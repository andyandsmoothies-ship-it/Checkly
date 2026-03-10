---
name: supabase-manager
description: Expert handling of Supabase migrations, type generation, and Edge Functions. Use when modifying the database schema or backend logic.
---

# Supabase Manager

## 1. Database & Security (Original Content Retained)
- **Verify Existence**: Always check `types.ts` before proposing a schema change.
- **Migration First**: Use Supabase migrations for all DDL changes.
- **RLS Scoping**: Use internal `has_role(uid, role)` and context helpers (`get_user_store_id`).
- **Standard Pattern**: `(auditor_id = auth.uid() OR public.has_role(auth.uid(), 'admin'))`.

## 2. Edge Functions & Type Safety
- **Standard Protocol**: Every function MUST handle `OPTIONS` requests and provide CORS headers.
- **Secret Management**: Use `Deno.env.get()` for all environment variables.
- **Type-Safe Catch**: Always treat caught errors as `unknown` and use type guards before accessing `.message`.
- **Complex Join Casting**: Avoid `as unknown as`. Define explicit TS interfaces for joined data.

## 3. Checkly-Smart Nuances (Original Content Retained)
- **JSONB Management**: Tables like `submissions` use JSONB. Always use Zod on the frontend to validate these structures.
- **Snake Case**: Adhere to `snake_case` naming for all database objects.