-- este si funcionò

-- 1. TABLA DE ROLES
CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  nombre_rol TEXT NOT NULL UNIQUE,
  descripcion TEXT
);

INSERT INTO roles (nombre_rol, descripcion) VALUES 
('Ingeniero', 'Aprueba pagos y firma digitalmente'),
('Contador', 'Gestiona caja y marca estados de pago'),
('Asistente Ingeniero', 'Registra órdenes de compra y genera PDFs');

-- 2. TABLA DE PERFILES (Extension de auth.users)
CREATE TABLE perfiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  nombre_completo TEXT,
  rol_id INTEGER REFERENCES roles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TRIGGER: CREACIÓN AUTOMÁTICA DE PERFIL
-- Esta función se dispara cada vez que un usuario se registra en Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.perfiles (id, nombre_completo, rol_id)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', 3); -- Por defecto asigna 'Asistente' (id 3)
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 4. TABLA DE PROVEEDORES
CREATE TABLE proveedores (
  id SERIAL PRIMARY KEY,
  nombre_comercial TEXT NOT NULL, --
  direccion TEXT,
  nrc_nit TEXT,
  terminos_pago TEXT DEFAULT 'Net 30 days' -- [cite: 21]
);

-- 5. TABLA DE ORDENES DE COMPRA
CREATE TABLE ordenes_compra (
  id SERIAL PRIMARY KEY,
  numero_orden TEXT UNIQUE NOT NULL, --
  fecha_emision DATE DEFAULT CURRENT_DATE, -- [cite: 14]
  proveedor_id INTEGER REFERENCES proveedores(id),
  monto_total DECIMAL(10,2) DEFAULT 0.00, --
  estado TEXT DEFAULT 'REGISTRADA', --
  fecha_vencimiento DATE, --
  registrado_por UUID REFERENCES auth.users(id),
  aprobado_por UUID REFERENCES auth.users(id),
  fecha_aprobacion TIMESTAMP WITH TIME ZONE,
  sello_digital_path TEXT
);

-- 6. TABLA DE DETALLE DE LA ORDEN
CREATE TABLE detalle_orden (
  id SERIAL PRIMARY KEY,
  orden_id INTEGER REFERENCES ordenes_compra(id) ON DELETE CASCADE,
  codigo_item TEXT, --
  descripcion TEXT, --
  cantidad INTEGER NOT NULL, --
  costo_unitario DECIMAL(10,2) NOT NULL, --
  subtotal DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * costo_unitario) STORED --
);


--------------------------------------


-- 1. Permitir que los usuarios vean su propio perfil
ALTER POLICY "Los usuarios pueden ver su propio perfil" ON perfiles
FOR SELECT USING (auth.uid() = id);

-- 2. Permitir que el Asistente inserte órdenes de compra
ALTER POLICY "Asistentes pueden insertar OC" ON ordenes_compra
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM perfiles 
    WHERE id = auth.uid() AND rol_id = 3 -- 3 es el ID de Asistente
  )
);

-- 3. Permitir que todos los autenticados vean proveedores
ALTER POLICY "Usuarios autenticados ven proveedores" ON proveedores
FOR SELECT TO authenticated USING (true);

-- no funcionò

----------------------------------------------------------------

-- 1. Política para la tabla Perfiles
-- Permite que cada usuario lea únicamente su propio perfil
CREATE POLICY "Los usuarios pueden ver su propio perfil" 
ON perfiles FOR SELECT 
USING (auth.uid() = id);

-- 2. Política para la tabla Ordenes de Compra
-- Permite que el Asistente Ingeniero (rol_id 3) inserte nuevas órdenes
CREATE POLICY "Asistentes pueden insertar OC" 
ON ordenes_compra FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM perfiles 
    WHERE id = auth.uid() AND rol_id = 3
  )
);

-- 3. Política para la tabla Proveedores
-- Permite que cualquier usuario que haya iniciado sesión pueda ver la lista de proveedores
CREATE POLICY "Usuarios autenticados ven proveedores" 
ON proveedores FOR SELECT 
TO authenticated 
USING (true);

-- 4. Política de lectura para Ordenes de Compra
-- Permite que todos los empleados vean las órdenes para que aparezcan en el Dashboard
CREATE POLICY "Usuarios autenticados ven ordenes" 
ON ordenes_compra FOR SELECT 
TO authenticated 
USING (true);

