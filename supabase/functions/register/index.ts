import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const { phone, password, fullName } = await req.json()

  if (!phone || !password || !fullName) {
    return new Response(JSON.stringify({ error: 'بيانات ناقصة' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  const supabaseUrl  = Deno.env.get('SUPABASE_URL')!
  const serviceKey   = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const anonKey      = Deno.env.get('SUPABASE_ANON_KEY')!

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false }
  })

  const email     = phone.replace(/\s/g, '') + '@wslha.app'
  const fullPhone = '+20' + phone.replace(/\s/g, '').replace(/^0/, '')

  const { error: createError } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName, phone: fullPhone }
  })

  if (createError && !createError.message.toLowerCase().includes('already')) {
    return new Response(JSON.stringify({ error: createError.message }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  const anon = createClient(supabaseUrl, anonKey)
  const { data: signIn, error: signInError } = await anon.auth.signInWithPassword({ email, password })

  if (signInError) {
    return new Response(JSON.stringify({ error: signInError.message }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  return new Response(JSON.stringify({ session: signIn.session, user: signIn.user }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
})
