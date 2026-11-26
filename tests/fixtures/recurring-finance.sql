begin;set local role authenticated;select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
insert into public.financial_entries(description,amount,entry_type,due_date,month_ref,status,paid_at,recurrence_type,recurrence_interval_months,series_id,created_by)
select 'Recorrente teste',100,'expense',('2026-11-25'::date+make_interval(months=>n*4))::date,date_trunc('month','2026-11-25'::date+make_interval(months=>n*4))::date,case when n=2 then 'paid' else 'pending' end,case when n=2 then now() else null end,'monthly',4,'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',auth.uid() from generate_series(0,3)n;
do $$declare v uuid;begin
 select id into v from public.financial_entries where series_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' and due_date='2027-03-25';
 perform public.edit_finance_entry(v,'single','Recorrente teste',125,'expense',null,'2027-03-26');
 if (select amount from public.financial_entries where series_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' and due_date='2027-11-25')<>100 then raise exception 'FAIL recurring single';end if;
 perform public.edit_finance_entry(v,'future','Recorrente teste',150,'expense',null,'2027-03-26',p_interval=>4);
 if not exists(select 1 from public.financial_entries where series_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' and due_date='2027-11-26' and amount=150) then raise exception 'FAIL recurring offset';end if;
 if (select amount from public.financial_entries where series_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' and due_date='2026-11-25')<>100 then raise exception 'FAIL earlier recurring';end if;
 if (select amount from public.financial_entries where series_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' and status='paid')<>100 then raise exception 'FAIL paid recurring';end if;
 begin perform public.edit_finance_entry(v,'single','INVALID',9,'expense',null,'2027-03-26',p_expected_updated_at=>'2000-01-01');raise exception 'FAIL stale guard';exception when others then if sqlerrm not like 'Este lançamento mudou%' then raise;end if;end;
 if (select count(*) from public.financial_entries where series_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb')<>4 then raise exception 'FAIL recurring duplicated';end if;
end $$;
select 'PASS: recurring single/future, four-month spacing, prior/paid preserved and stale guard' as verification;rollback;
