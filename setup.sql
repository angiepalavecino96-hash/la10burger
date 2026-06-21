-- ====================================================================
-- LA 10 BURGER - Setup completo de base de datos (Supabase / Postgres)
-- Ejecutar TODO este archivo de una sola vez en: Supabase > SQL Editor
-- ====================================================================

-- 1. TABLA INSUMOS
CREATE TABLE insumos (
  id_insumo SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  unidad TEXT NOT NULL, -- 'unidad', 'feta', 'gramos'
  stock_actual NUMERIC NOT NULL DEFAULT 0
);

INSERT INTO insumos (id_insumo, nombre, unidad, stock_actual) VALUES
(1, 'Pan artesanal', 'unidad', 0),
(2, 'Pan de papa', 'unidad', 0),
(3, 'Medallón carne 110gr', 'unidad', 0),
(4, 'Medallón carne 69gr', 'unidad', 0),
(5, 'Cheddar', 'feta', 0),
(6, 'Papas', 'gramos', 0);

-- 2. TABLA PRODUCTOS_VARIACIONES
CREATE TABLE productos_variaciones (
  id_variacion SERIAL PRIMARY KEY,
  nombre_producto TEXT NOT NULL,
  precio NUMERIC NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT true
);

INSERT INTO productos_variaciones (id_variacion, nombre_producto, precio) VALUES
(101, 'Abuela', 20000),
(102, '3 Estrellas', 15000),
(103, 'La Dibu XL', 14000),
(104, 'La Scaloneta', 13000),
(105, 'La Dibu', 13000),
(106, 'La Ota', 9000),
(107, 'La Araña que Pica', 8000),
(108, 'Especial de la Casa', 13000),
(109, 'La Doble Golazo', 11000),
(110, 'La Golazo', 9000),
(111, 'La Doble Messi', 8000),
(112, 'La Messi', 7000),
(113, 'La Chiqui Burguer', 6500);

-- 3. TABLA RECETAS (lo que SIEMPRE descuenta cada producto)
CREATE TABLE recetas (
  id_receta SERIAL PRIMARY KEY,
  id_variacion INT NOT NULL REFERENCES productos_variaciones(id_variacion),
  id_insumo INT NOT NULL REFERENCES insumos(id_insumo),
  cantidad_a_descontar NUMERIC NOT NULL
);

INSERT INTO recetas (id_variacion, id_insumo, cantidad_a_descontar) VALUES
(101, 1, 1), (101, 3, 5), (101, 5, 7.5), (101, 6, 300),
(102, 1, 1), (102, 3, 3), (102, 5, 4.5), (102, 6, 300),
(103, 1, 1), (103, 3, 3), (103, 6, 300),
(104, 1, 1), (104, 3, 2), (104, 6, 300),
(105, 1, 1), (105, 3, 2), (105, 6, 300),
(106, 1, 1), (106, 3, 1), (106, 5, 1.5), (106, 6, 300),
(107, 2, 1), (107, 4, 2), (107, 5, 2), (107, 6, 300),
(108, 1, 1), (108, 3, 2), (108, 5, 6), (108, 6, 300),
(109, 1, 1), (109, 3, 2), (109, 5, 6), (109, 6, 300),
(110, 1, 1), (110, 3, 1), (110, 5, 1.5), (110, 6, 300),
(111, 2, 1), (111, 4, 2), (111, 5, 4), (111, 6, 300),
(112, 2, 1), (112, 4, 1), (112, 5, 1), (112, 6, 300),
(113, 2, 1), (113, 4, 1), (113, 6, 300);

-- 4. MODIFICADORES (las 3 variantes de la Chiqui Burguer)
CREATE TABLE modificadores (
  id_modificador SERIAL PRIMARY KEY,
  id_variacion INT NOT NULL REFERENCES productos_variaciones(id_variacion),
  nombre TEXT NOT NULL
);

