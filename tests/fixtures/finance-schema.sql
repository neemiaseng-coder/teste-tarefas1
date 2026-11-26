create role authenticated;create role anon;create schema auth;create schema private;
create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create table auth.users(id uuid primary key);insert into auth.users values('11111111-1111-4111-8111-111111111111'),('22222222-2222-4222-8222-222222222222');
create table public.finance_members(user_id uuid primary key references auth.users);insert into public.finance_members select id from auth.users;
create function private.is_finance_member() returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.finance_members where user_id=auth.uid())$$;
create table public.finance_categories(id uuid primary key);create table public.financial_plans(id uuid primary key);
create table public.financial_entries(id uuid primary key default gen_random_uuid(),description text not null check(char_length(trim(description)) between 1 and 180),amount numeric(14,2) not null check(amount>0),entry_type text not null default 'expense' check(entry_type in('expense','income','reserve')),category_id uuid references public.finance_categories(id) on delete restrict,due_date date not null,month_ref date not null,status text not null default 'pending' check(status in('pending','paid')),paid_at timestamptz,paid_by uuid references auth.users(id),recurrence_type text not null default 'once' check(recurrence_type in('once','monthly','installments')),series_id uuid,installment_number integer,installment_total integer,plan_id uuid references public.financial_plans(id) on delete set null,notes text not null default '',created_by uuid not null references auth.users(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now(),check(date_trunc('month',month_ref)::date=month_ref),check((recurrence_type='installments' and series_id is not null and installment_number between 1 and installment_total and installment_total>=2) or (recurrence_type<>'installments' and installment_number is null and installment_total is null)),check((status='paid' and paid_at is not null) or status='pending'));
alter table public.financial_entries add column recurrence_interval_months integer not null default 1 check(recurrence_interval_months between 1 and 120);
create or replace function private.protect_paid_financial_entry() returns trigger language plpgsql set search_path='' as $$
begin
 if old.status='paid' and (new.description,new.amount,new.entry_type,new.category_id,new.due_date,new.month_ref,new.recurrence_type,new.series_id,new.installment_number,new.installment_total,new.plan_id,new.notes) is distinct from (old.description,old.amount,old.entry_type,old.category_id,old.due_date,old.month_ref,old.recurrence_type,old.series_id,old.installment_number,old.installment_total,old.plan_id,old.notes) then raise exception 'Para alterar uma conta paga, desfaça o pagamento primeiro.'; end if;
 if new.status='paid' and old.status<>'paid' then new.paid_at:=coalesce(new.paid_at,now());new.paid_by:=coalesce(new.paid_by,(select auth.uid())); elsif new.status='pending' then new.paid_at:=null;new.paid_by:=null; end if;
 new.updated_at:=now();return new;
end;$$;
create trigger financial_entries_protect_paid before update on public.financial_entries for each row execute function private.protect_paid_financial_entry();
grant usage on schema public,private,auth to authenticated,anon;
grant select,insert,update,delete on public.financial_entries to authenticated;
alter table public.financial_entries enable row level security;
create policy member_access on public.financial_entries for all to authenticated using(private.is_finance_member()) with check(private.is_finance_member());
