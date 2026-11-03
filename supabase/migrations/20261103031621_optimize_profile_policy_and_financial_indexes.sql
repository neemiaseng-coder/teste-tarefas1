begin;
drop policy if exists "profiles read authenticated" on public.profiles;
create policy "profiles read authenticated" on public.profiles for select to authenticated
using ((active=true) or (id=(select auth.uid())) or ((select private.current_app_role())='admin'::public.app_role));
create index if not exists financial_entries_created_by_idx on public.financial_entries(created_by);
create index if not exists financial_entries_paid_by_idx on public.financial_entries(paid_by);
create index if not exists financial_plans_created_by_idx on public.financial_plans(created_by);
commit;