-- este si funcionò
------------------------------------------------------------------------------------------------------


-- Permitir que cualquier usuario autenticado pueda registrar proveedores
CREATE POLICY "Usuarios pueden insertar proveedores" 
ON proveedores FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- También necesitamos permiso para verlos una vez creados (si no lo pusiste antes)
CREATE POLICY "Usuarios pueden ver proveedores" 
ON proveedores FOR SELECT 
TO authenticated 
USING (true);


-------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS empresa (
    id PRIMARY KEY DEFAULT 1, -- Usamos ID 1 para que solo exista un registro de configuración
    nombre_empresa TEXT NOT NULL,
    direccion1 TEXT,
    direccion2 TEXT,
    municipio TEXT,
    pais TEXT DEFAULT 'El Salvador',
    telefono_voice TEXT,
    tipo_envio TEXT DEFAULT 'Airborne',
    terminos_pago TEXT DEFAULT 'Net 30 days',
    giro_actividad TEXT,
    nit TEXT,
    nrc TEXT,
    CONSTRAINT single_row CHECK (id = 1)
);

-- Habilitar seguridad para que puedas leer y escribir
ALTER TABLE empresa ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir todo a usuarios autenticados" ON empresa FOR ALL TO authenticated USING (true);


--- no funcionò

----------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS empresa (
    id INTEGER PRIMARY KEY DEFAULT 1, 
    nombre_empresa TEXT NOT NULL,
    direccion1 TEXT,
    direccion2 TEXT,
    municipio TEXT,
    pais TEXT DEFAULT 'El Salvador',
    telefono_voice TEXT,
    tipo_envio TEXT DEFAULT 'Airborne',
    terminos_pago TEXT DEFAULT 'Net 30 days',
    giro_actividad TEXT,
    nit TEXT,
    nrc TEXT,
    CONSTRAINT single_row CHECK (id = 1)
);

-- Habilitar seguridad (RLS)
ALTER TABLE empresa ENABLE ROW LEVEL SECURITY;

-- Crear política de acceso para usuarios autenticados
CREATE POLICY "Permitir todo a usuarios autenticados" 
ON empresa FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);


-- si funcionò

