create function private.protect_paid_financial_delete() returns trigger language plpgsql security invoker set search_path='' as $$begin if old.status='paid' then raise exception 'Desfaça o pagamento antes de excluir este lançamento.';end if;return old;end;$$;
revoke all on function private.protect_paid_financial_delete() from public,anon,authenticated;
create trigger financial_entries_protect_paid_delete before delete on public.financial_entries for each row execute function private.protect_paid_financial_delete();

