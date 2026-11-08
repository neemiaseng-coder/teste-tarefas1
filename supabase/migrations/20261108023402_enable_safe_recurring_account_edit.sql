create function public.set_finance_recurrence(p_entry_id uuid,p_mode text,p_interval integer,p_description text,p_amount numeric,p_entry_type text,p_category_id uuid,p_due_date date,p_notes text default '',p_expected_updated_at timestamptz default null) returns jsonb language plpgsql security invoker set search_path='' as $$
declare v public.financial_entries%rowtype;s uuid;ids uuid[];n integer;i integer;d date;added integer:=0;
begin
 if auth.uid() is null or not private.is_finance_member() then raise exception 'Acesso não autorizado.';end if;
 select * into v from public.financial_entries where id=p_entry_id;
 if not found then raise exception 'Conta não encontrada.';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(coalesce(v.series_id,v.id)::text,0));
 perform id from public.financial_entries where id=p_entry_id or (v.series_id is not null and series_id=v.series_id) order by id for update;
 select * into v from public.financial_entries where id=p_entry_id;
 if v.status<>'pending' then raise exception 'Uma conta paga não pode ser alterada.';end if;
 if v.recurrence_type='installments' then raise exception 'Use a edição de parcelas para este lançamento.';end if;
 if p_expected_updated_at is not null and v.updated_at is distinct from p_expected_updated_at then raise exception 'A conta mudou em outro acesso. Reabra a edição.';end if;
 if p_mode is null or p_mode not in ('once','monthly') or p_interval is null or p_interval<1 or p_interval>120 or p_description is null or length(trim(p_description))=0 or p_amount is null or p_amount<=0 or p_due_date is null then raise exception 'Confira os dados e o intervalo da recorrência.';end if;
 if p_mode='once' then
 update public.financial_entries set description=trim(p_description),amount=p_amount,entry_type=p_entry_type,category_id=p_category_id,due_date=p_due_date,month_ref=pg_catalog.date_trunc('month',p_due_date)::date,notes=coalesce(p_notes,''),recurrence_type='once',series_id=null,recurrence_interval_months=1 where id=p_entry_id;
 return pg_catalog.jsonb_build_object('updated',1,'added',0);end if;
 s:=coalesce(v.series_id,gen_random_uuid());
 select pg_catalog.array_agg(id order by due_date,id) into ids from public.financial_entries where status='pending' and (id=p_entry_id or (v.series_id is not null and series_id=v.series_id and due_date>=v.due_date));
 n:=greatest(coalesce(pg_catalog.array_length(ids,1),0),ceil(24.0/p_interval)::integer);
 for i in 1..n loop
 d:=(p_due_date+pg_catalog.make_interval(months=>(i-1)*p_interval))::date;
 if exists(select 1 from public.financial_entries where series_id=s and status='paid' and due_date=d) then raise exception 'O novo calendário coincide com uma conta já paga. Escolha outro vencimento.';end if;
 if i<=coalesce(pg_catalog.array_length(ids,1),0) then
 update public.financial_entries set description=trim(p_description),amount=p_amount,entry_type=p_entry_type,category_id=p_category_id,due_date=d,month_ref=pg_catalog.date_trunc('month',d)::date,notes=coalesce(p_notes,''),recurrence_type='monthly',series_id=s,recurrence_interval_months=p_interval where id=ids[i];
 else
 insert into public.financial_entries(description,amount,entry_type,category_id,due_date,month_ref,status,notes,recurrence_type,series_id,recurrence_interval_months,created_by)
 values(trim(p_description),p_amount,p_entry_type,p_category_id,d,pg_catalog.date_trunc('month',d)::date,'pending',coalesce(p_notes,''),'monthly',s,p_interval,auth.uid());added:=added+1;
 end if;end loop;
 return pg_catalog.jsonb_build_object('updated',coalesce(pg_catalog.array_length(ids,1),0),'added',added,'series_id',s);
end;$$;
revoke all on function public.set_finance_recurrence(uuid,text,integer,text,numeric,text,uuid,date,text,timestamptz) from public,anon;
grant execute on function public.set_finance_recurrence(uuid,text,integer,text,numeric,text,uuid,date,text,timestamptz) to authenticated;