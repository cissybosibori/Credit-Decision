// Supabase Edge Function: create-user
// Creates an auth user (service role) and inserts profile row.
// Expects JSON body: { email, name, businessName, sector }

import { createClient } from '@supabase/supabase-js'

export const config = {
  runtime: 'edge'
}

export default async function handler(req: Request) {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })
  const { email, name, businessName, sector } = await req.json().catch(() => ({}))
  if (!email) return new Response(JSON.stringify({ error: 'email required' }), { status: 400 })

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // 1) create auth user (without password -> email invite flow) or with temp password if needed
  const { data: userRes, error: userErr } = await admin.auth.admin.createUser({ email, email_confirm: true })
  if (userErr || !userRes.user) return new Response(JSON.stringify({ error: userErr?.message || 'Failed to create user' }), { status: 500 })

  const userId = userRes.user.id
  // 2) insert profile
  const { error: profErr } = await admin.from('profiles').insert({ id: userId, email, name, business_name: businessName, sector }).single()
  if (profErr) return new Response(JSON.stringify({ error: profErr.message }), { status: 500 })

  return new Response(JSON.stringify({ userId }), { status: 200, headers: { 'Content-Type': 'application/json' } })
}


