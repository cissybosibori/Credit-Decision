#!/usr/bin/env bash
set -euo pipefail

# Link project (interactive if not already linked)
supabase link --project-ref ${SUPABASE_PROJECT_REF:-}

# Apply migrations
supabase db push

# Deploy functions
for fn in create-user delete-document download-data share-heva export-user-data whatsapp-messages; do
  supabase functions deploy "$fn"
done

echo "Deployment complete. Remember to set function env vars in the dashboard."


