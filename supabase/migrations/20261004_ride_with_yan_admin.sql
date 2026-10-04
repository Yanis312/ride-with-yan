-- Ride with Yan : réglages modifiables depuis le panneau d'administration.
-- (Copie du schéma appliqué au projet Supabase, pour référence.)

-- Seul le compte de Yanis, une fois son courriel confirmé, peut écrire.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users u
    where u.id = (select auth.uid())
      and u.email = 'yanisgaroui1@gmail.com'
      and u.email_confirmed_at is not null
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- Prix, stock et visibilité d'un article ; le reste (photos, textes) est dans l'app.
create table public.product_overrides (
  id text primary key check (char_length(id) <= 80),
  price numeric check (price >= 0),
  sizes jsonb,
  stock integer check (stock >= 0),
  hidden boolean not null default false,
  updated_at timestamptz not null default now()
);

create table public.settings (
  key text primary key check (char_length(key) <= 80),
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- Compteurs anonymes de la question du jour.
create table public.poll_votes (
  question_id text not null check (char_length(question_id) <= 40),
  option_id text not null check (char_length(option_id) <= 40),
  votes integer not null default 0 check (votes >= 0),
  primary key (question_id, option_id)
);

alter table public.product_overrides enable row level security;
alter table public.settings enable row level security;
alter table public.poll_votes enable row level security;

create policy "lecture publique" on public.product_overrides
  for select to anon, authenticated using (true);
create policy "admin ajoute" on public.product_overrides
  for insert to authenticated with check ((select public.is_admin()));
create policy "admin modifie" on public.product_overrides
  for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin supprime" on public.product_overrides
  for delete to authenticated using ((select public.is_admin()));

create policy "lecture publique" on public.settings
  for select to anon, authenticated using (true);
create policy "admin ajoute" on public.settings
  for insert to authenticated with check ((select public.is_admin()));
create policy "admin modifie" on public.settings
  for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy "admin supprime" on public.settings
  for delete to authenticated using ((select public.is_admin()));

create policy "lecture publique" on public.poll_votes
  for select to anon, authenticated using (true);
create policy "admin supprime" on public.poll_votes
  for delete to authenticated using ((select public.is_admin()));

-- La tablette ajoute un vote par cet appel uniquement (pas d'écriture directe).
create or replace function public.cast_vote(question text, choice text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if question !~ '^[a-z0-9_-]{1,40}$' or choice !~ '^[a-z0-9_-]{1,40}$' then
    raise exception 'vote invalide';
  end if;
  insert into public.poll_votes (question_id, option_id, votes)
  values (question, choice, 1)
  on conflict (question_id, option_id)
  do update set votes = public.poll_votes.votes + 1;
end;
$$;

revoke all on function public.cast_vote(text, text) from public;
grant execute on function public.cast_vote(text, text) to anon, authenticated;
