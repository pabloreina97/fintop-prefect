-- Categorías globales (user_id = NULL)
-- Se puede ejecutar múltiples veces (borra y recrea)

-- Borrar categorías globales existentes
DELETE FROM categories WHERE user_id IS NULL;

-- Ingresos (Verdes)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Nómina', 'briefcase', '#22c55e', TRUE, 'Ingresos'),
('Freelance', 'laptop', '#16a34a', TRUE, 'Ingresos'),
('Inversiones', 'trending-up', '#15803d', TRUE, 'Ingresos'),
('Reembolsos', 'rotate-ccw', '#4ade80', TRUE, 'Ingresos'),
('Ayudas y subvenciones', 'landmark', '#34d399', TRUE, 'Ingresos'),
('Otros ingresos', 'plus-circle', '#a3e635', TRUE, 'Ingresos');

-- Gastos - Hogar (Azules/Índigo)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Alquiler', 'home', '#3b82f6', TRUE, 'Hogar'),
('Hipoteca', 'home', '#2563eb', TRUE, 'Hogar'),
('Luz', 'zap', '#60a5fa', TRUE, 'Hogar'),
('Gas', 'flame', '#1d4ed8', TRUE, 'Hogar'),
('Agua', 'droplet', '#38bdf8', TRUE, 'Hogar'),
('Internet y teléfono', 'wifi', '#6366f1', TRUE, 'Hogar'),
('Seguros', 'shield', '#818cf8', TRUE, 'Hogar'),
('Mantenimiento hogar', 'wrench', '#4f46e5', TRUE, 'Hogar'),
('Comunidad de vecinos', 'building', '#a5b4fc', TRUE, 'Hogar'),
('Servicio doméstico', 'spray-can', '#c7d2fe', TRUE, 'Hogar');

-- Gastos - Alimentación (Naranjas/Ámbar)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Supermercado', 'shopping-cart', '#f59e0b', TRUE, 'Alimentación'),
('Restaurantes', 'utensils', '#d97706', TRUE, 'Alimentación'),
('Cafeterías', 'coffee', '#b45309', TRUE, 'Alimentación'),
('Comida a domicilio', 'package', '#92400e', TRUE, 'Alimentación');

-- Gastos - Transporte (Celestes/Sky)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Gasolina', 'fuel', '#0ea5e9', TRUE, 'Transporte'),
('Transporte público', 'train', '#0284c7', TRUE, 'Transporte'),
('Taxi y VTC', 'car', '#0369a1', TRUE, 'Transporte'),
('Parking', 'square-parking', '#075985', TRUE, 'Transporte'),
('Seguro coche', 'shield', '#38bdf8', TRUE, 'Transporte'),
('Mantenimiento coche', 'wrench', '#7dd3fc', TRUE, 'Transporte'),
('Préstamo coche', 'car', '#0c4a6e', TRUE, 'Transporte');

-- Gastos - Salud (Rosas)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Farmacia', 'pill', '#ec4899', TRUE, 'Salud'),
('Salud', 'stethoscope', '#db2777', TRUE, 'Salud'),
('Dentista', 'smile', '#be185d', TRUE, 'Salud'),
('Seguro médico', 'heart-pulse', '#9d174d', TRUE, 'Salud'),
('Belleza', 'sparkles', '#f472b6', TRUE, 'Salud');

-- Gastos - Ocio y entretenimiento (Violetas)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Suscripciones', 'tv', '#a78bfa', TRUE, 'Ocio'),
('Cine y espectáculos', 'clapperboard', '#7c3aed', TRUE, 'Ocio'),
('Deportes y gimnasio', 'dumbbell', '#6d28d9', TRUE, 'Ocio'),
('Viajes', 'plane', '#8b5cf6', TRUE, 'Ocio'),
('Hobbies', 'gamepad-2', '#5b21b6', TRUE, 'Ocio');

-- Gastos - Compras (Cyans)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Ropa y calzado', 'shirt', '#06b6d4', TRUE, 'Compras'),
('Electrónica', 'smartphone', '#0891b2', TRUE, 'Compras'),
('Hogar y decoración', 'sofa', '#0e7490', TRUE, 'Compras'),
('Regalos', 'gift', '#155e75', TRUE, 'Compras');

-- Gastos - Educación y familia (Teal)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Educación', 'graduation-cap', '#14b8a6', TRUE, 'Familia'),
('Guardería', 'baby', '#0d9488', TRUE, 'Familia'),
('Hijos', 'users', '#0f766e', TRUE, 'Familia'),
('Mascotas', 'dog', '#115e59', TRUE, 'Familia');

-- Gastos - Finanzas (Rose/Rojos)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Impuestos', 'receipt', '#e11d48', TRUE, 'Finanzas'),
('Comisiones bancarias', 'landmark', '#be123c', TRUE, 'Finanzas'),
('Préstamos', 'banknote', '#9f1239', TRUE, 'Finanzas'),
('Donaciones', 'heart-handshake', '#f43f5e', TRUE, 'Finanzas');

-- Gastos - Otros (Marrón cálido)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Otros gastos', 'circle-dot', '#a1887f', TRUE, 'Otros');

-- No computables - Grises (único grupo con grises)
INSERT INTO categories (name, icon, color, computable, group_name) VALUES
('Transferencia entre cuentas', 'arrow-left-right', '#71717a', FALSE, 'No computable'),
('Ajuste de saldo', 'scale', '#52525b', FALSE, 'No computable'),
('Ahorro e inversiones', 'banknote', '#3f3f46', FALSE, 'No computable');
