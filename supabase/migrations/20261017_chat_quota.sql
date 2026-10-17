-- Assistant de bord : plafonds de questions, pour garder la facture d'IA
-- sous contrôle même si quelqu'un abuse de la tablette ou de l'API.
--
-- Rien du contenu des conversations n'est enregistré : seulement un compteur
-- par passager (numéro tiré au hasard) et un compteur par jour.

create table private.chat_quota (
  session_id uuid not null,
  day date not null default (now() at time zone 'America/Toronto')::date,
  questions integer not null default 0,
  primary key (session_id, day)
);

-- Réserve une question : faux si le passager ou la journée a atteint son
-- plafond. Appelée seulement par la fonction Edge (clé de service).
create or replace function public.chat_take_quota(
  session uuid,
  per_session integer default 20,
  per_day integer default 400
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  today date := (now() at time zone 'America/Toronto')::date;
  used_today integer;
  used_session integer;
begin
  select coalesce(sum(questions), 0) into used_today
  from private.chat_quota where day = today;
  if used_today >= per_day then
    return false;
  end if;

  insert into private.chat_quota (session_id, day, questions)
  values (session, today, 1)
  on conflict (session_id, day)
  do update set questions = private.chat_quota.questions + 1
  returning questions into used_session;

  if used_session > per_session then
    return false;
  end if;
  return true;
end;
$$;

revoke all on function public.chat_take_quota(uuid, integer, integer) from public, anon, authenticated;
grant execute on function public.chat_take_quota(uuid, integer, integer) to service_role;

-- Les compteurs de plus de 30 jours ne servent plus.
create or replace function private.purge_chat_quota()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from private.chat_quota where day < current_date - 30;
$$;

select cron.schedule('purge-chat-quota', '15 8 * * *', 'select private.purge_chat_quota()');
