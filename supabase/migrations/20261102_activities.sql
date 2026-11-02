-- Activités : les sorties à Ottawa et à Gatineau proposées aux passagers,
-- gérées depuis le panneau d'administration.

create table public.activities (
  id text primary key check (id ~ '^[a-z0-9-]{2,60}$'),
  title_fr text not null check (char_length(title_fr) between 1 and 80),
  title_en text not null default '' check (char_length(title_en) <= 80),
  venue text not null default '' check (char_length(venue) <= 80),
  -- Rien en dehors de la région : la base le garantit.
  city text not null check (city in ('Ottawa', 'Gatineau')),
  starts_at timestamptz not null,
  link text check (link is null or link ~ '^https://'),
  photo_url text check (photo_url is null or photo_url ~ '^https://'),
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.activities enable row level security;

create policy "lecture publique des activites actives" on public.activities
  for select to anon, authenticated using (active or (select public.is_admin()));
create policy "admin ajoute" on public.activities
  for insert to authenticated with check ((select public.is_admin()));
create policy "admin modifie" on public.activities
  for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin supprime" on public.activities
  for delete to authenticated using ((select public.is_admin()));
