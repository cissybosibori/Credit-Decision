# DEPLOY_SUPABASE.md

Prereqs
- Install Supabase CLI: https://supabase.com/docs/guides/cli
- Node 18+ for Edge Functions

1) Create Supabase project
- In Supabase dashboard, create a new project.
- Note SUPABASE_URL and SUPABASE_ANON_KEY.
- Generate a SERVICE_ROLE key (keep secret; do not commit or expose).

2) Apply migrations
```bash
supabase link --project-ref <PROJECT_REF>
# Push migrations in order
supabase db push
```

3) Create Storage bucket
- In dashboard: Storage → New bucket → name: `documents` → Private.

4) Deploy Edge Functions
```bash
# From repo root
supabase functions deploy create-user
supabase functions deploy delete-document
supabase functions deploy download-data
supabase functions deploy share-heva
supabase functions deploy export-user-data
supabase functions deploy whatsapp-messages
```

5) Configure function env vars (in dashboard or CLI)
- SUPABASE_URL
- SUPABASE_SERVICE_ROLE_KEY (functions only)
- SUPABASE_ANON_KEY (for export-user-data if verifying user session)
- HEVA_API_URL, HEVA_API_KEY (for share-heva)

6) Frontend env vars
- VITE_SUPABASE_URL=<project-url>
- VITE_SUPABASE_ANON_KEY=<anon>

7) Verify
- Sign up a test user via Auth → Users or front-end signUp.
- Upload a file to `documents` bucket via frontend; confirm row in `documents` table.
- Create application and survey rows.
- Call functions via `supabase.functions.invoke(...)`.

Rollback
- To revert last migration: `supabase db reset` (local) or create down migration SQL to drop created tables.

Security Notes
- All user data tables have RLS enabled; admin-only tables guarded by app_metadata.role = 'admin'.
- Never expose SERVICE_ROLE to frontend.


