begin;
create table if not exists public.finance_user_preferences(
 user_id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '',
 avatar_path text,
 theme_key text not null default 'forest' check(theme_key in('forest','ocean','marsala','lavender','dark')),
 custom_primary text,
 custom_accent text,
 updated_at timestamptz not null default now()
);
alter table public.finance_user_preferences enable row level security;
drop policy if exists "preferences own read" on public.finance_user_preferences;
drop policy if exists "preferences own insert" on public.finance_user_preferences;
drop policy if exists "preferences own update" on public.finance_user_preferences;
create policy "preferences own read" on public.finance_user_preferences for select to authenticated using(user_id=(select auth.uid()));
create policy "preferences own insert" on public.finance_user_preferences for insert to authenticated with check(user_id=(select auth.uid()));
create policy "preferences own update" on public.finance_user_preferences for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
revoke all on public.finance_user_preferences from anon;
grant select,insert,update on public.finance_user_preferences to authenticated;
insert into public.finance_user_preferences(user_id,display_name)
select fm.user_id,coalesce(nullif(p.full_name,''),split_part(u.email,'@',1))
from public.finance_members fm join auth.users u on u.id=fm.user_id left join public.profiles p on p.id=fm.user_id
on conflict(user_id) do nothing;
revoke all on public.finance_members,public.finance_categories,public.financial_entries,public.financial_plans from anon;
grant select on public.finance_members to authenticated;
grant select,insert,update,delete on public.finance_categories,public.financial_entries,public.financial_plans to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('finance-avatars','finance-avatars',false,2097152,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=2097152,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists "finance avatar read own" on storage.objects;
drop policy if exists "finance avatar upload own" on storage.objects;
drop policy if exists "finance avatar update own" on storage.objects;
drop policy if exists "finance avatar delete own" on storage.objects;
create policy "finance avatar read own" on storage.objects for select to authenticated using(bucket_id='finance-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "finance avatar upload own" on storage.objects for insert to authenticated with check(bucket_id='finance-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "finance avatar update own" on storage.objects for update to authenticated using(bucket_id='finance-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text) with check(bucket_id='finance-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy "finance avatar delete own" on storage.objects for delete to authenticated using(bucket_id='finance-avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create index if not exists financial_entries_created_by_idx on public.financial_entries(created_by);
create index if not exists financial_entries_paid_by_idx on public.financial_entries(paid_by);
create index if not exists financial_plans_created_by_idx on public.financial_plans(created_by);
commit;