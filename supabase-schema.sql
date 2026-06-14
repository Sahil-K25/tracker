-- ============================================================
--  Patron / Rowan — complete Supabase setup.
--  Run this ONCE in your Supabase project:  SQL Editor → New query → paste → Run.
--  It sets up BOTH:
--    1. the data table  (everything except photos: finance, water, gym, goals…)
--    2. the photo storage bucket + permissions  (progress pictures)
--  Accounts: Supabase Auth (email/password) — every row is owned by the
--  signed-in user (auth.uid()) and only that user can read/write it.
--  Re-running is safe.
-- ============================================================

-- 1) DATA — one table holds every page's saved state as JSON, keyed by page,
--    one row per (user, key).
create table if not exists app_state (
  user_id    uuid not null references auth.users(id) on delete cascade,
  key        text not null,
  data       jsonb,
  updated_at timestamptz default now(),
  primary key (user_id, key)
);

-- Migrating from the old single-row-per-key schema (no accounts, no user_id):
-- add the column, drop the now-orphaned old row(s) — their data still lives
-- in each device's localStorage and gets re-pushed once that device signs in
-- — then tighten the primary key.
alter table app_state add column if not exists user_id uuid references auth.users(id) on delete cascade;
delete from app_state where user_id is null;
alter table app_state alter column user_id set not null;
alter table app_state drop constraint if exists app_state_pkey;
alter table app_state add primary key (user_id, key);

alter table app_state enable row level security;
drop policy if exists "app_state rw" on app_state;
drop policy if exists "app_state owner rw" on app_state;
create policy "app_state owner rw" on app_state for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 2) PHOTOS — a Storage bucket for progress pictures (this is the part that
--    breaks when photos get stuffed into the table/browser instead).
--    public = true so the app can display them by URL. Each user's photos
--    live under a <user_id>/ folder.
insert into storage.buckets (id, name, public)
values ('progress-photos', 'progress-photos', true)
on conflict (id) do nothing;

-- 3) PHOTO PERMISSIONS — anyone can view (public bucket), but only the owner
--    can upload/delete inside their own <user_id>/ folder.
drop policy if exists "progress read"   on storage.objects;
drop policy if exists "progress write"  on storage.objects;
drop policy if exists "progress delete" on storage.objects;
create policy "progress read" on storage.objects for select
  using (bucket_id = 'progress-photos');
create policy "progress write own" on storage.objects for insert
  with check (bucket_id = 'progress-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "progress delete own" on storage.objects for delete
  using (bucket_id = 'progress-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- 4) REALTIME — lets your other devices receive snapshot updates instantly
--    (without this, sync still works but only when you re-open / refocus a tab).
--    Safe to re-run: only adds the table if it isn't already published.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'app_state'
  ) then
    alter publication supabase_realtime add table app_state;
  end if;
end $$;

-- Done. Set SUPABASE_URL + SUPABASE_ANON_KEY as Vercel env vars (Settings → API
-- gives you both), redeploy, and every device syncs automatically.
