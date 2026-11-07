alter table public.financial_entries add column recurrence_interval_months integer not null default 1;
alter table public.financial_entries add constraint financial_entries_recurrence_interval_check check(recurrence_interval_months between 1 and 120 and (recurrence_type='monthly' or recurrence_interval_months=1));

create function private.protect_paid_recurrence_interval() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if old.status='paid' and new.recurrence_interval_months is distinct from old.recurrence_interval_months then raise exception 'Para alterar uma conta paga, desfaça o pagamento primeiro.';end if;
 return new;
end;
$$;
revoke all on function private.protect_paid_recurrence_interval() from public,anon,authenticated;
create trigger financial_entries_protect_paid_interval before update of recurrence_interval_months on public.financial_entries for each row execute function private.protect_paid_recurrence_interval();

create function public.edit_finance_installment_series(p_entry_id uuid,p_total integer,p_description text,p_amount numeric,p_entry_type text,p_category_id uuid,p_due_date date,p_notes text default '',p_expected_updated_at timestamptz default null) returns jsonb language plpgsql security invoker set search_path='' as $$
declare
 v_entry public.financial_entries%rowtype;
 v_updated integer;
 v_added integer;

begin
 if auth.uid() is null or not private.is_finance_member() then raise exception 'Acesso não autorizado.';end if;
 select * into v_entry from public.financial_entries where id=p_entry_id;
 if not found or v_entry.series_id is null or v_entry.recurrence_type<>'installments' then raise exception 'Parcelamento não encontrado.';end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_entry.series_id::text,0));
 perform id from public.financial_entries where series_id=v_entry.series_id order by id for update;
 select * into v_entry from public.financial_entries where id=p_entry_id;
 if v_entry.status='paid' then raise exception 'Uma parcela paga não pode ser alterada.';end if;
 if p_expected_updated_at is not null and v_entry.updated_at is distinct from p_expected_updated_at then raise exception 'A série mudou em outro acesso. Reabra a conta antes de alterar.';end if;
 if p_total is null or p_total<2 or p_total>120 or p_total<v_entry.installment_number then raise exception 'O total deve ser de 2 a 120 e não pode ser menor que a parcela atual.';end if;
 if p_description is null or length(trim(p_description))<1 or p_amount is null or p_amount<=0 or p_due_date is null then raise exception 'Informe descrição, valor e vencimento válidos.';end if;
 if p_total<>v_entry.installment_total and exists(select 1 from public.financial_entries where series_id=v_entry.series_id and status='paid') then raise exception 'A série já tem parcelas pagas. Preserve a quantidade total para manter o histórico.';end if;
 if exists(select 1 from public.financial_entries where series_id=v_entry.series_id group by installment_number having count(*)>1) then raise exception 'A série tem numeração duplicada e precisa de conferência.';end if;
 if exists(select 1 from public.financial_entries where series_id=v_entry.series_id and installment_number>p_total) then raise exception 'Existem parcelas acima desse total. Confira e exclua individualmente as excedentes antes de reduzir.';end if;
 update public.financial_entries e set description=trim(p_description)||' ('||e.installment_number||'/'||p_total||')',amount=p_amount,entry_type=p_entry_type,category_id=p_category_id,due_date=(p_due_date+pg_catalog.make_interval(months=>e.installment_number-v_entry.installment_number))::date,month_ref=pg_catalog.date_trunc('month',p_due_date+pg_catalog.make_interval(months=>e.installment_number-v_entry.installment_number))::date,notes=coalesce(p_notes,''),installment_total=p_total where e.series_id=v_entry.series_id and e.status='pending';
 get diagnostics v_updated=row_count;
 insert into public.financial_entries(description,amount,entry_type,category_id,due_date,month_ref,status,recurrence_type,series_id,installment_number,installment_total,notes,created_by,recurrence_interval_months)
 select trim(p_description)||' ('||n||'/'||p_total||')',p_amount,p_entry_type,p_category_id,(p_due_date+pg_catalog.make_interval(months=>n-v_entry.installment_number))::date,pg_catalog.date_trunc('month',p_due_date+pg_catalog.make_interval(months=>n-v_entry.installment_number))::date,'pending','installments',v_entry.series_id,n,p_total,coalesce(p_notes,''),auth.uid(),1
 from pg_catalog.generate_series(v_entry.installment_number,p_total) n where not exists(select 1 from public.financial_entries e where e.series_id=v_entry.series_id and e.installment_number=n);
 get diagnostics v_added=row_count;
 return pg_catalog.jsonb_build_object('updated',v_updated,'added',v_added,'removed',0,'series_id',v_entry.series_id);
end;
$$;
revoke all on function public.edit_finance_installment_series(uuid,integer,text,numeric,text,uuid,date,text,timestamptz) from public,anon;
grant execute on function public.edit_finance_installment_series(uuid,integer,text,numeric,text,uuid,date,text,timestamptz) to authenticated;
