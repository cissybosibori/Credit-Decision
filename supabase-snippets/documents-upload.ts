import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string
export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export async function uploadDocument(userId: string, file: File, docType: string) {
  const key = `${userId}/${crypto.randomUUID()}_${file.name}`
  const { error: upErr } = await supabase.storage.from('documents').upload(key, file, { contentType: file.type })
  if (upErr) throw upErr
  const { error: dbErr } = await supabase.from('documents').insert({ user_id: userId, name: file.name, type: file.type, size: file.size, url: key, document_type: docType })
  if (dbErr) throw dbErr
  return key
}


