from datetime import date, timedelta

import httpx
from prefect import flow, task
from prefect.blocks.system import Secret
from prefect.variables import Variable
from supabase import create_client

GOCARDLESS_BASE_URL = "https://bankaccountdata.gocardless.com/api/v2"
SYNC_OVERLAP_DAYS = 7  # Margen de seguridad para capturar modificaciones


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
def get_last_sync_date() -> str | None:
    """Obtiene la fecha de última sincronización."""
    return Variable.get("gc_last_sync_date", default=None)


@task
async def update_last_sync_date(sync_date: str):
    """Actualiza la fecha de última sincronización."""
    await Variable.set("gc_last_sync_date", sync_date, overwrite=True)


@task
def fetch_transactions(token: str, account_id: str, date_from: str | None) -> list:
    """Descarga transacciones de la cuenta bancaria."""
    params = {}
    if date_from:
        # Retroceder unos días para capturar posibles modificaciones
        from_date = date.fromisoformat(date_from) - timedelta(days=SYNC_OVERLAP_DAYS)
        params["date_from"] = from_date.isoformat()

    response = httpx.get(
        f"{GOCARDLESS_BASE_URL}/accounts/{account_id}/transactions/",
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
        # Descripción: unir array o usar string simple
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
def get_supabase_client():
    """Crea cliente de Supabase."""
    url = Secret.load("supabase-url").get()
    key = Secret.load("supabase-service-key").get()
    return create_client(url, key)


@task
def load_to_database(transactions: list, account_id: str) -> int:
    """
    Inserta transacciones en transactions_raw.
    Usa upsert para deduplicar por transaction_id.
    """
    if not transactions:
        return 0

    client = get_supabase_client()

    # Preparar datos para upsert
    rows = [
        {
            "transaction_id": tx["transaction_id"],
            "account_id": account_id,
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

    # Upsert: inserta o actualiza si transaction_id ya existe
    result = client.table("transactions_raw").upsert(
        rows,
        on_conflict="transaction_id",
    ).execute()

    return len(result.data)


@flow(log_prints=True)
def bank_transactions_etl():
    """ETL incremental de movimientos bancarios desde GoCardless."""
    account_id = Variable.get("gc_account_id")
    last_sync = get_last_sync_date()

    if last_sync:
        print(f"Sincronización incremental desde {last_sync}")
    else:
        print("Primera sincronización (completa)")

    token = get_access_token()
    raw = fetch_transactions(token, account_id, last_sync)
    print(f"Descargadas {len(raw)} transacciones")

    normalized = normalize_transactions(raw)
    inserted = load_to_database(normalized, account_id)
    print(f"Procesadas {inserted} transacciones")

    # Actualizar fecha de última sincronización
    today = date.today().isoformat()
    update_last_sync_date(today)
    print(f"Próxima sincronización desde {today}")


if __name__ == "__main__":
    bank_transactions_etl()
