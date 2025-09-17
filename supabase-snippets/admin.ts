import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string
export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export async function listApplications() {
  const { data, error } = await supabase.from('applications').select('*').order('created_at', { ascending: false })
  if (error) throw error
  return data
}

export async function updateApplicationStatus(applicationId: string, status: 'draft'|'submitted'|'reviewing'|'approved'|'rejected'|'paused'|'conditional') {
  const { error } = await supabase.from('applications').update({ status }).eq('id', applicationId)
  if (error) throw error
}

export async function postAdminNote(applicationId: string, content: string, visible = true) {
  const { error } = await supabase.from('admin_annotations').insert({ application_id: applicationId, type: 'note', content, visible })
  if (error) throw error
}


