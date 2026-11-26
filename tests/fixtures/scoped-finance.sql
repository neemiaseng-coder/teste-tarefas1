begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
insert into public.financial_entries(description,amount,entry_type,due_date,month_ref,status,paid_at,paid_by,recurrence_type,series_id,installment_number,installment_total,created_by)
select 'TESTE SINTETICO ('||n||'/5)',100,'expense',('2026-11-10'::date+make_interval(months=>n-1))::date,date_trunc('month','2026-11-10'::date+make_interval(months=>n-1))::date,case when n in(1,4) then 'paid' else 'pending' end,case when n in(1,4) then now() else null end,case when n in(1,4) then auth.uid() else null end,'installments','0c105c49-432b-4cb3-871b-59cb6a72484e',n,5,auth.uid() from generate_series(1,5) n;
do $$declare v uuid;oldstamp timestamptz;begin
 select id,updated_at into v,oldstamp from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e' and installment_number=3;
 perform public.edit_finance_entry(v,'single','TESTE SINTETICO',150,'expense',null,'2027-01-10');
 if (select amount from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e' and installment_number=5)<>100 then raise exception 'FAIL single scope';end if;
 perform public.edit_finance_entry(v,'future','TESTE SINTETICO',200,'expense',null,'2027-02-15');
 if exists(select 1 from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e' and installment_number in(1,2,4) and amount<>100) then raise exception 'FAIL earlier or paid changed';end if;
 if (select due_date from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e' and installment_number=5)<>'2027-04-15'::date then raise exception 'FAIL date offset';end if;
 if (select sum(amount) from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e' and status='pending')<>500 then raise exception 'FAIL pending sum';end if;
 begin perform public.edit_finance_entry(v,'future','INVALID',300,'expense','ffffffff-ffff-ffff-ffff-ffffffffffff','2027-02-15');raise exception 'FAIL expected FK rejection';exception when foreign_key_violation then null;end;
 if (select sum(amount) from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e' and status='pending')<>500 then raise exception 'FAIL rollback';end if;
end $$;
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
delete from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e' and installment_number=5 and status='pending';
do $$declare v uuid;paid_id uuid;begin
 select id into v from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e' and installment_number=3;
 perform public.edit_finance_entry(v,'future','TESTE SINTETICO',200,'expense',null,'2027-02-15');
 if (select count(*) from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e')<>4 then raise exception 'FAIL deleted installment resurrected';end if;
 update public.financial_entries set status='paid',paid_at=now(),paid_by=auth.uid() where id=v;
 if (select sum(amount) from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e' and status='pending')<>100 then raise exception 'FAIL payment pending';end if;
 begin perform public.edit_finance_entry(v,'single','INVALID',200,'expense',null,'2027-02-15');raise exception 'FAIL paid edit accepted';exception when others then if sqlerrm not like 'Desfaça o pagamento%' then raise;end if;end;
 begin delete from public.financial_entries where id=v;raise exception 'FAIL paid deletion accepted';exception when others then if sqlerrm not like 'Desfaça o pagamento%' then raise;end if;end;
 update public.financial_entries set status='pending',paid_at=null,paid_by=null where id=v;
 if (select sum(amount) from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e' and status='pending')<>300 then raise exception 'FAIL undo pending';end if;
 if (select sum(amount) from public.financial_entries where series_id='0c105c49-432b-4cb3-871b-59cb6a72484e')<>500 then raise exception 'FAIL updated total';end if;
end $$;
select 'PASS: single, future, earlier pending, paid preserved, date offsets, failed transaction rollback, deletion, no resurrection, payment, undo, cross-user RLS' as verification;
rollback;
