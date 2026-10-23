-- Attendify: Supabase schema. Run once in Supabase > SQL Editor > New query > Run.
-- Safe to run again (every statement is "if not exists" or "create or replace").
-- Creates the 8 tables the app reads and writes, then opens them up to the
-- app's anon key. See the security note at the bottom before you go live.

create extension if not exists pgcrypto;

-- Students --------------------------------------------------------------
create table if not exists public.students (
  sid         text primary key,
  name        text not null,
  strand      text,
  pin_hash    text,
  pin_plain   text,
  pin_changed boolean default false,
  photo       text,
  deleted_at  timestamptz
);

-- Staff / admins ----------------------------------------------------------
create table if not exists public.staff (
  id         text primary key,
  name       text not null,
  role       text,
  key_hash   text,
  can_edit   boolean default false,
  photo      text,
  deleted_at timestamptz
);

-- Student attendance records ---------------------------------------------
create table if not exists public.records (
  id     uuid primary key default gen_random_uuid(),
  sid    text not null references public.students(sid) on delete cascade,
  name   text,
  date   date not null,
  time   text,
  status text,
  by     text,
  unique (sid, date)
);

-- Staff's own attendance records ------------------------------------------
create table if not exists public.staff_attendance (
  id       uuid primary key default gen_random_uuid(),
  staff_id text not null references public.staff(id) on delete cascade,
  name     text,
  date     date not null,
  time     text,
  status   text,
  by       text,
  unique (staff_id, date)
);

-- Fines --------------------------------------------------------------------
create table if not exists public.fines (
  id     uuid primary key default gen_random_uuid(),
  sid    text not null references public.students(sid) on delete cascade,
  title  text,
  reason text,
  amount numeric not null default 0,
  date   date,
  by     text
);

-- Payments -------------------------------------------------------------------
create table if not exists public.payments (
  id     uuid primary key default gen_random_uuid(),
  sid    text not null references public.students(sid) on delete cascade,
  amount numeric not null default 0,
  method text,
  by     text,
  at     timestamptz default now()
);

-- Daily attendance windows (open / late-after / close times) ----------------
create table if not exists public.windows (
  date    date primary key,
  title   text,
  start_t text,
  late_t  text,
  close_t text,
  closed  boolean default false,
  by      text
);

-- School-wide settings (school name, ID prefixes, school days, etc.) --------
create table if not exists public.settings (
  key   text primary key,
  value text
);

-- Helpful indexes ------------------------------------------------------------
create index if not exists records_date_idx on public.records (date);
create index if not exists staff_attendance_date_idx on public.staff_attendance (date);
create index if not exists fines_sid_idx on public.fines (sid);
create index if not exists payments_sid_idx on public.payments (sid);

-- Row Level Security ----------------------------------------------------------
-- The app has no server of its own: the browser talks to Supabase directly
-- using the public "anon" key, and the app's own Student ID / PIN and Staff
-- access key are what gate who can do what inside the app's screens.
-- These policies let that anon key read and write every table so the app
-- works; see the note below about what this means for security.
do $$
declare t text;
begin
  for t in select unnest(array['students','staff','records','staff_attendance','fines','payments','windows','settings'])
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists anon_all on public.%I', t);
    execute format('create policy anon_all on public.%I for all to anon, authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- SECURITY NOTE: your Supabase URL and anon key live in config.js inside your
-- public GitHub repo, so anyone who finds them can call the Supabase API
-- directly and bypass the app's own login screens. This is the same trade-off
-- the app always had with Supabase + a public repo/site, not something new.
-- To reduce the risk:
--   * Don't put real students' full legal names, photos, or other sensitive
--     data in a school's test/demo project if the repo is public.
--   * Consider keeping the GitHub repo private (GitHub Pages still works from
--     a private repo on GitHub Pro, or free for school/education accounts).
--   * Rotate the anon key in Supabase if you ever suspect it's been exposed
--     beyond your own repo.