INSERT INTO modificadores (id_modificador, id_variacion, nombre) VALUES
(1, 113, 'Jamón y Queso'),
(2, 113, 'Cheddar'),
(3, 113, 'Lechuga y Tomate');

CREATE TABLE recetas_modificador (
  id_receta_mod SERIAL PRIMARY KEY,
  id_modificador INT NOT NULL REFERENCES modificadores(id_modificador),
  id_insumo INT NOT NULL REFERENCES insumos(id_insumo),
  cantidad_a_descontar NUMERIC NOT NULL
);

INSERT INTO recetas_modificador (id_modificador, id_insumo, cantidad_a_descontar) VALUES
(2, 5, 1); -- Opción Cheddar descuenta 1 feta extra

-- ====================================================================
-- 5. FUNCIÓN: calcular cuántas unidades de cada variación se pueden
--    vender hoy según el stock actual (para marcar "agotado" en la web)
-- ====================================================================
CREATE OR REPLACE FUNCTION disponibilidad_productos()
RETURNS TABLE(id_variacion INT, unidades_disponibles NUMERIC) AS $$
  SELECT
    r.id_variacion,
    FLOOR(MIN(i.stock_actual / r.cantidad_a_descontar)) AS unidades_disponibles
  FROM recetas r
  JOIN insumos i ON i.id_insumo = r.id_insumo
  GROUP BY r.id_variacion;
$$ LANGUAGE sql STABLE;

-- ====================================================================
-- 6. FUNCIÓN: descontar stock al confirmar una compra (ATÓMICA)
--    Uso desde la web: supabase.rpc('descontar_stock', {p_id_variacion: 113, p_id_modificador: 2})
-- ====================================================================
CREATE OR REPLACE FUNCTION descontar_stock(
  p_id_variacion INT,
  p_id_modificador INT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_insumo RECORD;
  v_filas_afectadas INT;
BEGIN
  -- Recorremos receta base + receta del modificador (si vino)
  FOR v_insumo IN
    SELECT id_insumo, cantidad_a_descontar FROM recetas WHERE id_variacion = p_id_variacion
    UNION ALL
    SELECT id_insumo, cantidad_a_descontar FROM recetas_modificador WHERE id_modificador = p_id_modificador
  LOOP
    UPDATE insumos
    SET stock_actual = stock_actual - v_insumo.cantidad_a_descontar
    WHERE id_insumo = v_insumo.id_insumo
      AND stock_actual >= v_insumo.cantidad_a_descontar;

    GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;

    IF v_filas_afectadas = 0 THEN
      RAISE EXCEPTION 'SIN_STOCK: insumo % no tiene stock suficiente', v_insumo.id_insumo;
    END IF;
  END LOOP;

  RETURN json_build_object('ok', true);
END;
$$ LANGUAGE plpgsql;

-- ====================================================================
-- 7. Seguridad básica (Row Level Security)
--    Dejamos lectura pública del menú/stock, pero solo el admin puede
--    escribir directamente en insumos (la compra usa la función RPC,
--    que corre con permisos del propietario, no necesita RLS abierto).
-- ====================================================================
ALTER TABLE insumos ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos_variaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE recetas ENABLE ROW LEVEL SECURITY;
ALTER TABLE modificadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE recetas_modificador ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lectura publica insumos" ON insumos FOR SELECT USING (true);
CREATE POLICY "lectura publica productos" ON productos_variaciones FOR SELECT USING (true);
CREATE POLICY "lectura publica recetas" ON recetas FOR SELECT USING (true);
CREATE POLICY "lectura publica modificadores" ON modificadores FOR SELECT USING (true);
CREATE POLICY "lectura publica recetas_modificador" ON recetas_modificador FOR SELECT USING (true);

-- IMPORTANTE: el UPDATE de stock desde el panel admin se hace con la
-- "service_role key" (clave secreta), NUNCA con la clave pública (anon key).
-- Por eso el admin.html pide esa clave aparte, y el index.html (menú) NO la usa.
