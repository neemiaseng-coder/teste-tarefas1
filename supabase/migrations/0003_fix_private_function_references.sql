create or replace function public.enforce_task_update_permissions()
returns trigger language plpgsql security definer set search_path = public, private
as $$ declare v_role public.app_role;
begin
  if auth.uid() is null then raise exception 'Autenticação obrigatória'; end if;
  v_role := private.current_app_role();
  if v_role='admin' then return new; end if;
  if v_role='manager' and old.team_id is not null and private.is_team_leader(old.team_id) then
    if new.creator_id <> old.creator_id then raise exception 'Não é permitido alterar o criador'; end if;
    return new;
  end if;
  if old.creator_id=auth.uid() then
    if new.creator_id <> old.creator_id then raise exception 'Não é permitido alterar o criador'; end if;
    return new;
  end if;
  if old.assignee_id=auth.uid() then
    if row(new.title,new.description,new.creator_id,new.assignee_id,new.team_id,new.due_at,new.priority)
       is distinct from
       row(old.title,old.description,old.creator_id,old.assignee_id,old.team_id,old.due_at,old.priority) then
      raise exception 'Responsável só pode atualizar o status da tarefa'; end if;
    return new;
  end if;
  raise exception 'Sem permissão para alterar esta tarefa';
end $$;
REVOKE EXECUTE ON FUNCTION public.enforce_task_update_permissions() FROM PUBLIC, anon, authenticated;
