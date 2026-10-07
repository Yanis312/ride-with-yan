-- Commandes de la boutique, avec alerte sur le téléphone de Yanis.
-- (Copie du schéma appliqué au projet Supabase, pour référence.)
--
-- Le nom du canal de notification n'est PAS dans ce fichier : il est dans
-- la table private.app_secrets (clé 'ntfy_topic'), qui n'est pas exposée
-- par l'API. Quiconque connaît ce nom peut lire les alertes.

create extension if not exists pg_net;

create schema if not exists private;
revoke all on schema private from anon, authenticated;

create table if not exists private.app_secrets (
  key text primary key,
  value text not null
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  reference text not null check (reference ~ '^RWY-[0-9]{4}$'),
  created_at timestamptz not null default now(),
  name text not null check (char_length(btrim(name)) between 1 and 80),
  phone text not null check (phone ~ '^[0-9+() .-]{7,24}$'),
  address text check (address is null or char_length(address) <= 300),
  language text not null default 'fr' check (language in ('fr', 'en')),
  -- [{id, name, size, qty, price, on_order}]
  lines jsonb not null check (
    jsonb_typeof(lines) = 'array'
    and jsonb_array_length(lines) between 1 and 30
    and pg_column_size(lines) < 8000
  ),
  pay_now numeric not null check (pay_now between 0 and 10000),
  pay_later numeric not null check (pay_later between 0 and 10000),
  transfer_claimed boolean not null default false,
  status text not null default 'new'
    check (status in ('new', 'paid', 'delivered', 'cancelled'))
);

create index orders_created_at_idx on public.orders (created_at desc);

alter table public.orders enable row level security;

-- La tablette peut seulement déposer une commande neuve ; elle ne peut ni
-- relire ni modifier les commandes (données personnelles des clients).
create policy "depot d'une commande" on public.orders
  for insert to anon, authenticated
  with check (status = 'new' and transfer_claimed = false);

create policy "admin lit" on public.orders
  for select to authenticated using ((select public.is_admin()));
create policy "admin modifie" on public.orders
  for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin supprime" on public.orders
  for delete to authenticated using ((select public.is_admin()));

-- Le client touche « Virement envoyé » : on le note, sans rien pouvoir
-- changer d'autre. L'identifiant de commande (aléatoire) fait office de clé.
create or replace function public.claim_transfer(order_id uuid, order_reference text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.orders
  set transfer_claimed = true
  where id = order_id
    and reference = order_reference
    and status = 'new'
    and created_at > now() - interval '2 hours';
$$;

revoke all on function public.claim_transfer(uuid, text) from public;
grant execute on function public.claim_transfer(uuid, text) to anon, authenticated;

-- Montants sans décimales inutiles ("2 $" et non "2.0 $").
create or replace function private.money(amount numeric)
returns text
language sql
immutable
set search_path = ''
as $$
  select case when amount = trunc(amount)
    then trunc(amount)::text
    else to_char(amount, 'FM999990.00')
  end || ' $';
$$;

-- Alerte à chaque nouvelle commande. Elle ne contient ni téléphone ni
-- adresse : ces données restent dans la base, visibles dans l'administration.
create or replace function private.notify_new_order()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  topic text;
  recent integer;
  items text;
  body text;
begin
  select value into topic from private.app_secrets where key = 'ntfy_topic';
  if topic is null then
    return new;
  end if;

  -- Garde-fou : pas plus de 30 alertes par heure, même en cas d'abus.
  select count(*) into recent
  from public.orders
  where created_at > now() - interval '1 hour';
  if recent > 30 then
    return new;
  end if;

  select string_agg(
    (l ->> 'qty') || ' x ' || left(l ->> 'name', 40)
      || coalesce(' ' || nullif(l ->> 'size', ''), '')
      || case when (l ->> 'on_order')::boolean then ' (sur commande)' else '' end,
    E'\n'
  )
  into items
  from jsonb_array_elements(new.lines) as l;

  body := left(new.name, 40) || E'\n' || coalesce(items, '')
    || E'\nA payer maintenant : ' || private.money(new.pay_now)
    || case when new.pay_later > 0
         then E'\nA la livraison : ' || private.money(new.pay_later) else '' end;

  perform net.http_post(
    url := 'https://ntfy.sh',
    body := jsonb_build_object(
      'topic', topic,
      'title', 'Nouvelle commande ' || new.reference,
      'message', body,
      'priority', 4,
      'tags', jsonb_build_array('shopping_bags'),
      'click', 'https://yanis312.github.io/ride-with-yan/?admin'
    ),
    headers := jsonb_build_object('Content-Type', 'application/json')
  );
  return new;
exception when others then
  -- Une alerte qui échoue ne doit jamais empêcher d'enregistrer la commande.
  return new;
end;
$$;

create trigger orders_notify
  after insert on public.orders
  for each row execute function private.notify_new_order();
