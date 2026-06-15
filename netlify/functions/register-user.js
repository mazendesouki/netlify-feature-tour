const { createClient } = require('@supabase/supabase-js');

exports.handler = async (event) => {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers, body: JSON.stringify({ error: 'Method not allowed' }) };
  }

  let phone, password, fullName;
  try {
    ({ phone, password, fullName } = JSON.parse(event.body));
  } catch {
    return { statusCode: 400, headers, body: JSON.stringify({ error: 'Invalid JSON' }) };
  }

  if (!phone || !password || !fullName) {
    return { statusCode: 400, headers, body: JSON.stringify({ error: 'بيانات ناقصة' }) };
  }

  const SUPABASE_URL = process.env.SUPABASE_URL || 'https://ifpopyplwpmrapaofimi.supabase.co';
  const SERVICE_KEY  = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const ANON_KEY     = process.env.SUPABASE_ANON_KEY || 'sb_publishable_kazC7uOBFXz8-AuIfXD7mA_cBb4_EtH';

  if (!SERVICE_KEY) {
    return { statusCode: 500, headers, body: JSON.stringify({ error: 'SUPABASE_SERVICE_ROLE_KEY not set' }) };
  }

  const email     = phone.replace(/\s/g, '') + '@wslha.app';
  const fullPhone = '+20' + phone.replace(/\s/g, '').replace(/^0/, '');

  const admin = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { error: createError } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName, phone: fullPhone },
  });

  if (createError && !createError.message.toLowerCase().includes('already')) {
    return { statusCode: 400, headers, body: JSON.stringify({ error: createError.message }) };
  }

  const anon = createClient(SUPABASE_URL, ANON_KEY);
  const { data: signIn, error: signInError } = await anon.auth.signInWithPassword({ email, password });

  if (signInError) {
    return { statusCode: 400, headers, body: JSON.stringify({ error: signInError.message }) };
  }

  return {
    statusCode: 200,
    headers,
    body: JSON.stringify({ session: signIn.session, user: signIn.user }),
  };
};
