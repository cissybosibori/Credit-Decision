-- 002_admin_tables.sql
-- Admin-facing schema: admin_preferences, admin_annotations, risk_alerts, assessments, audit_logs, exports

create extension if not exists pgcrypto;

-- ADMIN PREFERENCES
create table if not exists public.admin_preferences (
  admin_id uuid primary key references auth.users(id) on delete cascade,
  preferences jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_admin_prefs_updated_at on public.admin_preferences;
create trigger trg_admin_prefs_updated_at
before update on public.admin_preferences
for each row execute function public.set_updated_at();

alter table public.admin_preferences enable row level security;

drop policy if exists admin_prefs_admin_only on public.admin_preferences;
create policy admin_prefs_admin_only on public.admin_preferences
  for all using ( coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' )
  with check ( coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' and admin_id = auth.uid() );

-- ADMIN ANNOTATIONS (notes/feedback/score)
create table if not exists public.admin_annotations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  application_id uuid references public.applications(id) on delete cascade,
  type text not null check (type in ('note','feedback','score')),
  content text,
  score numeric,
  visible boolean not null default true,
  admin_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists idx_admin_annotations_app on public.admin_annotations (application_id);
create index if not exists idx_admin_annotations_user on public.admin_annotations (user_id);

alter table public.admin_annotations enable row level security;

drop policy if exists admin_annotations_admin_only on public.admin_annotations;
create policy admin_annotations_admin_only on public.admin_annotations
  for all using ( coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' )
  with check ( coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

-- RISK ALERTS
create table if not exists public.risk_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_name text,
  risk_level text not null check (risk_level in ('low','medium','high')),
  reason text,
  flagged_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active','resolved','investigating'))
);

create index if not exists idx_risk_alerts_user on public.risk_alerts (user_id);
create index if not exists idx_risk_alerts_flagged on public.risk_alerts (flagged_at desc);

alter table public.risk_alerts enable row level security;

drop policy if exists risk_alerts_admin_only on public.risk_alerts;
create policy risk_alerts_admin_only on public.risk_alerts
  for all using ( coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' )
  with check ( coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

-- ASSESSMENTS (face_value/admin_review)
create table if not exists public.assessments (
  id uuid primary key default gen_random_uuid(),
  applicant_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('face_value','admin_review')),
  content text,
  admin_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists idx_assessments_applicant on public.assessments (applicant_id);

alter table public.assessments enable row level security;

drop policy if exists assessments_admin_only on public.assessments;
create policy assessments_admin_only on public.assessments
  for all using ( coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' )
  with check ( coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

-- AUDIT LOGS
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references auth.users(id) on delete cascade,
  action text not null,
  target text,
  details text,
  severity text not null default 'low' check (severity in ('low','medium','high','critical')),
  created_at timestamptz not null default now()
);

create index if not exists idx_audit_logs_admin on public.audit_logs (admin_id);
create index if not exists idx_audit_logs_created on public.audit_logs (created_at desc);

alter table public.audit_logs enable row level security;

drop policy if exists audit_logs_admin_select on public.audit_logs;
create policy audit_logs_admin_select on public.audit_logs
  for select using ( coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

drop policy if exists audit_logs_admin_insert on public.audit_logs;
create policy audit_logs_admin_insert on public.audit_logs
  for insert with check ( coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

-- EXPORTS (optional tracking for data exports)
create table if not exists public.exports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  format text not null check (format in ('csv','json')),
  status text not null default 'pending' check (status in ('pending','ready','failed')),
  url text,
  created_at timestamptz not null default now()
);

create index if not exists idx_exports_user on public.exports (user_id);

alter table public.exports enable row level security;

drop policy if exists exports_owner_select on public.exports;
create policy exports_owner_select on public.exports
  for select using ( user_id = auth.uid() or coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

drop policy if exists exports_insert_owner_or_admin on public.exports;
create policy exports_insert_owner_or_admin on public.exports
  for insert with check ( (user_id = auth.uid()) or coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

-- TRIGGER: On application status change, insert audit log (admin-only context typically)
create or replace function public.log_application_update()
returns trigger as $$
begin
  if (tg_op = 'UPDATE') and (new.status is distinct from old.status) then
    insert into public.audit_logs (admin_id, action, target, details, severity)
    values (
      coalesce((auth.uid())::uuid, '00000000-0000-0000-0000-000000000000'),
      'APPLICATION_STATUS_CHANGE',
      new.id::text,
      'Status changed from ' || old.status || ' to ' || new.status,
      case when new.status in ('approved','rejected') then 'high' else 'medium' end
    );
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_applications_audit on public.applications;
create trigger trg_applications_audit
after update on public.applications
for each row execute function public.log_application_update();

comment on table public.admin_preferences is 'Per-admin UI and system preferences';
comment on table public.admin_annotations is 'Admin notes/feedback/scores linked to users/applications';
comment on table public.risk_alerts is 'Risk alerts for applicants with levels and status';
comment on table public.assessments is 'Admin assessments (face value, admin review)';
comment on table public.audit_logs is 'Administrative audit trail';
comment on table public.exports is 'Export jobs and generated file URLs';


