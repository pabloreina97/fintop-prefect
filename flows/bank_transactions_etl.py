from datetime import date, datetime, timedelta

import httpx
from prefect import flow, task
from prefect.blocks.system import Secret
from supabase import create_client

GOCARDLESS_BASE_URL = "https://bankaccountdata.gocardless.com/api/v2"
SYNC_OVERLAP_DAYS = 7


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


@task
def get_active_accounts(client) -> list:
    """Obtiene todas las cuentas activas de Supabase."""
    result = client.table("accounts").select("*").eq("is_active", True).execute()
    return result.data


@task
def fetch_transactions(token: str, gocardless_account_id: str, date_from: str | None) -> list:
    """Descarga transacciones de la cuenta bancaria."""
    params = {}
    if date_from:
        from_date = date.fromisoformat(date_from) - timedelta(days=SYNC_OVERLAP_DAYS)
        params["date_from"] = from_date.isoformat()

    response = httpx.get(
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


@task
def load_to_database(client, transactions: list, account_id: str) -> int:
    """
    Inserta transacciones en transactions_raw.
    Usa upsert para deduplicar por (account_id, transaction_id).
    """
    if not transactions:
        return 0

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

    return len(result.data)


@task
def update_account_last_sync(client, account_id: str):
    """Actualiza la fecha de última sincronización de la cuenta."""
    client.table("accounts").update({
        "last_sync_at": datetime.now().isoformat()
    }).eq("id", account_id).execute()


@flow(log_prints=True)
def sync_account(client, token: str, account: dict):
    """Sincroniza una cuenta bancaria individual."""
    account_id = account["id"]
    gc_account_id = account["gocardless_account_id"]
    account_name = account.get("account_name") or account.get("bank_name") or gc_account_id
    last_sync = account.get("last_sync_at")

    if last_sync:
        # Extraer solo la fecha del timestamp
        last_sync_date = last_sync[:10] if isinstance(last_sync, str) else last_sync.date().isoformat()
        print(f"[{account_name}] Sincronización incremental desde {last_sync_date}")
    else:
        last_sync_date = None
        print(f"[{account_name}] Primera sincronización (completa)")

    raw = fetch_transactions(token, gc_account_id, last_sync_date)
    print(f"[{account_name}] Descargadas {len(raw)} transacciones")

    if raw:
        normalized = normalize_transactions(raw)
        inserted = load_to_database(client, normalized, account_id)
        print(f"[{account_name}] Procesadas {inserted} transacciones")

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
