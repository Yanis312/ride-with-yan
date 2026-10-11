-- Question du jour : seuls les votes pour une vraie question et une vraie
-- réponse sont comptés. Avant, n'importe quel identifiant bien formé était
-- accepté : un inconnu pouvait remplir la table de lignes inventées.
--
-- La liste doit rester identique à `pollQuestions` (app/lib/data/poll.dart) ;
-- un test de l'app (test/poll_allow_list_test.dart) le vérifie.

create or replace function public.cast_vote(question text, choice text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  allowed constant jsonb := '{
    "ville": ["montreal", "paris", "tokyo", "barcelone", "londres", "amsterdam"],
    "saison": ["hiver", "printemps", "ete", "automne"],
    "plat": ["poutine", "smoked", "bagel"],
    "soiree": ["resto", "match", "concert", "maison"],
    "musique": ["rock", "pop", "rap", "silence"]
  }';
begin
  if question is null or choice is null
     or not coalesce(allowed -> question, '[]'::jsonb) ? choice then
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
