-- Tabla raw: solo la toca la ETL
CREATE TABLE transactions_raw (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id TEXT UNIQUE NOT NULL,
    account_id TEXT NOT NULL,
    booking_date DATE NOT NULL,
    value_date DATE,
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'EUR',
    description TEXT,
    creditor_name TEXT,
    debtor_name TEXT,
    category_source TEXT,
    raw_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla user: solo la toca el frontend/usuario
CREATE TABLE transactions_user (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id TEXT UNIQUE NOT NULL REFERENCES transactions_raw(transaction_id),
    category_id UUID,  -- FK a tabla de categorías
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
    r.category_source,
    -- Campos editables: prioridad usuario > source
    COALESCE(u.category_id, NULL) AS category_id,
    u.notes,
    COALESCE(u.hidden, FALSE) AS hidden,
    r.created_at,
    GREATEST(r.updated_at, u.updated_at) AS updated_at
FROM transactions_raw r
LEFT JOIN transactions_user u USING (transaction_id);

-- Índices
CREATE INDEX idx_transactions_raw_account ON transactions_raw(account_id);
CREATE INDEX idx_transactions_raw_booking_date ON transactions_raw(booking_date);
CREATE INDEX idx_transactions_user_category ON transactions_user(category_id);
