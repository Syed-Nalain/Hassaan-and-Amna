-- Hassaan & Amna games: two new scoreboard tables (Khana Khul Gaya! and Shagun Catch).
-- Run this once in Supabase → SQL Editor → New query → Run.
-- Same rules as Shagun Catch: one row per name (its best score), guests can read and submit only.

create table if not exists public.ha_khana_scores (
  id bigint generated always as identity primary key,
  name text not null check (char_length(name) between 1 and 24),
  team text not null check (team in ('Team Hassaan', 'Team Amna')),
  score int not null check (score between 0 and 20000),
  created_at timestamptz not null default now()
);

create unique index if not exists ha_khana_scores_name_unique on public.ha_khana_scores (lower(btrim(name)));

alter table public.ha_khana_scores enable row level security;
drop policy if exists "anyone can read ha khana scores" on public.ha_khana_scores;
create policy "anyone can read ha khana scores" on public.ha_khana_scores for select using (true);
grant select on public.ha_khana_scores to anon;

-- The game saves through this function: a new name is added,
-- an existing name is only updated when the new score is higher.
create or replace function public.submit_ha_khana_score(p_name text, p_team text, p_score int)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  clean_name text := btrim(p_name);
begin
  if clean_name = '' or char_length(clean_name) > 24 then raise exception 'invalid name'; end if;
  if p_team not in ('Team Hassaan', 'Team Amna') then raise exception 'invalid team'; end if;
  if p_score < 0 or p_score > 20000 then raise exception 'invalid score'; end if;

  insert into public.ha_khana_scores (name, team, score)
  values (clean_name, p_team, p_score)
  on conflict ((lower(btrim(name)))) do update
    set score = excluded.score, team = excluded.team, name = excluded.name, created_at = now()
    where excluded.score > public.ha_khana_scores.score;
end;
$$;

revoke all on function public.submit_ha_khana_score(text, text, int) from public;
grant execute on function public.submit_ha_khana_score(text, text, int) to anon;


-- ===== Shagun Catch =====
create table if not exists public.ha_game_scores (
  id bigint generated always as identity primary key,
  name text not null check (char_length(name) between 1 and 24),
  team text not null check (team in ('Team Hassaan', 'Team Amna')),
  score int not null check (score between 0 and 1000000),
  created_at timestamptz not null default now()
);

create unique index if not exists ha_game_scores_name_unique on public.ha_game_scores (lower(btrim(name)));

alter table public.ha_game_scores enable row level security;
drop policy if exists "anyone can read ha shagun scores" on public.ha_game_scores;
create policy "anyone can read ha shagun scores" on public.ha_game_scores for select using (true);
grant select on public.ha_game_scores to anon;

-- The game saves through this function: a new name is added,
-- an existing name is only updated when the new score is higher.
create or replace function public.submit_ha_score(p_name text, p_team text, p_score int)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  clean_name text := btrim(p_name);
begin
  if clean_name = '' or char_length(clean_name) > 24 then raise exception 'invalid name'; end if;
  if p_team not in ('Team Hassaan', 'Team Amna') then raise exception 'invalid team'; end if;
  if p_score < 0 or p_score > 1000000 then raise exception 'invalid score'; end if;

  insert into public.ha_game_scores (name, team, score)
  values (clean_name, p_team, p_score)
  on conflict ((lower(btrim(name)))) do update
    set score = excluded.score, team = excluded.team, name = excluded.name, created_at = now()
    where excluded.score > public.ha_game_scores.score;
end;
$$;

revoke all on function public.submit_ha_score(text, text, int) from public;
grant execute on function public.submit_ha_score(text, text, int) to anon;


-- Check: should return an empty table the first time.
select name, team, score from public.ha_khana_scores order by score desc limit 20;
