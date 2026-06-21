# La 10 Burger — Guía paso a paso

## PARTE 1 — Crear la base de datos en Supabase

1. Entrá a https://supabase.com → creá una cuenta gratis → "New Project"
2. Ponele un nombre (ej: la10burger) y una contraseña de base de datos (guardala en un lugar seguro)
3. Esperá ~2 minutos a que el proyecto termine de crearse
4. En el menú izquierdo, click en **SQL Editor** → **New query**
5. Abrí el archivo `setup.sql` que te dejé, copiá TODO el contenido, pegalo ahí y dale **Run**
6. Si todo salió bien, en el menú izquierdo → **Table Editor** vas a ver las tablas: insumos, productos_variaciones, recetas, modificadores, recetas_modificador

## PARTE 2 — Conseguir las claves de Supabase

1. En el menú izquierdo → **Settings** (ícono de tuerca) → **API**
2. Vas a ver:
   - **Project URL** (algo como `https://xxxxx.supabase.co`)
   - **anon public** key (una clave larga)
   - **service_role** key (otra clave larga, ¡esta es secreta!)
3. Guardá las 3 en un bloc de notas, las vamos a usar ahora

## PARTE 3 — Completar config.js

1. Abrí el archivo `config.js`
2. Reemplazá `PEGA_AQUI_TU_PROJECT_URL` por tu Project URL
3. Reemplazá `PEGA_AQUI_TU_ANON_KEY` por tu anon public key
4. Guardalo

## PARTE 4 — Subir todo a Netlify

1. Entrá a https://netlify.com → creá una cuenta (podés usar GitHub o email)
2. La forma más simple sin usar GitHub: en el dashboard de Netlify, buscá la zona que dice
   **"Drag and drop your site folder here"**
3. Arrastrá la carpeta `la10burger` completa (la que tiene index.html, admin.html, config.js, la carpeta netlify/, etc.) a esa zona
4. Netlify va a publicar el sitio y te va a dar una URL tipo `https://nombre-random.netlify.app`

## PARTE 5 — Configurar las variables secretas en Netlify

Esto es CLAVE para que el panel admin funcione y nadie pueda robarte el stock:

1. En tu sitio dentro de Netlify → **Site configuration** → **Environment variables**
2. Agregá 3 variables:
   - `SUPABASE_URL` → tu Project URL
   - `SUPABASE_SERVICE_KEY` → tu service_role key (la secreta)
   - `ADMIN_PASSWORD` → la contraseña que vas a usar para entrar al panel admin (elegí una fuerte)
3. Después de guardarlas, andá a **Deploys** → **Trigger deploy** → **Deploy site** (para que tome las variables nuevas)

## PARTE 6 — Probar todo

1. Abrí `https://tu-sitio.netlify.app` → deberías ver el menú (todo va a estar "Agotado" porque el stock está en 0)
2. Abrí `https://tu-sitio.netlify.app/admin.html` → entrá con la contraseña que pusiste en `ADMIN_PASSWORD`
3. Cargá el stock real de cada insumo (panes, medallones, fetas de cheddar, gramos de papas) y dale **Guardar** en cada fila
4. Volvé al menú principal y refrescá la página → ya deberían aparecer disponibles las hamburguesas que tengan insumos suficientes
5. Probá hacer clic en "Comprar" en una y fijate que el stock se actualice (refrescá el admin para verlo)

## Cómo seguir cargando stock día a día

Simplemente entrás a `tu-sitio.netlify.app/admin.html` con la contraseña, cambiás los números, y guardás. No necesitás tocar código nunca más para esto.

## Pendiente para más adelante (cuando quieras)

- Conectar un cobro real (Mercado Pago) antes de descontar el stock
- Que el botón "Comprar" además guarde el pedido en una tabla `pedidos` con fecha/hora para tener historial de ventas
- Agregar fotos de cada hamburguesa al menú
- Reponer stock automáticamente si cancelás un pedido
