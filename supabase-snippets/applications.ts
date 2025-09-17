import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string
export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export async function createApplication(userId: string, fundingType: 'grant'|'loan'|'investment', amount?: number) {
  const { data, error } = await supabase.from('applications').insert({ user_id: userId, funding_type: fundingType, amount }).select('*').single()
  if (error) throw error
  return data
}

export async function getUserApplication(userId: string) {
  const { data, error } = await supabase.from('applications').select('*').eq('user_id', userId).maybeSingle()
  if (error) throw error
  return data
}


