import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string
export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export async function submitSurvey(userId: string, payload: {
  satisfaction: number;
  ease_of_use: number;
  support_quality: number;
  likelihood_to_recommend: number;
  feedback?: string;
  improvements?: string;
}) {
  const { error } = await supabase.from('surveys').upsert({ user_id: userId, ...payload }, { onConflict: 'user_id' })
  if (error) throw error
}


