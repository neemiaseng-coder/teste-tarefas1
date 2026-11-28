-- Additive: lets members change an account's repetition type and installment numbering.
-- Paid rows are never updated or deleted. No existing financial row is changed by this migration.
create function public.convert_finance_entry(p_entry_id uuid,p_scope text,p_description text,p_amount numeric,p_entry_type text,p_category_id uuid,p_due_date date,p_notes text,p_expected_updated_at timestamptz,p_recurrence text,p_interval integer default 1,p_number integer default null,p_total integer default null) returns jsonb language plpgsql security invoker set search_path='' as $$
declare v public.financial_entries%rowtype;step integer;num integer;total integer;s uuid;d date;same boolean;affected integer:=0;added integer:=0;removed integer:=0;n integer;
begin
 if auth.uid() is null or not private.is_finance_member() then raise exception 'Acesso não autorizado.';end if;
 if p_scope is null or p_scope not in ('single','future') then raise exception 'Escolha Somente esta ou Esta e todas as próximas.';end if;
 select * into v from public.financial_entries where id=p_entry_id;
 if not found then raise exception 'Lançamento não encontrado. Reabra a lista.';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(coalesce(v.series_id,v.id)::text,0));
 perform id from public.financial_entries where id=p_entry_id or (v.series_id is not null and series_id=v.series_id) order by id for update;
 select * into v from public.financial_entries where id=p_entry_id;
 if not found then raise exception 'Lançamento excluído em outro acesso.';end if;
 if v.status<>'pending' then raise exception 'Desfaça o pagamento antes de editar este lançamento.';end if;
 if p_expected_updated_at is not null and p_expected_updated_at is distinct from v.updated_at then raise exception 'Este lançamento mudou em outro acesso. Reabra a edição.';end if;
 if p_description is null or length(btrim(p_description)) not between 1 and 170 or p_amount is null or p_amount<=0 or p_amount<>round(p_amount,2) or p_due_date is null or p_entry_type is null or p_entry_type not in ('expense','income','reserve') then raise exception 'Confira descrição, valor, tipo e vencimento.';end if;
 if p_recurrence is null or p_recurrence not in ('once','monthly','installments') then raise exception 'Repetição inválida.';end if;
 step:=case when p_recurrence='monthly' then coalesce(p_interval,1) else 1 end;
 if step not between 1 and 120 then raise exception 'Informe um intervalo de 1 a 120 meses.';end if;
 same:=v.recurrence_type=p_recurrence;
 if same and p_recurrence<>'installments' then raise exception 'Use a edição comum para esta alteração.';end if;
 if p_recurrence='installments' then
  num:=coalesce(p_number,v.installment_number,1);total:=coalesce(p_total,v.installment_total);
  if total is null or total not between 2 and 120 then raise exception 'Informe de 2 a 120 parcelas.';end if;
  if num not between 1 and total then raise exception 'A parcela atual deve estar entre 1 e o total de parcelas.';end if;
 end if;

 if same then
  s:=v.series_id;
  if total<>v.installment_total and p_scope<>'future' then raise exception 'Altere a quantidade em Esta e todas as próximas.';end if;
  if p_scope='future' then
   delete from public.financial_entries where series_id=s and id<>v.id and status='pending' and installment_number>v.installment_number;
   get diagnostics removed=row_count;
   if exists(select 1 from public.financial_entries where series_id=s and id<>v.id and installment_number>total)
    or exists(select 1 from public.finance_installment_history_links where series_id=s and installment_number>total)
   then raise exception 'Há parcelas pagas ou anteriores acima do novo total. Informe um total maior.';end if;
  end if;
  if exists(select 1 from public.financial_entries where series_id=s and id<>v.id and installment_number=num)
   or exists(select 1 from public.finance_installment_history_links where series_id=s and installment_number=num)
  then raise exception 'Já existe a parcela % neste parcelamento.',num;end if;
 else
  if v.series_id is not null and p_scope='future' then
   if p_recurrence<>'once' and exists(select 1 from public.financial_entries e where e.series_id=v.series_id and e.status='paid' and case when v.recurrence_type='installments' then e.installment_number>v.installment_number else e.due_date>v.due_date end)
   then raise exception 'Há contas seguintes já pagas. Desfaça esses pagamentos ou escolha Somente esta.';end if;
   delete from public.financial_entries e where e.series_id=v.series_id and e.id<>v.id and e.status='pending' and case when v.recurrence_type='installments' then e.installment_number>v.installment_number else e.due_date>v.due_date end;
   get diagnostics removed=row_count;
  end if;
  s:=case when p_recurrence='once' then null else gen_random_uuid() end;
 end if;

 update public.financial_entries set description=btrim(p_description)||case when p_recurrence='installments' then ' ('||num||'/'||total||')' else '' end,amount=p_amount,entry_type=p_entry_type,category_id=p_category_id,due_date=p_due_date,month_ref=pg_catalog.date_trunc('month',p_due_date)::date,notes=coalesce(p_notes,''),recurrence_type=p_recurrence,recurrence_interval_months=step,series_id=s,installment_number=case when p_recurrence='installments' then num end,installment_total=case when p_recurrence='installments' then total end where id=v.id;
 affected:=1;

 if p_recurrence='installments' then
  if same and p_scope='future' and total<>v.installment_total then
   update public.financial_entries set installment_total=total,description=pg_catalog.regexp_replace(description,'\s*\([0-9]+/[0-9]+\)\s*$','')||' ('||installment_number||'/'||total||')' where series_id=s and id<>v.id and status='pending';
  end if;
  if not same or p_scope='future' then
   for n in (num+1)..total loop
    if not exists(select 1 from public.financial_entries where series_id=s and installment_number=n) and not exists(select 1 from public.finance_installment_history_links where series_id=s and installment_number=n) then
     d:=(p_due_date+pg_catalog.make_interval(months=>n-num))::date;
     insert into public.financial_entries(description,amount,entry_type,category_id,due_date,month_ref,status,recurrence_type,series_id,installment_number,installment_total,created_by,notes) values(btrim(p_description)||' ('||n||'/'||total||')',p_amount,p_entry_type,p_category_id,d,pg_catalog.date_trunc('month',d)::date,'pending','installments',s,n,total,auth.uid(),coalesce(p_notes,''));added:=added+1;
    end if;
   end loop;
  end if;
 elsif p_recurrence='monthly' then
  for n in 1..(ceil(24.0/step)::integer-1) loop
   d:=(p_due_date+pg_catalog.make_interval(months=>n*step))::date;
   insert into public.financial_entries(description,amount,entry_type,category_id,due_date,month_ref,status,recurrence_type,recurrence_interval_months,series_id,created_by,notes) values(btrim(p_description),p_amount,p_entry_type,p_category_id,d,pg_catalog.date_trunc('month',d)::date,'pending','monthly',step,s,auth.uid(),coalesce(p_notes,''));added:=added+1;
  end loop;
 end if;
 return pg_catalog.jsonb_build_object('updated',affected,'added',added,'removed',removed);
end;$$;
revoke all on function public.convert_finance_entry(uuid,text,text,numeric,text,uuid,date,text,timestamptz,text,integer,integer,integer) from public,anon;
grant execute on function public.convert_finance_entry(uuid,text,text,numeric,text,uuid,date,text,timestamptz,text,integer,integer,integer) to authenticated;
