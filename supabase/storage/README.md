# Storage Setup

Buckets
- documents (private): stores user-uploaded documents. Path convention: `user_id/{uuid}_{originalName}`.

Recommended metadata stored in DB (public.documents):
- name (original filename)
- type (MIME)
- size (bytes)
- url (storage path key)
- document_type (business logic: mpesa_statements, utility_bills, etc.)
- uploaded_at
- status (uploaded|verified|pending)

Access rules
- Keep bucket private. Use Supabase JWT session for client SDK access.
- For server-side deletions or cross-user admin actions, use Edge Functions.

Signed uploads (optional)
- Generate a unique key on client and call `storage.from('documents').upload(key, file)`.
- For very large files, implement an Edge Function that returns a short-lived signed URL, then PUT to that URL.


