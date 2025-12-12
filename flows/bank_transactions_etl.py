from prefect import flow, task
from prefect.blocks.system import Secret
import httpx

GOCARDLESS_BASE_URL = "https://bankaccountdata.gocardless.com/api/v2"


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
def fetch_transactions(token: str, account_id: str) -> list:
    """Descarga transacciones de la cuenta bancaria."""
    response = httpx.get(
        f"{GOCARDLESS_BASE_URL}/accounts/{account_id}/transactions/",
        headers={"Authorization": f"Bearer {token}"},
    )
    response.raise_for_status()
    return response.json()["transactions"]["booked"]


@task
def normalize_and_dedupe(transactions: list) -> list:
    """Normaliza y deduplica transacciones."""
    # TODO: implementar lógica de normalización
    # TODO: implementar deduplicación contra BD
    return transactions


@task
def load_to_database(transactions: list):
    """Inserta transacciones en la base de datos."""
    # TODO: implementar inserción en Supabase/PostgreSQL
    pass


@flow(log_prints=True)
def bank_transactions_etl():
    """ETL de movimientos bancarios desde GoCardless."""
    account_id = Secret.load("gc-account-id").get()

    token = get_access_token()
    raw = fetch_transactions(token, account_id)
    print(f"Descargadas {len(raw)} transacciones")

    clean = normalize_and_dedupe(raw)
    load_to_database(clean)
    print("ETL completado")


if __name__ == "__main__":
    bank_transactions_etl()
