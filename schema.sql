-- Tabla de cuentas bancarias
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    gocardless_account_id TEXT UNIQUE NOT NULL,
    bank_name TEXT,
    account_name TEXT,          -- Alias que pone el usuario
    iban TEXT,
    last_sync_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla raw: solo la toca la ETL
CREATE TABLE transactions_raw (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    transaction_id TEXT NOT NULL,
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
    creditor_id TEXT,
    debtor_name TEXT,
    ultimate_debtor TEXT,

    -- Descripción
    description TEXT,

    -- Referencias de pago
    end_to_end_id TEXT,
    mandate_id TEXT,

    -- Códigos de clasificación
    bank_transaction_code TEXT,
    proprietary_code TEXT,
    purpose_code TEXT,

    -- Datos originales
    raw_data JSONB,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique por cuenta + transaction_id
    UNIQUE(account_id, transaction_id)
);

-- Categorías de transacciones
-- user_id NULL = categoría global (visible para todos)
-- user_id NOT NULL = categoría personalizada del usuario
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT,
    color TEXT,
    computable BOOLEAN DEFAULT TRUE,  -- FALSE = no cuenta en totales/gráficos
    parent_id UUID REFERENCES categories(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla user: solo la toca el frontend/usuario
CREATE TABLE transactions_user (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_raw_id UUID UNIQUE NOT NULL REFERENCES transactions_raw(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vista combinada para el frontend (con filtro RLS)
CREATE VIEW transactions WITH (security_invoker = true) AS
SELECT
    r.id,
    r.account_id,
    a.user_id,
    r.transaction_id,
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
    u.category_id,
    c.name AS category_name,
    c.icon AS category_icon,
    c.color AS category_color,
    COALESCE(c.computable, TRUE) AS computable,
    u.notes,
    r.created_at,
    GREATEST(r.updated_at, u.updated_at) AS updated_at
FROM transactions_raw r
JOIN accounts a ON a.id = r.account_id
LEFT JOIN transactions_user u ON u.transaction_raw_id = r.id
LEFT JOIN categories c ON c.id = u.category_id
WHERE a.user_id = auth.uid();

-- Índices
CREATE INDEX idx_accounts_user ON accounts(user_id);
CREATE INDEX idx_accounts_active ON accounts(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_categories_user ON categories(user_id);
CREATE INDEX idx_transactions_raw_account ON transactions_raw(account_id);
CREATE INDEX idx_transactions_raw_booking_date ON transactions_raw(booking_date);
CREATE INDEX idx_transactions_raw_creditor ON transactions_raw(creditor_name);
CREATE INDEX idx_transactions_user_category ON transactions_user(category_id);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER transactions_raw_updated_at
    BEFORE UPDATE ON transactions_raw
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER transactions_user_updated_at
    BEFORE UPDATE ON transactions_user
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS Policies
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions_raw ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions_user ENABLE ROW LEVEL SECURITY;

-- Accounts: usuario solo ve las suyas
CREATE POLICY accounts_select ON accounts
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY accounts_insert ON accounts
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY accounts_update ON accounts
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY accounts_delete ON accounts
    FOR DELETE USING (user_id = auth.uid());

-- Categories: globales (user_id IS NULL) + propias del usuario
CREATE POLICY categories_select ON categories
    FOR SELECT USING (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY categories_insert ON categories
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY categories_update ON categories
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY categories_delete ON categories
    FOR DELETE USING (user_id = auth.uid());

-- Transactions_raw: usuario solo ve las de sus cuentas
CREATE POLICY transactions_raw_select ON transactions_raw
    FOR SELECT USING (
        account_id IN (SELECT id FROM accounts WHERE user_id = auth.uid())
    );

-- Transactions_user: usuario solo ve/edita las de sus transacciones
CREATE POLICY transactions_user_select ON transactions_user
    FOR SELECT USING (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );

CREATE POLICY transactions_user_insert ON transactions_user
    FOR INSERT WITH CHECK (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );

CREATE POLICY transactions_user_update ON transactions_user
    FOR UPDATE USING (
        transaction_raw_id IN (
            SELECT r.id FROM transactions_raw r
            JOIN accounts a ON a.id = r.account_id
            WHERE a.user_id = auth.uid()
        )
    );
