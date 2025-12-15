-- Categorías globales (user_id = NULL)
-- Se puede ejecutar múltiples veces (borra y recrea)

-- Borrar categorías globales existentes
DELETE FROM categories WHERE user_id IS NULL;

-- Ingresos
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Nómina', 'briefcase', '#22c55e', TRUE, 'Ingresos'),
('Freelance', 'laptop', '#16a34a', TRUE, 'Ingresos'),
('Inversiones', 'trending-up', '#15803d', TRUE, 'Ingresos'),
('Reembolsos', 'rotate-ccw', '#4ade80', TRUE, 'Ingresos'),
('Ayudas y subvenciones', 'landmark', '#86efac', TRUE, 'Ingresos'),
('Otros ingresos', 'plus-circle', '#bbf7d0', TRUE, 'Ingresos');

-- Gastos - Hogar
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Alquiler', 'home', '#ef4444', TRUE, 'Hogar'),
('Hipoteca', 'home', '#dc2626', TRUE, 'Hogar'),
('Luz', 'zap', '#f97316', TRUE, 'Hogar'),
('Gas', 'flame', '#ea580c', TRUE, 'Hogar'),
('Agua', 'droplet', '#0ea5e9', TRUE, 'Hogar'),
('Internet y teléfono', 'wifi', '#6366f1', TRUE, 'Hogar'),
('Seguros', 'shield', '#8b5cf6', TRUE, 'Hogar'),
('Mantenimiento hogar', 'wrench', '#a855f7', TRUE, 'Hogar');

-- Gastos - Alimentación
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Supermercado', 'shopping-cart', '#f59e0b', TRUE, 'Alimentación'),
('Restaurantes', 'utensils', '#d97706', TRUE, 'Alimentación'),
('Cafeterías', 'coffee', '#b45309', TRUE, 'Alimentación'),
('Comida a domicilio', 'package', '#92400e', TRUE, 'Alimentación');

-- Gastos - Transporte
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Gasolina', 'fuel', '#64748b', TRUE, 'Transporte'),
('Transporte público', 'train', '#475569', TRUE, 'Transporte'),
('Taxi y VTC', 'car', '#334155', TRUE, 'Transporte'),
('Parking', 'square-parking', '#1e293b', TRUE, 'Transporte'),
('Seguro coche', 'shield', '#94a3b8', TRUE, 'Transporte'),
('Mantenimiento coche', 'wrench', '#cbd5e1', TRUE, 'Transporte'),
('Préstamo coche', 'car', '#e2e8f0', TRUE, 'Transporte');

-- Gastos - Salud
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Farmacia', 'pill', '#ec4899', TRUE, 'Salud'),
('Salud', 'stethoscope', '#db2777', TRUE, 'Salud'),
('Dentista', 'smile', '#be185d', TRUE, 'Salud'),
('Seguro médico', 'heart-pulse', '#9d174d', TRUE, 'Salud');

-- Gastos - Ocio y entretenimiento
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Suscripciones', 'tv', '#8b5cf6', TRUE, 'Ocio'),
('Cine y espectáculos', 'clapperboard', '#7c3aed', TRUE, 'Ocio'),
('Deportes y gimnasio', 'dumbbell', '#6d28d9', TRUE, 'Ocio'),
('Viajes', 'plane', '#5b21b6', TRUE, 'Ocio'),
('Ocio', 'gamepad-2', '#4c1d95', TRUE, 'Ocio');

-- Gastos - Compras
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Ropa y calzado', 'shirt', '#06b6d4', TRUE, 'Compras'),
('Electrónica', 'smartphone', '#0891b2', TRUE, 'Compras'),
('Hogar y decoración', 'sofa', '#0e7490', TRUE, 'Compras'),
('Regalos', 'gift', '#155e75', TRUE, 'Compras');

-- Gastos - Educación y familia
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Educación', 'graduation-cap', '#10b981', TRUE, 'Familia'),
('Guardería', 'baby', '#059669', TRUE, 'Familia'),
('Hijos', 'users', '#047857', TRUE, 'Familia'),
('Mascotas', 'dog', '#065f46', TRUE, 'Familia');

-- Gastos - Finanzas
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Impuestos', 'receipt', '#78716c', TRUE, 'Finanzas'),
('Comisiones bancarias', 'landmark', '#57534e', TRUE, 'Finanzas'),
('Préstamos', 'banknote', '#44403c', TRUE, 'Finanzas'),
('Donaciones', 'heart-handshake', '#f43f5e', TRUE, 'Finanzas');

-- Gastos - Otros
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Otros gastos', 'circle-dot', '#a1a1aa', TRUE, 'Otros');

-- No computables (transferencias internas, ajustes, etc.)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Transferencia entre cuentas', 'arrow-left-right', '#71717a', FALSE, 'No computable'),
('Ajuste de saldo', 'scale', '#52525b', FALSE, 'No computable'),
('Ahorro e inversiones', 'banknote', '#3f3f46', FALSE, 'No computable');
