-- Durée de conservation annoncée dans la politique de confidentialité.
--
-- Chaque nuit :
-- - les coordonnées des commandes de plus de 12 mois sont effacées (nom,
--   téléphone, adresse) ; les montants et les articles restent, sans nom,
--   pour la comptabilité (6 ans) ;
-- - les commandes de plus de 6 ans sont supprimées ;
-- - les évènements de mesure d'usage de plus de 13 mois sont supprimés.
--
-- Appliqué le 2026-10-14 avec l'accord de Yanis (tâche pg_cron active).

create extension if not exists pg_cron;

create or replace function private.apply_retention()
returns void
language sql
security definer
set search_path = ''
as $$
  update public.orders
  set name = 'Client effacé',
      phone = '0000000',
      address = null
  where created_at < now() - interval '12 months'
    and name <> 'Client effacé';

  delete from public.orders
  where created_at < now() - interval '6 years';

  delete from public.usage_events
  where created_at < now() - interval '13 months';
$$;

-- 8 h UTC = 3 h ou 4 h du matin à Ottawa.
select cron.schedule('retention-nocturne', '0 8 * * *', 'select private.apply_retention()');
