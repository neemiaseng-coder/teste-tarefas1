create function public.edit_finance_entry(p_entry_id uuid,p_scope text,p_description text,p_amount numeric,p_entry_type text,p_category_id uuid,p_due_date date,p_notes text default '',p_expected_updated_at timestamptz default null,p_recurrence text default null,p_interval integer default null,p_total integer default null) returns jsonb language plpgsql security invoker set search_path='' as $$
declare v public.financial_entries%rowtype; r public.financial_entries%rowtype;mode text;step integer;total integer;s uuid;d date;offset_months integer;affected integer:=0;added integer:=0;n integer;
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
 mode:=coalesce(p_recurrence,v.recurrence_type);step:=case when mode='monthly' then coalesce(p_interval,v.recurrence_interval_months) else 1 end;total:=coalesce(p_total,v.installment_total);s:=v.series_id;
 if mode is null or mode not in ('once','monthly','installments') or step not between 1 and 120 then raise exception 'Repetição inválida.';end if;
 if (v.recurrence_type='installments') is distinct from (mode='installments') then raise exception 'Preserve o tipo deste parcelamento.';end if;
 if v.series_id is not null and p_scope='single' and (mode is distinct from v.recurrence_type or step is distinct from v.recurrence_interval_months or total is distinct from v.installment_total) then raise exception 'Para alterar a regra da série, escolha Esta e todas as próximas.';end if;
 if mode='installments' then
  if total is null or total<2 or total>120 or total<v.installment_number then raise exception 'Quantidade de parcelas inválida.';end if;
  if total is distinct from v.installment_total then
   if p_scope<>'future' then raise exception 'Altere a quantidade em Esta e todas as próximas.';end if;
   if exists(select 1 from public.financial_entries where series_id=s and status='paid') then raise exception 'Preserve o total da série que já possui pagamentos.';end if;
   if exists(select 1 from public.financial_entries where series_id=s and installment_number>total) then raise exception 'O novo total não pode excluir parcelas existentes.';end if;
  end if;
 end if;
 if mode='monthly' and s is null then s:=gen_random_uuid();end if;
 for r in select * from public.financial_entries e where e.status='pending' and (e.id=p_entry_id or (p_scope='future' and v.series_id is not null and e.series_id=v.series_id and case when v.recurrence_type='installments' then e.installment_number>=v.installment_number else e.due_date>=v.due_date end)) order by e.id loop
  offset_months:=case when r.id=p_entry_id then 0 when mode='installments' then r.installment_number-v.installment_number else ((extract(year from r.due_date)::integer-extract(year from v.due_date)::integer)*12+extract(month from r.due_date)::integer-extract(month from v.due_date)::integer) end;
  if mode='monthly' and v.recurrence_type='monthly' and step<>v.recurrence_interval_months then
   if offset_months%v.recurrence_interval_months<>0 then raise exception 'A série tem datas personalizadas. Preserve o intervalo ou ajuste somente esta cobrança.';end if;
   offset_months:=(offset_months/v.recurrence_interval_months)*step;
  end if;
  d:=(p_due_date+pg_catalog.make_interval(months=>offset_months))::date;
  update public.financial_entries set description=btrim(p_description)||case when mode='installments' then ' ('||r.installment_number||'/'||case when total is distinct from v.installment_total then total else r.installment_total end||')' else '' end,amount=p_amount,entry_type=p_entry_type,category_id=p_category_id,due_date=d,month_ref=pg_catalog.date_trunc('month',d)::date,notes=coalesce(p_notes,''),recurrence_type=mode,recurrence_interval_months=step,series_id=case when mode='once' then null else s end,installment_total=case when mode='installments' then case when total is distinct from v.installment_total then total else r.installment_total end else null end,installment_number=case when mode='installments' then r.installment_number else null end where id=r.id;
  affected:=affected+1;
 end loop;
 -- Only explicit expansion creates new numbers; deleted/missing earlier slots stay absent.
 if mode='installments' and total>v.installment_total then
  for n in (v.installment_total+1)..total loop
   if not exists(select 1 from public.financial_entries where series_id=s and installment_number=n) then
    d:=(p_due_date+pg_catalog.make_interval(months=>n-v.installment_number))::date;
    insert into public.financial_entries(description,amount,entry_type,category_id,due_date,month_ref,status,recurrence_type,series_id,installment_number,installment_total,created_by,notes) values(btrim(p_description)||' ('||n||'/'||total||')',p_amount,p_entry_type,p_category_id,d,pg_catalog.date_trunc('month',d)::date,'pending','installments',s,n,total,auth.uid(),coalesce(p_notes,''));added:=added+1;
   end if;
  end loop;
 elsif v.recurrence_type='once' and mode='monthly' then
  for n in 1..(ceil(24.0/step)::integer-1) loop
   d:=(p_due_date+pg_catalog.make_interval(months=>n*step))::date;
   insert into public.financial_entries(description,amount,entry_type,category_id,due_date,month_ref,status,recurrence_type,recurrence_interval_months,series_id,created_by,notes) values(btrim(p_description),p_amount,p_entry_type,p_category_id,d,pg_catalog.date_trunc('month',d)::date,'pending','monthly',step,s,auth.uid(),coalesce(p_notes,''));added:=added+1;
  end loop;
 end if;
 return pg_catalog.jsonb_build_object('updated',affected,'added',added);
end;$$;
revoke all on function public.edit_finance_entry(uuid,text,text,numeric,text,uuid,date,text,timestamptz,text,integer,integer) from public,anon;
grant execute on function public.edit_finance_entry(uuid,text,text,numeric,text,uuid,date,text,timestamptz,text,integer,integer) to authenticated;

