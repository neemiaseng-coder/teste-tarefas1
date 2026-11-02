-- Teste Tarefas — esquema inicial Supabase
-- Execute no SQL Editor de um projeto novo. Não coloque a service_role key no frontend.
create extension if not exists pgcrypto;

create type public.app_role as enum ('admin','manager','user');
create type public.task_status as enum ('pending','in_progress','done');
create type public.task_priority as enum ('low','medium','high');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role public.app_role not null default 'user',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.team_members (
  team_id uuid not null references public.teams(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  member_role text not null default 'member' check (member_role in ('leader','member')),
  created_at timestamptz not null default now(),
  primary key (team_id,user_id)
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 1 and 160),
  description text not null default '',
  creator_id uuid not null references public.profiles(id),
  assignee_id uuid not null references public.profiles(id),
  team_id uuid references public.teams(id) on delete set null,
  due_at date,
  priority public.task_priority not null default 'medium',
  status public.task_status not null default 'pending',
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.task_comments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  author_id uuid not null references public.profiles(id),
  body text not null check (char_length(trim(body)) between 1 and 5000),
  created_at timestamptz not null default now()
);

create table public.task_subtasks (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 160),
  is_done boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.task_history (
  id bigint generated always as identity primary key,
  task_id uuid not null references public.tasks(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.task_dependencies (
  task_id uuid not null references public.tasks(id) on delete cascade,
  depends_on_task_id uuid not null references public.tasks(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(task_id,depends_on_task_id),
  check(task_id <> depends_on_task_id)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete cascade,
  title text not null,
  body text not null default '',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index tasks_assignee_status_idx on public.tasks(assignee_id,status);
create index tasks_due_at_idx on public.tasks(due_at) where status <> 'done';
create index tasks_team_idx on public.tasks(team_id);
create index task_comments_task_created_idx on public.task_comments(task_id,created_at);
create index task_history_task_created_idx on public.task_history(task_id,created_at desc);
create index notifications_user_unread_idx on public.notifications(user_id,created_at desc) where read_at is null;

create or replace function public.current_app_role()
returns public.app_role language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() and active = true $$;

create or replace function public.is_task_member(target_task uuid)
returns boolean language sql stable security definer set search_path = public
as $$ select exists (
  select 1 from public.tasks t
  where t.id = target_task and (
    t.creator_id = auth.uid() or t.assignee_id = auth.uid() or
    (t.team_id is not null and exists (
      select 1 from public.team_members tm where tm.team_id=t.team_id and tm.user_id=auth.uid()
    ))
  )
) $$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$ begin
  insert into public.profiles(id,full_name)
  values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''));
  return new;
end $$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public
as $$ begin new.updated_at=now(); return new; end $$;
create trigger profiles_updated_at before update on public.profiles
for each row execute procedure public.set_updated_at();
create trigger tasks_updated_at before update on public.tasks
for each row execute procedure public.set_updated_at();

create or replace function public.track_task_changes()
returns trigger language plpgsql security definer set search_path = public
as $$ begin
  if TG_OP='INSERT' then
    insert into public.task_history(task_id,actor_id,action,details)
    values(new.id,auth.uid(),'created',jsonb_build_object('title',new.title,'assignee_id',new.assignee_id));
    return new;
  end if;
  if row(new.title,new.description,new.assignee_id,new.team_id,new.due_at,new.priority,new.status)
     is distinct from
     row(old.title,old.description,old.assignee_id,old.team_id,old.due_at,old.priority,old.status) then
    insert into public.task_history(task_id,actor_id,action,details)
    values(new.id,auth.uid(),'updated',jsonb_build_object(
      'old',jsonb_build_object('title',old.title,'assignee_id',old.assignee_id,'status',old.status,'due_at',old.due_at),
      'new',jsonb_build_object('title',new.title,'assignee_id',new.assignee_id,'status',new.status,'due_at',new.due_at)
    ));
  end if;
  if new.status='done' and old.status<>'done' then new.completed_at=now();
  elsif new.status<>'done' then new.completed_at=null; end if;
  return new;
end $$;
create trigger tasks_history before insert or update on public.tasks
for each row execute procedure public.track_task_changes();

alter table public.profiles enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.tasks enable row level security;
alter table public.task_comments enable row level security;
alter table public.task_subtasks enable row level security;
alter table public.task_history enable row level security;
alter table public.task_dependencies enable row level security;
alter table public.notifications enable row level security;

create policy "profiles read authenticated" on public.profiles for select to authenticated
using (active=true or id=auth.uid() or public.current_app_role()='admin');
create policy "admins update profiles" on public.profiles for update to authenticated
using (public.current_app_role()='admin')
with check (public.current_app_role()='admin');
-- Usuários comuns não podem alterar seu próprio perfil/role por esta API. Atualizações administrativas são restritas a admin.
create policy "teams visible to members" on public.teams for select to authenticated
using (created_by=auth.uid() or public.current_app_role()='admin' or exists(select 1 from public.team_members tm where tm.team_id=id and tm.user_id=auth.uid()));
create policy "admins manage teams" on public.teams for all to authenticated
using (public.current_app_role()='admin') with check (public.current_app_role()='admin');
create or replace function public.is_team_member(target_team uuid)
returns boolean language sql stable security definer set search_path = public
as $ select exists(select 1 from public.team_members tm where tm.team_id=target_team and tm.user_id=auth.uid()) $;
create policy "members visible to team" on public.team_members for select to authenticated
using (user_id=auth.uid() or public.current_app_role()='admin' or public.is_team_member(team_id));
create policy "admins manage memberships" on public.team_members for all to authenticated
using (public.current_app_role()='admin') with check (public.current_app_role()='admin');

create policy "read tasks in scope" on public.tasks for select to authenticated
using (public.current_app_role()='admin' or creator_id=auth.uid() or assignee_id=auth.uid() or exists(select 1 from public.team_members tm where tm.team_id=tasks.team_id and tm.user_id=auth.uid()));
create policy "create own tasks" on public.tasks for insert to authenticated
with check (creator_id=auth.uid() and exists(select 1 from public.profiles p where p.id=assignee_id and p.active=true));
create policy "update tasks in scope" on public.tasks for update to authenticated
using (public.current_app_role()='admin' or creator_id=auth.uid() or assignee_id=auth.uid() or (public.current_app_role()='manager' and team_id is not null and exists(select 1 from public.team_members tm where tm.team_id=tasks.team_id and tm.user_id=auth.uid() and tm.member_role='leader')))
with check (public.current_app_role()='admin' or creator_id=auth.uid() or assignee_id=auth.uid() or (public.current_app_role()='manager' and team_id is not null and exists(select 1 from public.team_members tm where tm.team_id=tasks.team_id and tm.user_id=auth.uid() and tm.member_role='leader')));
create policy "admins delete tasks" on public.tasks for delete to authenticated
using (public.current_app_role()='admin');

create policy "comments read in task scope" on public.task_comments for select to authenticated using(public.is_task_member(task_id) or public.current_app_role()='admin');
create policy "comments create in task scope" on public.task_comments for insert to authenticated with check(author_id=auth.uid() and public.is_task_member(task_id));
create policy "subtasks read in task scope" on public.task_subtasks for select to authenticated using(public.is_task_member(task_id) or public.current_app_role()='admin');
create policy "subtasks manage in task scope" on public.task_subtasks for all to authenticated using(public.is_task_member(task_id) or public.current_app_role()='admin') with check(public.is_task_member(task_id) or public.current_app_role()='admin');
create policy "history read in task scope" on public.task_history for select to authenticated using(public.is_task_member(task_id) or public.current_app_role()='admin');
create policy "dependencies read in task scope" on public.task_dependencies for select to authenticated using(public.is_task_member(task_id) or public.is_task_member(depends_on_task_id) or public.current_app_role()='admin');
create policy "dependencies manage in task scope" on public.task_dependencies for all to authenticated using(public.is_task_member(task_id) or public.current_app_role()='admin') with check(public.is_task_member(task_id) or public.current_app_role()='admin');
create policy "notifications own rows" on public.notifications for select to authenticated using(user_id=auth.uid() or public.current_app_role()='admin');
create policy "notifications update own rows" on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());

-- Bootstrap: após criar seu primeiro usuário no Auth, promova-o a admin no SQL Editor:
-- update public.profiles set role='admin' where id=(select id from auth.users where email='SEU_EMAIL');
