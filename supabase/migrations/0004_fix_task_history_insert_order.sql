-- Corrige o registro de histórico para ocorrer depois da gravação da tarefa.
-- O trigger anterior era BEFORE INSERT e tentava inserir task_history antes
-- de a linha correspondente existir em public.tasks, violando a FK.

DROP TRIGGER IF EXISTS tasks_history ON public.tasks;

CREATE OR REPLACE FUNCTION public.track_task_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.task_history(task_id, actor_id, action, details)
    VALUES (
      NEW.id,
      auth.uid(),
      'created',
      jsonb_build_object('title', NEW.title, 'assignee_id', NEW.assignee_id)
    );
    RETURN NEW;
  END IF;

  IF ROW(NEW.title, NEW.description, NEW.assignee_id, NEW.team_id, NEW.due_at, NEW.priority, NEW.status)
     IS DISTINCT FROM
     ROW(OLD.title, OLD.description, OLD.assignee_id, OLD.team_id, OLD.due_at, OLD.priority, OLD.status) THEN
    INSERT INTO public.task_history(task_id, actor_id, action, details)
    VALUES (
      NEW.id,
      auth.uid(),
      'updated',
      jsonb_build_object(
        'old', jsonb_build_object('title', OLD.title, 'assignee_id', OLD.assignee_id, 'status', OLD.status, 'due_at', OLD.due_at),
        'new', jsonb_build_object('title', NEW.title, 'assignee_id', NEW.assignee_id, 'status', NEW.status, 'due_at', NEW.due_at)
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_task_completed_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'done' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'done') THEN
    NEW.completed_at = now();
  ELSIF NEW.status <> 'done' THEN
    NEW.completed_at = NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tasks_completed_at ON public.tasks;
CREATE TRIGGER tasks_completed_at
BEFORE INSERT OR UPDATE ON public.tasks
FOR EACH ROW EXECUTE FUNCTION public.set_task_completed_at();

CREATE TRIGGER tasks_history
AFTER INSERT OR UPDATE ON public.tasks
FOR EACH ROW EXECUTE FUNCTION public.track_task_changes();

REVOKE EXECUTE ON FUNCTION public.track_task_changes() FROM PUBLIC, anon, authenticated;
