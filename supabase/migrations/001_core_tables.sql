-- 001_core_tables.sql
-- Core user-facing schema for HEVA Credit-Decision app
-- Tables: profiles, documents, applications, surveys, user_preferences
-- Includes RLS policies and helpful indexes + minimal seed data

-- Enable required extensions
create extension if not exists pgcrypto; -- for gen_random_uuid

-- PROFILES: 1-1 with auth.users
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  email text unique,
  business_name text,
  sector text,
  application_id text,
  avatar text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_email on public.profiles (email);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

-- RLS: users read/update only their own profile; admins can read all via role
drop policy if exists profiles_select_self on public.profiles;
create policy profiles_select_self on public.profiles
  for select using ( id = auth.uid() or coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
  for update using ( id = auth.uid() ) with check ( id = auth.uid() );

-- DOCUMENTS: metadata for files stored in Supabase Storage (private bucket)
create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  type text,
  size bigint,
  url text not null, -- storage path key
  document_type text,
  status text not null default 'uploaded' check (status in ('uploaded','verified','pending')),
  uploaded_at timestamptz not null default now()
);

create index if not exists idx_documents_user on public.documents (user_id);
create index if not exists idx_documents_uploaded_at on public.documents (uploaded_at desc);

alter table public.documents enable row level security;

drop policy if exists documents_owner_select on public.documents;
create policy documents_owner_select on public.documents
  for select using ( user_id = auth.uid() or coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

drop policy if exists documents_owner_modify on public.documents;
create policy documents_owner_modify on public.documents
  for all using ( user_id = auth.uid() ) with check ( user_id = auth.uid() );

-- APPLICATIONS: user applications lifecycle
create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'draft' check (status in ('draft','submitted','reviewing','approved','rejected','paused','conditional')),
  funding_type text not null check (funding_type in ('grant','loan','investment')),
  amount numeric(15,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_applications_user on public.applications (user_id);
create index if not exists idx_applications_status on public.applications (status);

drop trigger if exists trg_applications_updated_at on public.applications;
create trigger trg_applications_updated_at
before update on public.applications
for each row execute function public.set_updated_at();

alter table public.applications enable row level security;

drop policy if exists applications_owner_select on public.applications;
create policy applications_owner_select on public.applications
  for select using ( user_id = auth.uid() or coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

drop policy if exists applications_owner_modify on public.applications;
drop policy if exists applications_owner_insert on public.applications;
create policy applications_owner_insert on public.applications
  for insert with check ( user_id = auth.uid() );

drop policy if exists applications_owner_update on public.applications;
create policy applications_owner_update on public.applications
  for update using ( user_id = auth.uid() ) with check ( user_id = auth.uid() );

-- SURVEYS: post-application survey per user (one row per user by default)
create table if not exists public.surveys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  satisfaction int check (satisfaction between 1 and 5),
  ease_of_use int check (ease_of_use between 1 and 5),
  support_quality int check (support_quality between 1 and 5),
  likelihood_to_recommend int check (likelihood_to_recommend between 1 and 10),
  feedback text,
  improvements text,
  submitted_at timestamptz not null default now(),
  unique (user_id)
);

create index if not exists idx_surveys_user on public.surveys (user_id);

alter table public.surveys enable row level security;

drop policy if exists surveys_owner_select on public.surveys;
create policy surveys_owner_select on public.surveys
  for select using ( user_id = auth.uid() or coalesce((auth.jwt() -> 'app_metadata' ->> 'role'),'') = 'admin' );

drop policy if exists surveys_owner_upsert on public.surveys;
create policy surveys_owner_upsert on public.surveys
  for all using ( user_id = auth.uid() ) with check ( user_id = auth.uid() );

-- USER PREFERENCES: jsonb blobs per user
create table if not exists public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  notifications jsonb not null default '{}'::jsonb,
  privacy jsonb not null default '{}'::jsonb,
  language text default 'en',
  timezone text,
  currency text,
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_user_preferences_updated_at on public.user_preferences;
create trigger trg_user_preferences_updated_at
before update on public.user_preferences
for each row execute function public.set_updated_at();

alter table public.user_preferences enable row level security;

drop policy if exists user_prefs_owner on public.user_preferences;
create policy user_prefs_owner on public.user_preferences
  for all using ( user_id = auth.uid() ) with check ( user_id = auth.uid() );

-- Minimal seed (optional; remove in prod)
-- insert into public.profiles (id, name, email, business_name, sector)
-- values ('00000000-0000-0000-0000-000000000000','Demo User','demo@example.com','Demo Biz','Fashion')
-- on conflict (id) do nothing;

comment on table public.profiles is 'User profile fields associated with auth.users';
comment on table public.documents is 'Metadata for files stored in Supabase Storage';
comment on table public.applications is 'User applications lifecycle and amounts';
comment on table public.surveys is 'Post-application survey responses';
comment on table public.user_preferences is 'Per-user UI/notification preferences';


