// Supabase Edge Function: whatsapp-messages
// Proxy to WhatsApp Business API (or return stored messages). Upserts into whatsapp_messages table if used.
// Expects JSON: { userId }

import { createClient } from '@supabase/supabase-js'

export const config = { runtime: 'edge' }

export default async function handler(req: Request) {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })
  const { userId } = await req.json().catch(() => ({}))
  if (!userId) return new Response(JSON.stringify({ error: 'userId required' }), { status: 400 })

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
  const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

  // Placeholder: if integrating external provider, fetch there.
  // For now, return any stored messages if such a table is created later.
  const { data: msgs } = await admin.from('whatsapp_messages').select('*').eq('user_id', userId).order('timestamp', { ascending: false })
  return new Response(JSON.stringify({ messages: msgs || [] }), { status: 200, headers: { 'Content-Type': 'application/json' } })
}


