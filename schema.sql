-- Tabla raw: solo la toca la ETL
CREATE TABLE transactions_raw (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id TEXT UNIQUE NOT NULL,
    account_id TEXT NOT NULL,
    internal_transaction_id TEXT,
    entry_reference TEXT,

    -- Fechas
    booking_date DATE NOT NULL,
    value_date DATE,

    -- Importe
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'EUR',

    -- Partes involucradas
    creditor_name TEXT,
    creditor_id TEXT,           -- ID SEPA del acreedor (domiciliaciones)
    debtor_name TEXT,
    ultimate_debtor TEXT,       -- Deudor final (útil para nóminas, transferencias)

    -- Descripción
    description TEXT,

    -- Referencias de pago
    end_to_end_id TEXT,         -- ID end-to-end (transferencias/domiciliaciones)
    mandate_id TEXT,            -- ID de mandato SEPA

    -- Códigos de clasificación
    bank_transaction_code TEXT, -- PMNT (pago), LDAS (domiciliación), etc.
    proprietary_code TEXT,      -- Código propietario del banco (40/174, 2/48, etc.)
    purpose_code TEXT,          -- SALA (salario), GOVT (gobierno), SUPP (suplemento)

    -- Datos originales
    raw_data JSONB,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla user: solo la toca el frontend/usuario
CREATE TABLE transactions_user (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id TEXT UNIQUE NOT NULL REFERENCES transactions_raw(transaction_id),
    category_id UUID,           -- FK a tabla de categorías
    notes TEXT,
    hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vista combinada para el frontend
CREATE VIEW transactions AS
SELECT
    r.id,
    r.transaction_id,
    r.account_id,
    r.booking_date,
    r.value_date,
    r.amount,
    r.currency,
    r.description,
    r.creditor_name,
    r.debtor_name,
    r.ultimate_debtor,
    r.bank_transaction_code,
    r.proprietary_code,
    r.purpose_code,
    -- Campos editables: prioridad usuario > source
    u.category_id,
    u.notes,
    COALESCE(u.hidden, FALSE) AS hidden,
    r.created_at,
    GREATEST(r.updated_at, u.updated_at) AS updated_at
FROM transactions_raw r
LEFT JOIN transactions_user u USING (transaction_id);

-- Índices
CREATE INDEX idx_transactions_raw_account ON transactions_raw(account_id);
CREATE INDEX idx_transactions_raw_booking_date ON transactions_raw(booking_date);
CREATE INDEX idx_transactions_raw_creditor ON transactions_raw(creditor_name);
CREATE INDEX idx_transactions_raw_purpose ON transactions_raw(purpose_code);
CREATE INDEX idx_transactions_user_category ON transactions_user(category_id);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER transactions_raw_updated_at
    BEFORE UPDATE ON transactions_raw
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER transactions_user_updated_at
    BEFORE UPDATE ON transactions_user
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
