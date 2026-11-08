create or replace function public.notify_finance_entry_change() returns trigger language plpgsql security definer set search_path='' as $function$
declare v_actor uuid;v_actor_name text;v_event text;v_title text;v_message text;
begin
 if tg_op='INSERT' then
  if new.series_id is not null and exists(select 1 from public.financial_entries where series_id=new.series_id and id<>new.id) then return new;end if;
  v_actor:=coalesce(auth.uid(),new.created_by);v_event:='account_created';v_title:='Nova conta cadastrada';
 elsif tg_op='UPDATE' and old.status is distinct from new.status then
  v_actor:=coalesce(auth.uid(),new.paid_by,old.paid_by,new.created_by);
  if new.status='paid' then v_event:='account_paid';v_title:='Conta paga';
  elsif new.status='pending' then v_event:='account_unpaid';v_title:='Pagamento desfeito';
  else return new;end if;
 else return new;end if;
 if auth.uid() is not null and not exists(select 1 from public.finance_members where user_id=auth.uid()) then raise exception 'Acesso não autorizado.';end if;
 select coalesce(nullif(btrim(f.display_name),''),nullif(btrim(p.full_name),''),'Um usuário') into v_actor_name from public.profiles p left join public.finance_user_preferences f on f.user_id=p.id where p.id=v_actor;
 v_actor_name:=coalesce(v_actor_name,'Um usuário');
 if tg_op='INSERT' then v_message:=v_actor_name||' cadastrou "'||new.description||'" no valor de R$ '||replace(to_char(new.amount,'FM999999990D00'),'.',',')||'.';
 elsif new.status='paid' then v_message:=v_actor_name||' pagou "'||new.description||'".';
 else v_message:=v_actor_name||' desfez o pagamento de "'||new.description||'".';end if;
 insert into public.finance_notifications(recipient_id,actor_id,entry_id,event_type,title,message)
 select user_id,v_actor,new.id,v_event,v_title,v_message from public.finance_members;
 return new;
end;$function$;
revoke all on function public.notify_finance_entry_change() from public,anon,authenticated;
update public.finance_notifications n set message=coalesce(nullif(btrim(f.display_name),''),nullif(btrim(p.full_name),''))||substring(n.message from length('Um usuário')+1)
from public.profiles p left join public.finance_user_preferences f on f.user_id=p.id
where n.actor_id=p.id and n.message like 'Um usuário %' and coalesce(nullif(btrim(f.display_name),''),nullif(btrim(p.full_name),'')) is not null;