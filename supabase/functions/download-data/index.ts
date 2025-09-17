// Supabase Edge Function: download-data
// Generates CSV/JSON for a single user or all users (admin-only for all)
// Expects JSON: { userId?: string, format: 'csv'|'json' }

import { createClient } from '@supabase/supabase-js'
import { stringify } from 'csv-stringify/sync'

export const config = { runtime: 'edge' }

export default async function handler(req: Request) {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })
  const { userId, format = 'csv' } = await req.json().catch(() => ({}))

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // Fetch data
  let query = admin.from('profiles').select('id,name,email,business_name,sector')
  if (userId) query = query.eq('id', userId)
  const { data: profiles, error } = await query
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 })

  if (format === 'json') {
    return new Response(JSON.stringify({ profiles }), { status: 200, headers: { 'Content-Type': 'application/json' } })
  }

  const csv = stringify(profiles || [], { header: true })
  return new Response(csv, { status: 200, headers: { 'Content-Type': 'text/csv' } })
}


