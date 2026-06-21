// netlify/functions/update-stock.js
// Esta función corre en el SERVIDOR de Netlify, nunca en el navegador.
// Por eso puede usar la clave secreta (service_role) sin riesgo.

const { createClient } = require('@supabase/supabase-js');

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Método no permitido' };
  }

  const body = JSON.parse(event.body || '{}');
  const { password, id_insumo, nuevo_stock } = body;

  // Chequeo de contraseña simple (la definís en Netlify, ver paso a paso)
  if (password !== process.env.ADMIN_PASSWORD) {
    return { statusCode: 401, body: JSON.stringify({ error: 'Contraseña incorrecta' }) };
  }

  if (id_insumo === undefined || nuevo_stock === undefined) {
    return { statusCode: 400, body: JSON.stringify({ error: 'Faltan datos' }) };
  }

  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY // clave secreta, solo vive en Netlify
  );

  const { error } = await supabase
    .from('insumos')
    .update({ stock_actual: nuevo_stock })
    .eq('id_insumo', id_insumo);

  if (error) {
    return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
  }

  return { statusCode: 200, body: JSON.stringify({ ok: true }) };
};
