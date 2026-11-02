-- Restringe funções internas e remove RPCs SECURITY DEFINER do schema exposto.
REVOKE EXECUTE ON FUNCTION public.current_app_role() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_task_member(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_team_member(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_team_leader(uuid) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.enforce_task_update_permissions() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.track_task_changes() FROM PUBLIC, anon, authenticated;

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon;
GRANT USAGE ON SCHEMA private TO authenticated;

ALTER FUNCTION public.current_app_role() SET SCHEMA private;
ALTER FUNCTION public.is_task_member(uuid) SET SCHEMA private;
ALTER FUNCTION public.is_team_member(uuid) SET SCHEMA private;
ALTER FUNCTION public.is_team_leader(uuid) SET SCHEMA private;

REVOKE EXECUTE ON FUNCTION private.current_app_role() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION private.is_task_member(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION private.is_team_member(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION private.is_team_leader(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.current_app_role() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_task_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_team_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_team_leader(uuid) TO authenticated;
