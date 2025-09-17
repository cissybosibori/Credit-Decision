// Supabase Edge Function: share-heva
// Posts selected user data to HEVA external API and writes an audit log.
// Expects JSON: { userId }

import { createClient } from '@supabase/supabase-js'

export const config = { runtime: 'edge' }

export default async function handler(req: Request) {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })
  const { userId } = await req.json().catch(() => ({}))
  if (!userId) return new Response(JSON.stringify({ error: 'userId required' }), { status: 400 })

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const HEVA_API_URL = Deno.env.get('HEVA_API_URL')!
  const HEVA_API_KEY = Deno.env.get('HEVA_API_KEY')!
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  const { data: profile, error } = await admin.from('profiles').select('*').eq('id', userId).single()
  if (error || !profile) return new Response(JSON.stringify({ error: error?.message || 'profile not found' }), { status: 404 })

  const res = await fetch(`${HEVA_API_URL}/share`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${HEVA_API_KEY}` },
    body: JSON.stringify({ profile })
  })
  if (!res.ok) return new Response(JSON.stringify({ error: 'HEVA share failed', status: res.status }), { status: 502 })

  // Write audit log (admin id is not available in edge context unless passed; record system user)
  await admin.from('audit_logs').insert({ admin_id: '00000000-0000-0000-0000-000000000000', action: 'SHARE_HEVA', target: userId, details: 'Shared profile with HEVA', severity: 'high' })

  return new Response(JSON.stringify({ success: true }), { status: 200, headers: { 'Content-Type': 'application/json' } })
}


