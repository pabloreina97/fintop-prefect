import re
from datetime import date, datetime, timedelta

import httpx
from prefect import flow, task
from prefect.blocks.system import Secret
from prefect.cache_policies import NONE
from supabase import create_client

# Cliente HTTP con timeout más largo
HTTP_CLIENT = httpx.Client(timeout=60.0)

GOCARDLESS_BASE_URL = "https://bankaccountdata.gocardless.com/api/v2"
SYNC_OVERLAP_DAYS = 7

# Mapeo purpose_code → nombre de categoría
PURPOSE_CODE_MAP = {
    "SALA": "Nómina",
    "GOVT": "Ayudas y subvenciones",
}


@task
def get_supabase_client():
    """Crea cliente de Supabase con service key (bypasses RLS)."""
    url = Secret.load("supabase-url").get()
    key = Secret.load("supabase-service-key").get()
    return create_client(url, key)


@task
def get_access_token() -> str:
    """Obtiene token de acceso de GoCardless."""
    secret_id = Secret.load("gc-secret-id").get()
    secret_key = Secret.load("gc-secret-key").get()

    response = httpx.post(
        f"{GOCARDLESS_BASE_URL}/token/new/",
        json={"secret_id": secret_id, "secret_key": secret_key},
    )
    response.raise_for_status()
    return response.json()["access"]


@task(cache_policy=NONE)
def get_active_accounts(client) -> list:
    """Obtiene todas las cuentas activas de Supabase."""
    result = client.table("accounts").select("*").eq("is_active", True).execute()
    return result.data


@task(retries=3, retry_delay_seconds=[10, 30, 60])
def fetch_transactions(token: str, gocardless_account_id: str, date_from: str | None) -> list:
    """Descarga transacciones de la cuenta bancaria."""
    params = {}
    if date_from:
        from_date = date.fromisoformat(date_from) - timedelta(days=SYNC_OVERLAP_DAYS)
        params["date_from"] = from_date.isoformat()

    response = HTTP_CLIENT.get(
        f"{GOCARDLESS_BASE_URL}/accounts/{gocardless_account_id}/transactions/",
        headers={"Authorization": f"Bearer {token}"},
        params=params,
    )
    response.raise_for_status()
    return response.json()["transactions"]["booked"]


@task
def normalize_transactions(transactions: list) -> list:
    """Normaliza transacciones al esquema interno."""
    normalized = []
    for tx in transactions:
        description_array = tx.get("remittanceInformationUnstructuredArray", [])
        description = " | ".join(description_array) if description_array else tx.get("remittanceInformationUnstructured", "")

        normalized.append({
            "transaction_id": tx.get("transactionId") or tx.get("internalTransactionId"),
            "internal_transaction_id": tx.get("internalTransactionId"),
            "entry_reference": tx.get("entryReference"),
            "end_to_end_id": tx.get("endToEndId"),
            "mandate_id": tx.get("mandateId"),
            "creditor_id": tx.get("creditorId"),
            "booking_date": tx.get("bookingDate"),
            "value_date": tx.get("valueDate"),
            "amount": float(tx["transactionAmount"]["amount"]),
            "currency": tx["transactionAmount"]["currency"],
            "description": description,
            "creditor_name": tx.get("creditorName"),
            "debtor_name": tx.get("debtorName"),
            "ultimate_debtor": tx.get("ultimateDebtor"),
            "bank_transaction_code": tx.get("bankTransactionCode"),
            "proprietary_code": tx.get("proprietaryBankTransactionCode"),
            "purpose_code": tx.get("purposeCode"),
            "raw_data": tx,
        })
    return normalized


@task(cache_policy=NONE)
def load_to_database(client, transactions: list, account_id: str) -> list:
    """
    Inserta transacciones en transactions_raw.
    Retorna los IDs de las transacciones insertadas/actualizadas.
    """
    if not transactions:
        return []

    rows = [
        {
            "account_id": account_id,
            "transaction_id": tx["transaction_id"],
            "internal_transaction_id": tx["internal_transaction_id"],
            "entry_reference": tx["entry_reference"],
            "end_to_end_id": tx["end_to_end_id"],
            "mandate_id": tx["mandate_id"],
            "creditor_id": tx["creditor_id"],
            "booking_date": tx["booking_date"],
            "value_date": tx["value_date"],
            "amount": tx["amount"],
            "currency": tx["currency"],
            "description": tx["description"],
            "creditor_name": tx["creditor_name"],
            "debtor_name": tx["debtor_name"],
            "ultimate_debtor": tx["ultimate_debtor"],
            "bank_transaction_code": tx["bank_transaction_code"],
            "proprietary_code": tx["proprietary_code"],
            "purpose_code": tx["purpose_code"],
            "raw_data": tx["raw_data"],
        }
        for tx in transactions
    ]

    result = client.table("transactions_raw").upsert(
        rows,
        on_conflict="account_id,transaction_id",
    ).execute()

    return result.data


