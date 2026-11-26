-- AT Recovery RPG v2.0 (ATP Pomodoro) — Optional Supabase Free-Tier Schema
-- Stores complete v2.0 RPG progression inside user_state.payload (Citadel, Journey, Stats, Skills, Armory)
-- with Row-Level Security so each authenticated user owns only their encrypted/private records.

create table if not exists public.user_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.urge_logs (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  timestamp_utc timestamptz not null,
  type text not null,
  intensity integer not null,
  triggers jsonb not null default '[]'::jsonb,
  mood text not null default '',
  note text not null default '',
  updated_at timestamptz not null,
  is_deleted boolean not null default false,
  primary key (user_id, id)
);

create table if not exists public.quests (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  xp_reward integer not null default 25,
  gold_reward integer not null default 10,
  completed_today boolean not null default false,
  streak_count integer not null default 0,
  last_completed_date text,
  updated_at timestamptz not null,
  is_deleted boolean not null default false,
  primary key (user_id, id)
);

alter table public.user_state enable row level security;
alter table public.urge_logs enable row level security;
alter table public.quests enable row level security;

drop policy if exists "user_state_owner_all" on public.user_state;
create policy "user_state_owner_all" on public.user_state
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "urge_logs_owner_all" on public.urge_logs;
create policy "urge_logs_owner_all" on public.urge_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "quests_owner_all" on public.quests;
create policy "quests_owner_all" on public.quests
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
