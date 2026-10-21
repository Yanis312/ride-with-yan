-- Annonceurs : les commerces partenaires affichés dans la section publicité,
-- gérés depuis le panneau d'administration au lieu d'être écrits dans l'app.

create table public.advertisers (
  id text primary key check (id ~ '^[a-z0-9-]{2,40}$'),
  name text not null check (char_length(name) between 1 and 60),
  category_fr text not null default '' check (char_length(category_fr) <= 60),
  category_en text not null default '' check (char_length(category_en) <= 60),
  description_fr text not null default '' check (char_length(description_fr) <= 300),
  description_en text not null default '' check (char_length(description_en) <= 300),
  -- Offre réservée aux passagers (ex. « −10 % avec Ride with Yan »).
  offer_fr text not null default '' check (char_length(offer_fr) <= 80),
  offer_en text not null default '' check (char_length(offer_en) <= 80),
  address text not null default '' check (char_length(address) <= 120),
  phone text not null default '' check (char_length(phone) <= 30),
  hours_fr text not null default '' check (char_length(hours_fr) <= 80),
  hours_en text not null default '' check (char_length(hours_en) <= 80),
  lat double precision check (lat between -90 and 90),
  lng double precision check (lng between -180 and 180),
  -- Couleur du visuel (sans photo), en hexadécimal : « E8A23A ».
  color text not null default 'E8A23A' check (color ~ '^[0-9A-Fa-f]{6}$'),
  photo_url text check (photo_url is null or photo_url ~ '^https://'),
  website text check (website is null or website ~ '^https://'),
  instagram text check (instagram is null or instagram ~ '^https://'),
  tiktok text check (tiktok is null or tiktok ~ '^https://'),
  facebook text check (facebook is null or facebook ~ '^https://'),
  active boolean not null default true,
  sort integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.advertisers enable row level security;

create policy "lecture publique des annonceurs actifs" on public.advertisers
  for select to anon, authenticated using (active or (select public.is_admin()));
create policy "admin ajoute" on public.advertisers
  for insert to authenticated with check ((select public.is_admin()));
create policy "admin modifie" on public.advertisers
  for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin supprime" on public.advertisers
  for delete to authenticated using ((select public.is_admin()));