----------------------------------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS proyectos (
    id SERIAL PRIMARY KEY,
    nombre_proyecto TEXT NOT NULL,
    codigo_proyecto TEXT UNIQUE, -- Ej: PRY-2026-01
    ubicacion_proyecto TEXT,
    estado TEXT DEFAULT 'Activo',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE proyectos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios autenticados gestionan proyectos" 
ON proyectos FOR ALL TO authenticated USING (true);

----------------------------------------------------------------------------------------------------------------
-- Habilita que cualquiera con la anon key pueda leer los proyectos
create policy "Permitir lectura publica de proyectos"
on public.proyectos
for select
to anon
using (true);



-- Habilita que cualquiera con la anon key pueda leer los proveedores
create policy "Permitir lectura publica de proveedores"
on public.proveedores
for select
to anon
using (true);

------------------------------------------------------------------------------------------------------------------

--- con esto puedo ver los estados de cada tabla , rls y policy 

-- 1. Listar todas tus tablas y sus columnas

SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_schema = 'public'
ORDER BY 
    table_name;


-- 2. Revisar las Políticas de Seguridad (RLS)


SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM 
    pg_policies
WHERE 
    schemaname = 'public';


-- 3. Verificar si el RLS está activo

SELECT 
    relname AS tabla, 
    relrowsecurity AS rls_activado
FROM 
    pg_class c
JOIN 
    pg_namespace n ON n.oid = c.relnamespace
WHERE 
    n.nspname = 'public' 
    AND c.relkind = 'r';


-------------------------------------------------------------------------------------------------------------------

-- con esto se eliminan las policys que no me sirve y se definen una nueva

-- 1. TABLA: PROVEEDORES
DROP POLICY IF EXISTS "Permitir lectura publica de proveedores" ON proveedores;
DROP POLICY IF EXISTS "Usuarios pueden ver proveedores" ON proveedores;
DROP POLICY IF EXISTS "Usuarios pueden insertar proveedores" ON proveedores;
DROP POLICY IF EXISTS "Usuarios autenticados ven proveedores" ON proveedores;
CREATE POLICY "Permitir todo a usuarios autenticados" ON proveedores FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 2. TABLA: PROYECTOS
DROP POLICY IF EXISTS "Permitir lectura publica de proyectos" ON proyectos;
DROP POLICY IF EXISTS "Usuarios autenticados gestionan proyectos" ON proyectos;
CREATE POLICY "Permitir todo a usuarios autenticados" ON proyectos FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 3. TABLA: ORDENES_COMPRA
DROP POLICY IF EXISTS "Usuarios autenticados ven ordenes" ON ordenes_compra;
DROP POLICY IF EXISTS "Asistentes pueden insertar OC" ON ordenes_compra;
CREATE POLICY "Permitir todo a usuarios autenticados" ON ordenes_compra FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 4. TABLA: DETALLE_ORDEN
DROP POLICY IF EXISTS "Permitir todo a usuarios autenticados" ON detalle_orden;
CREATE POLICY "Permitir todo a usuarios autenticados" ON detalle_orden FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 5. TABLA: EMPRESA
DROP POLICY IF EXISTS "Permitir todo a usuarios autenticados" ON empresa;
CREATE POLICY "Permitir todo a usuarios autenticados" ON empresa FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 6. TABLA: PERFILES
DROP POLICY IF EXISTS "Los usuarios pueden ver su propio perfil" ON perfiles;
CREATE POLICY "Permitir todo a usuarios autenticados" ON perfiles FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 7. TABLA: ROLES
DROP POLICY IF EXISTS "Permitir todo a usuarios autenticados" ON roles;
CREATE POLICY "Permitir todo a usuarios autenticados" ON roles FOR ALL TO authenticated USING (true) WITH CHECK (true);

------------------------------------------------------------------------------------------------------------------

-- verificando por que no guarda nrc_nit en proveedores
-- validamos la tabla proveedores
-- estructura en json
-- update a la tabla proveedores

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'proveedores'
AND table_schema = 'public';

/*

[
  {
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO"
  },
  {
    "column_name": "nombre_comercial",
    "data_type": "text",
    "is_nullable": "NO"
  },
  {
    "column_name": "direccion",
    "data_type": "text",
    "is_nullable": "YES"
  },
  {
    "column_name": "nit",
    "data_type": "text",
    "is_nullable": "YES"
  },
  {
    "column_name": "terminos_pago",
    "data_type": "text",
    "is_nullable": "YES"
  },
  {
    "column_name": "nrc",
    "data_type": "text",
    "is_nullable": "YES"
  },
  {
    "column_name": "numerotelefono",
    "data_type": "text",
    "is_nullable": "YES"
  },
  {
    "column_name": "email",
    "data_type": "text",
    "is_nullable": "YES"
  },
  {
    "column_name": "razon_social",
    "data_type": "text",
    "is_nullable": "YES"
  }
]
*/


-- Cambiamos el nombre de 'nit' a 'nrc_nit' para que coincida con tu JavaScript
ALTER TABLE public.proveedores 
RENAME COLUMN nit TO nrc_nit;



--- corriguiendo datos en ordenes de compra.
-- la fecha era uno de ellos
-- gemini encontro los tipos de datos para modificarlos.
-- se muestra el query de la tabla.
-- estructura en json de la tabla ordenes_compra
-- update a la tabla ordenes_compra


SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'ordenes_compra'
AND table_schema = 'public';



/*
[
  {
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO"
  },
  {
    "column_name": "numero_orden",
    "data_type": "text",
    "is_nullable": "NO"
  },
  {
    "column_name": "fecha_emision",
    "data_type": "date",
    "is_nullable": "YES"
  },
  {
    "column_name": "proveedor_id",
    "data_type": "integer",
    "is_nullable": "YES"
  },
  {
    "column_name": "monto_total",
    "data_type": "numeric",
    "is_nullable": "YES"
  },
  {
    "column_name": "estado",
    "data_type": "text",
    "is_nullable": "YES"
  },
  {
    "column_name": "fecha_vencimiento",
    "data_type": "date",
    "is_nullable": "YES"
  },
  {
    "column_name": "registrado_por",
    "data_type": "uuid",
    "is_nullable": "YES"
  },
  {
    "column_name": "aprobado_por",
    "data_type": "uuid",
    "is_nullable": "YES"
  },
  {
    "column_name": "fecha_aprobacion",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES"
  },
  {
    "column_name": "sello_digital_path",
    "data_type": "text",
    "is_nullable": "YES"
  }
]
*/





-- 1. Renombrar columnas para que coincidan con el HTML
ALTER TABLE ordenes_compra RENAME COLUMN fecha_emision TO fecha;
ALTER TABLE ordenes_compra RENAME COLUMN monto_total TO total;

-- 2. Cambiar el tipo de dato de numero_orden a integer para que coincida con el parseInt() del JS
ALTER TABLE ordenes_compra 
ALTER COLUMN numero_orden TYPE integer USING (numero_orden::integer);

-- 3. Agregar la columna faltante para el Proyecto
ALTER TABLE ordenes_compra 
ADD COLUMN IF NOT EXISTS proyecto_id integer;

-- 4. Limpiar el caché de Supabase para que reconozca los cambios inmediatamente
NOTIFY pgrst, 'reload schema';


/*
Se quitan los campos innecesarios en ordenes de compra
*/

-- 1. Eliminar campos que no se utilizarán
ALTER TABLE ordenes_compra 
DROP COLUMN IF EXISTS aprobado_por,
DROP COLUMN IF EXISTS sello_digital_path;

-- 2. Asegurar que las columnas para el registro existan con el tipo correcto
ALTER TABLE ordenes_compra 
ADD COLUMN IF NOT EXISTS fecha_vencimiento date,
ADD COLUMN IF NOT EXISTS registrado_por text; -- Cambiado a text para guardar el nombre del usuario

-- 3. Refrescar el caché del esquema
NOTIFY pgrst, 'reload schema';


--- cambio se agrega el campo del DTE 

-- 1. Agregar la columna DTE como texto
ALTER TABLE ordenes_compra 
ADD COLUMN IF NOT EXISTS numero_factura_dte text;

-- 4. Refrescar caché
NOTIFY pgrst, 'reload schema';


---- se modifica el campo registrado por , se quita el fk y se cambia tipo de dato



-- 1. Eliminar la restricción de llave foránea que causa el error
ALTER TABLE ordenes_compra 
DROP CONSTRAINT IF EXISTS ordenes_compra_registrado_por_fkey;

-- 2. Ahora sí, cambiar registrado_por de UUID a TEXT
ALTER TABLE ordenes_compra 
ALTER COLUMN registrado_por TYPE text;



-- 5. Refrescar el esquema para que Supabase reconozca los cambios de tipos
NOTIFY pgrst, 'reload schema';

---------------------------------------


-- 1. Asegurar que la columna de factura exista
ALTER TABLE ordenes_compra 
ADD COLUMN IF NOT EXISTS numero_factura_dte text;

-- 2. Crear la relación con Proveedores (si no existe)
ALTER TABLE ordenes_compra
ADD CONSTRAINT fk_proveedor
FOREIGN KEY (proveedor_id) 
REFERENCES proveedores(id);

-- 3. Crear la relación con Proyectos (El error de la imagen 6)
ALTER TABLE ordenes_compra
ADD CONSTRAINT fk_proyecto
FOREIGN KEY (proyecto_id) 
REFERENCES proyectos(id);


-- 1. Resolver error de relación con Proyectos (Error PGRST200)
-- Esto crea explícitamente la llave foránea que la API no detecta
ALTER TABLE IF EXISTS public.ordenes_compra
DROP CONSTRAINT IF EXISTS fk_proyecto;

ALTER TABLE public.ordenes_compra
ADD CONSTRAINT fk_proyecto
FOREIGN KEY (proyecto_id) 
REFERENCES proyectos(id)
ON DELETE SET NULL;

-- 2. Asegurar que la columna de factura sea reconocida
-- A veces el caché falla si la columna se creó recientemente
ALTER TABLE public.ordenes_compra 
ALTER COLUMN numero_factura_dte SET DATA TYPE text;

-- 3. Refrescar el caché del esquema (Opcional pero recomendado)
-- Esto ayuda a que Supabase "sepa" que los cambios ya están ahí
NOTIFY pgrst, 'reload schema';


ALTER TABLE ordenes_compra 
DROP CONSTRAINT fk_proveedor;


-- Crear la tabla de ítems
CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    nombre_item TEXT NOT NULL UNIQUE
);


-- se crea un bucket para que pueda guardar todos los pdfs 

-- se modifica la tabla ordenes_compra para agregar los campos de URL de los documentos relacionados
ALTER TABLE ordenes_compra 
ADD COLUMN url_factura TEXT,
ADD COLUMN url_orden_compra TEXT,
ADD COLUMN url_comprobante_pago TEXT;