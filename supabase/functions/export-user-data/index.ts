// Supabase Edge Function: export-user-data
// Generates an export for the authenticated user (session-bound) and returns a signed URL or inline JSON
// Expects JSON: { format: 'csv'|'json' }

import { createClient } from '@supabase/supabase-js'
import { stringify } from 'csv-stringify/sync'

export const config = { runtime: 'edge' }

export default async function handler(req: Request) {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })

  const authHeader = req.headers.get('Authorization')
  const jwt = authHeader?.split('Bearer ')[1]
  if (!jwt) return new Response(JSON.stringify({ error: 'auth required' }), { status: 401 })

  const { format = 'json' } = await req.json().catch(() => ({}))
  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const client = createClient(SUPABASE_URL, anonKey, { global: { headers: { Authorization: `Bearer ${jwt}` } } })

  const { data: { user }, error: uerr } = await client.auth.getUser()
  if (uerr || !user) return new Response(JSON.stringify({ error: 'invalid session' }), { status: 401 })

  const { data: profile } = await client.from('profiles').select('*').eq('id', user.id).single()
  const { data: apps } = await client.from('applications').select('*').eq('user_id', user.id)
  const { data: docs } = await client.from('documents').select('*').eq('user_id', user.id)
  const exportObj = { profile, applications: apps, documents: docs }

  if (format === 'csv') {
    const csv = stringify((apps || []), { header: true })
    return new Response(csv, { status: 200, headers: { 'Content-Type': 'text/csv' } })
  }

  return new Response(JSON.stringify(exportObj), { status: 200, headers: { 'Content-Type': 'application/json' } })
}


