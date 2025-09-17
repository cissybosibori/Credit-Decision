-- DROP in reverse dependency order
drop trigger if exists trg_applications_audit on public.applications;
drop function if exists public.log_application_update();

drop table if exists public.exports cascade;
drop table if exists public.audit_logs cascade;
drop table if exists public.assessments cascade;
drop table if exists public.risk_alerts cascade;
drop table if exists public.admin_annotations cascade;
drop table if exists public.admin_preferences cascade;

drop table if exists public.user_preferences cascade;
drop table if exists public.surveys cascade;
drop table if exists public.applications cascade;
drop table if exists public.documents cascade;
drop trigger if exists trg_profiles_updated_at on public.profiles;
drop table if exists public.profiles cascade;

drop function if exists public.set_updated_at();


