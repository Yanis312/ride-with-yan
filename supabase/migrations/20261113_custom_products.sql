-- Articles ajoutés depuis le panneau d'administration, avec leurs photos.
-- Visibles par tous (tablette et boutique sur téléphone), modifiables par
-- l'administrateur seulement.

create table public.custom_products (
  id text primary key check (id ~ '^[a-z0-9-]{3,60}$'),
  name_fr text not null check (length(name_fr) between 1 and 80),
  name_en text not null check (length(name_en) between 1 and 80),
  description_fr text not null default '' check (length(description_fr) <= 400),
  description_en text not null default '' check (length(description_en) <= 400),
  price numeric(8, 2) not null check (price >= 0 and price < 100000),
  category text not null check (
    category in ('airForce1', 'dunk', 'vans', 'northFace', 'bags', 'other')
  ),
  shoppers text[] not null default '{men,women}'
    check (shoppers <@ array['men', 'women'] and cardinality(shoppers) > 0),
  sizes text[] not null default '{}' check (cardinality(sizes) <= 20),
  photos text[] not null default '{}' check (cardinality(photos) <= 8),
  created_at timestamptz not null default now()
);

alter table public.custom_products enable row level security;

create policy "lecture publique" on public.custom_products
  for select to anon, authenticated using (true);
create policy "admin ajoute" on public.custom_products
  for insert to authenticated with check ((select public.is_admin()));
create policy "admin modifie" on public.custom_products
  for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin supprime" on public.custom_products
  for delete to authenticated using ((select public.is_admin()));

-- Photos des articles : lecture publique, envoi par l'administrateur.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'product-photos', 'product-photos', true, 5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy "admin envoie des photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'product-photos' and (select public.is_admin()));
create policy "admin supprime des photos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'product-photos' and (select public.is_admin()));
