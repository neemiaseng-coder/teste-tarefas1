create table public.finance_installment_history_links(entry_id uuid primary key references public.financial_entries(id) on delete cascade,series_id uuid not null,installment_number integer not null check(installment_number>0),created_at timestamptz not null default now());
create index finance_installment_history_links_series_idx on public.finance_installment_history_links(series_id);
alter table public.finance_installment_history_links enable row level security;
create policy "finance members read installment history links" on public.finance_installment_history_links for select to authenticated using(private.is_finance_member());
revoke all on public.finance_installment_history_links from anon,authenticated;
grant select on public.finance_installment_history_links to authenticated;
create function private.finance_history_title(value text) returns text language sql immutable security invoker set search_path='' as $$select regexp_replace(btrim(regexp_replace(translate(lower(regexp_replace(coalesce(value,''),'\s*\([0-9]+/[0-9]+\)\s*$','','g')),'áàâãäéèêëíìîïóòôõöúùûüç','aaaaaeeeeiiiiooooouuuuc'),'[^a-z0-9]+',' ','g')),'\mnubanck\M','nubank','g')$$;
revoke all on function private.finance_history_title(text) from public,anon,authenticated;
-- Preserve only unambiguous, compatible imported paid history; no financial row is changed.
with grouped as (
 select series_id,max(installment_total) total,count(distinct(extract(year from due_date)::int*12+extract(month from due_date)::int-1-installment_number)) offsets
 from public.financial_entries where recurrence_type='installments' group by series_id
),anchors as(
 select distinct on(e.series_id) e.*,g.total,g.offsets from public.financial_entries e join grouped g using(series_id) where e.recurrence_type='installments' order by e.series_id,e.due_date,e.id
),candidates as(
 select h.id entry_id,a.series_id, a.installment_number+(extract(year from h.due_date)::int-extract(year from a.due_date)::int)*12+extract(month from h.due_date)::int-extract(month from a.due_date)::int as number
 from anchors a join public.financial_entries h on h.recurrence_type<>'installments' and h.status='paid' and h.notes like '%IMPORT_GRANNA_2026_FEV_OUT_V1%' and h.entry_type=a.entry_type and h.due_date<a.due_date and h.amount=a.amount and h.amount>0.01 and extract(day from h.due_date)=extract(day from a.due_date) and private.finance_history_title(h.description)=private.finance_history_title(a.description) where a.offsets=1
),eligible as(
 select c.* from candidates c join grouped g using(series_id) where c.number between 1 and g.total and not exists(select 1 from public.financial_entries e where e.series_id=c.series_id and e.installment_number=c.number)
),unique_matches as(
 select *,count(*) over(partition by entry_id) entry_matches,count(*) over(partition by series_id,number) slot_matches from eligible
)
insert into public.finance_installment_history_links(entry_id,series_id,installment_number) select entry_id,series_id,number from unique_matches where entry_matches=1 and slot_matches=1;
alter publication supabase_realtime add table public.finance_installment_history_links;