@task(cache_policy=NONE)
def get_categorization_rules(client, user_id: str | None) -> list:
    """Obtiene reglas de categorización (globales + usuario)."""
    query = client.table("categorization_rules").select(
        "*, categories(id, name)"
    ).eq("is_active", True).order("priority", desc=True)

    # Globales + del usuario
    if user_id:
        query = query.or_(f"user_id.is.null,user_id.eq.{user_id}")
    else:
        query = query.is_("user_id", "null")

    result = query.execute()
    return result.data


@task(cache_policy=NONE)
def get_categories_by_name(client) -> dict:
    """Obtiene mapeo nombre → id de categorías globales."""
    result = client.table("categories").select("id, name").is_("user_id", "null").execute()
    return {cat["name"]: cat["id"] for cat in result.data}


def match_rule(rule: dict, transaction: dict) -> bool:
    """Comprueba si una transacción coincide con una regla."""
    field = rule["field"]
    pattern = rule["pattern"].lower()
    match_type = rule["match_type"]

    value = transaction.get(field) or ""
    value = value.lower()

    if match_type == "contains":
        return pattern in value
    elif match_type == "starts_with":
        return value.startswith(pattern)
    elif match_type == "exact":
        return value == pattern
    elif match_type == "regex":
        try:
            return bool(re.search(pattern, value, re.IGNORECASE))
        except re.error:
            return False
    return False


@task(cache_policy=NONE)
def auto_categorize(client, transactions: list, user_id: str | None) -> dict:
    """
    Categoriza automáticamente las transacciones sin categoría.
    Retorna estadísticas de categorización.
    """
    if not transactions:
        return {"total": 0, "categorized": 0, "percentage": 0}

    # Obtener reglas y categorías
    rules = get_categorization_rules(client, user_id)
    categories_map = get_categories_by_name(client)

    # Obtener transacciones sin categorizar
    tx_ids = [tx["id"] for tx in transactions]
    existing = client.table("transactions_user").select(
        "transaction_raw_id"
    ).in_("transaction_raw_id", tx_ids).execute()
    already_categorized = {row["transaction_raw_id"] for row in existing.data}

    to_categorize = []

    for tx in transactions:
        if tx["id"] in already_categorized:
            continue

        category_id = None
        rule_id = None

        # 1. Intentar con purpose_code
        purpose = tx.get("purpose_code")
        if purpose and purpose in PURPOSE_CODE_MAP:
            category_name = PURPOSE_CODE_MAP[purpose]
            category_id = categories_map.get(category_name)

        # 2. Si no, buscar por reglas
        if not category_id:
            for rule in rules:
                if match_rule(rule, tx):
                    category_id = rule["category_id"]
                    rule_id = rule["id"]
                    break

        if category_id:
            to_categorize.append({
                "transaction_raw_id": tx["id"],
                "category_id": category_id,
                "is_auto_categorized": True,
            })

    # Insertar categorizaciones
    if to_categorize:
        client.table("transactions_user").upsert(
            to_categorize,
            on_conflict="transaction_raw_id",
        ).execute()

    total = len(transactions)
    categorized = len(to_categorize) + len(already_categorized)

    return {
        "total": total,
        "categorized": categorized,
        "new_categorized": len(to_categorize),
        "percentage": round(categorized / total * 100, 1) if total > 0 else 0,
    }


@task(cache_policy=NONE)
def update_account_last_sync(client, account_id: str):
    """Actualiza la fecha de última sincronización de la cuenta."""
    client.table("accounts").update({
        "last_sync_at": datetime.now().isoformat()
    }).eq("id", account_id).execute()


@flow(log_prints=True)
def sync_account(client, token: str, account: dict):
    """Sincroniza una cuenta bancaria individual."""
    account_id = account["id"]
    user_id = account["user_id"]
    gc_account_id = account["gocardless_account_id"]
    account_name = account.get("account_name") or account.get("bank_name") or gc_account_id
    last_sync = account.get("last_sync_at")

    if last_sync:
        last_sync_date = last_sync[:10] if isinstance(last_sync, str) else last_sync.date().isoformat()
        print(f"[{account_name}] Sincronización incremental desde {last_sync_date}")
    else:
        last_sync_date = None
        print(f"[{account_name}] Primera sincronización (completa)")

    # Descargar y guardar transacciones
    raw = fetch_transactions(token, gc_account_id, last_sync_date)
    print(f"[{account_name}] Descargadas {len(raw)} transacciones")

    if raw:
        normalized = normalize_transactions(raw)
        inserted = load_to_database(client, normalized, account_id)
        print(f"[{account_name}] Guardadas {len(inserted)} transacciones")

        # Categorización automática
        stats = auto_categorize(client, inserted, user_id)
        print(f"[{account_name}] Categorizadas: {stats['new_categorized']} nuevas ({stats['percentage']}% total)")

    update_account_last_sync(client, account_id)


@flow(log_prints=True)
def bank_transactions_etl():
    """ETL de movimientos bancarios para todas las cuentas activas."""
    client = get_supabase_client()
    accounts = get_active_accounts(client)

    if not accounts:
        print("No hay cuentas activas para sincronizar")
        return

    print(f"Sincronizando {len(accounts)} cuenta(s)")

    token = get_access_token()

    for account in accounts:
        sync_account(client, token, account)

    print("ETL completado")


if __name__ == "__main__":
    bank_transactions_etl()
