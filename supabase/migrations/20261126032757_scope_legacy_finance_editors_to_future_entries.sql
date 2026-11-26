-- Existing clients also get the corrected future-only atomic semantics.
create or replace function public.edit_finance_installment_series(p_entry_id uuid,p_total integer,p_description text,p_amount numeric,p_entry_type text,p_category_id uuid,p_due_date date,p_notes text default '',p_expected_updated_at timestamptz default null) returns jsonb language sql security invoker set search_path='' as $$
 select public.edit_finance_entry(p_entry_id,'future',p_description,p_amount,p_entry_type,p_category_id,p_due_date,p_notes,p_expected_updated_at,'installments',1,p_total);
$$;
create or replace function public.set_finance_recurrence(p_entry_id uuid,p_mode text,p_interval integer,p_description text,p_amount numeric,p_entry_type text,p_category_id uuid,p_due_date date,p_notes text default '',p_expected_updated_at timestamptz default null) returns jsonb language sql security invoker set search_path='' as $$
 select public.edit_finance_entry(p_entry_id,'future',p_description,p_amount,p_entry_type,p_category_id,p_due_date,p_notes,p_expected_updated_at,p_mode,p_interval,null);
$$;

