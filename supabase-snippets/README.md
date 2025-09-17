# Supabase Frontend Snippets

- auth-login.ts maps to src/pages/Login.tsx and src/context/AuthContext.tsx
- documents-upload.ts maps to src/components/DocumentUpload.tsx and src/services/backendService.ts (DocumentService)
- applications.ts maps to src/services/backendService.ts (ApplicationService)
- surveys.ts maps to src/pages/ProfilePage.tsx and src/services/backendService.ts (SurveyService)
- admin.ts maps to src/components/AdminDashboard.tsx and admin endpoints in backendService.ts

Each file initializes a Supabase client and provides a minimal call to match the frontend injection point.
