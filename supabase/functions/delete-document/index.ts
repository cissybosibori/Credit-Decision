// Supabase Edge Function: delete-document
// Deletes a document: removes storage object and DB row transactionally (best effort)
// Expects JSON: { documentId }

import { createClient } from '@supabase/supabase-js'

export const config = { runtime: 'edge' }

export default async function handler(req: Request) {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })
  const { documentId } = await req.json().catch(() => ({}))
  if (!documentId) return new Response(JSON.stringify({ error: 'documentId required' }), { status: 400 })

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  const { data: doc, error: selErr } = await admin.from('documents').select('*').eq('id', documentId).single()
  if (selErr || !doc) return new Response(JSON.stringify({ error: selErr?.message || 'Not found' }), { status: 404 })

  const storage = admin.storage.from('documents')
  // delete storage object first
  const { error: delErr } = await storage.remove([doc.url])
  if (delErr) return new Response(JSON.stringify({ error: delErr.message }), { status: 500 })

  const { error: dbErr } = await admin.from('documents').delete().eq('id', documentId)
  if (dbErr) return new Response(JSON.stringify({ error: dbErr.message }), { status: 500 })

  return new Response(JSON.stringify({ success: true }), { status: 200, headers: { 'Content-Type': 'application/json' } })
}


