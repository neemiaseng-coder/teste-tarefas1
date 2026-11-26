create unique index if not exists financial_entries_series_number_unique on public.financial_entries(series_id,installment_number) where recurrence_type='installments';

