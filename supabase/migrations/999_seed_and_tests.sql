-- 999_seed_and_tests.sql
-- Optional seed and simple test queries

-- Seed risk levels reference usage (no separate table; inline checks already defined)

-- Example: insert a fake admin preferences row for testing (requires an admin user id)
-- insert into public.admin_preferences (admin_id, preferences) values ('00000000-0000-0000-0000-000000000000', '{"theme":"dark"}');

-- Curl examples (documentation only)
-- curl -X POST "https://<project>.functions.supabase.co/create-user" -H 'Authorization: Bearer SERVICE_ROLE' -H 'Content-Type: application/json' -d '{"email":"user@example.com","name":"User"}'
-- curl -X POST "https://<project>.functions.supabase.co/delete-document" -H 'Authorization: Bearer SERVICE_ROLE' -H 'Content-Type: application/json' -d '{"documentId":"<uuid>"}'
-- curl -X POST "https://<project>.functions.supabase.co/export-user-data" -H 'Authorization: Bearer <user_jwt>' -H 'Content-Type: application/json' -d '{"format":"json"}'


