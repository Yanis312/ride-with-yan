-- Mesure de l'usage de la tablette : quels écrans et quels boutons servent.
--
-- Anonyme : aucun nom, aucun appareil, aucune adresse IP enregistrée. Chaque
-- passager reçoit un numéro de session tiré au hasard, oublié à la fin de sa
-- course ; il sert seulement à compter les passagers et la durée des visites.

create table public.usage_events (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  session_id uuid not null,
  kind text not null
    check (kind in ('session_start', 'session_end', 'screen', 'tap')),
  name text not null check (name ~ '^[a-z0-9_.:-]{1,60}$'),
  language text check (language in ('fr', 'en')),
  -- Durée de la session en secondes (session_end seulement).
  value integer check (value between 0 and 86400)
);

create index usage_events_created_at_idx on public.usage_events (created_at desc);

alter table public.usage_events enable row level security;

-- La tablette dépose des évènements ; elle ne peut ni les relire ni les
-- modifier. Seul l'administrateur les lit et les efface.
create policy "depot anonyme" on public.usage_events
  for insert to anon, authenticated with check (true);
create policy "admin lit" on public.usage_events
  for select to authenticated using ((select public.is_admin()));
create policy "admin supprime" on public.usage_events
  for delete to authenticated using ((select public.is_admin()));

-- Résumé pour le panneau d'administration, calculé dans la base pour ne pas
-- télécharger chaque évènement.
create or replace function public.usage_summary(since timestamptz)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if not public.is_admin() then
    raise exception 'réservé à l''administrateur';
  end if;

  with events as (
    select * from public.usage_events where created_at >= since
  ),
  sessions as (
    select session_id,
           max(language) as language,
           max(value) filter (where kind = 'session_end') as seconds
    from events
    group by session_id
  )
  select jsonb_build_object(
    'sessions', (select count(*) from sessions),
    'average_seconds',
      (select coalesce(round(avg(seconds)), 0) from sessions where seconds is not null),
    'french_sessions',
      (select count(*) from sessions where language = 'fr'),
    'screens', coalesce((
      select jsonb_agg(jsonb_build_object('name', name, 'count', n) order by n desc)
      from (select name, count(*) as n from events where kind = 'screen'
            group by name order by n desc limit 15) s), '[]'::jsonb),
    'taps', coalesce((
      select jsonb_agg(jsonb_build_object('name', name, 'count', n) order by n desc)
      from (select name, count(*) as n from events where kind = 'tap'
            group by name order by n desc limit 20) t), '[]'::jsonb),
    'hours', coalesce((
      select jsonb_agg(jsonb_build_object('hour', h, 'count', n) order by h)
      from (select extract(hour from created_at at time zone 'America/Toronto')::int as h,
                   count(*) as n
            from events where kind = 'session_start' group by h) hh), '[]'::jsonb)
  ) into result;

  return result;
end;
$$;

revoke all on function public.usage_summary(timestamptz) from public;
grant execute on function public.usage_summary(timestamptz) to authenticated;
