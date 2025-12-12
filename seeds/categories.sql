-- Categorías globales (user_id = NULL)
-- Ejecutar una sola vez para poblar la base de datos

-- Ingresos
INSERT INTO categories (name, icon, color, computable) VALUES
('Nómina', 'briefcase', '#22c55e', TRUE),
('Freelance', 'laptop', '#16a34a', TRUE),
('Inversiones', 'trending-up', '#15803d', TRUE),
('Reembolsos', 'rotate-ccw', '#4ade80', TRUE),
('Ayudas y subvenciones', 'landmark', '#86efac', TRUE),
('Otros ingresos', 'plus-circle', '#bbf7d0', TRUE);

-- Gastos - Hogar
INSERT INTO categories (name, icon, color, computable) VALUES
('Alquiler', 'home', '#ef4444', TRUE),
('Hipoteca', 'home', '#dc2626', TRUE),
('Luz', 'zap', '#f97316', TRUE),
('Gas', 'flame', '#ea580c', TRUE),
('Agua', 'droplet', '#0ea5e9', TRUE),
('Internet y teléfono', 'wifi', '#6366f1', TRUE),
('Seguro hogar', 'shield', '#8b5cf6', TRUE),
('Mantenimiento hogar', 'wrench', '#a855f7', TRUE);

-- Gastos - Alimentación
INSERT INTO categories (name, icon, color, computable) VALUES
('Supermercado', 'shopping-cart', '#f59e0b', TRUE),
('Restaurantes', 'utensils', '#d97706', TRUE),
('Cafeterías', 'coffee', '#b45309', TRUE),
('Comida a domicilio', 'package', '#92400e', TRUE);

-- Gastos - Transporte
INSERT INTO categories (name, icon, color, computable) VALUES
('Gasolina', 'fuel', '#64748b', TRUE),
('Transporte público', 'train', '#475569', TRUE),
('Taxi y VTC', 'car', '#334155', TRUE),
('Parking', 'square-parking', '#1e293b', TRUE),
('Seguro coche', 'shield', '#94a3b8', TRUE),
('Mantenimiento coche', 'wrench', '#cbd5e1', TRUE);

-- Gastos - Salud
INSERT INTO categories (name, icon, color, computable) VALUES
('Farmacia', 'pill', '#ec4899', TRUE),
('Médico', 'stethoscope', '#db2777', TRUE),
('Dentista', 'smile', '#be185d', TRUE),
('Seguro médico', 'heart-pulse', '#9d174d', TRUE);

-- Gastos - Ocio y entretenimiento
INSERT INTO categories (name, icon, color, computable) VALUES
('Suscripciones', 'tv', '#8b5cf6', TRUE),
('Cine y espectáculos', 'clapperboard', '#7c3aed', TRUE),
('Deportes y gimnasio', 'dumbbell', '#6d28d9', TRUE),
('Viajes', 'plane', '#5b21b6', TRUE),
('Hobbies', 'gamepad-2', '#4c1d95', TRUE);

-- Gastos - Compras
INSERT INTO categories (name, icon, color, computable) VALUES
('Ropa y calzado', 'shirt', '#06b6d4', TRUE),
('Electrónica', 'smartphone', '#0891b2', TRUE),
('Hogar y decoración', 'sofa', '#0e7490', TRUE),
('Regalos', 'gift', '#155e75', TRUE);

-- Gastos - Educación y familia
INSERT INTO categories (name, icon, color, computable) VALUES
('Educación', 'graduation-cap', '#10b981', TRUE),
('Guardería', 'baby', '#059669', TRUE),
('Hijos', 'users', '#047857', TRUE),
('Mascotas', 'dog', '#065f46', TRUE);

-- Gastos - Finanzas
INSERT INTO categories (name, icon, color, computable) VALUES
('Impuestos', 'receipt', '#78716c', TRUE),
('Comisiones bancarias', 'landmark', '#57534e', TRUE),
('Préstamos', 'banknote', '#44403c', TRUE),
('Donaciones', 'heart-handshake', '#f43f5e', TRUE);

-- Gastos - Otros
INSERT INTO categories (name, icon, color, computable) VALUES
('Otros gastos', 'circle-dot', '#a1a1aa', TRUE);

-- No computables (transferencias internas, ajustes, etc.)
INSERT INTO categories (name, icon, color, computable) VALUES
('Transferencia entre cuentas', 'arrow-left-right', '#71717a', FALSE),
('Ajuste de saldo', 'scale', '#52525b', FALSE),
('Retirada efectivo', 'banknote', '#3f3f46', FALSE);
