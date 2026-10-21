-- Kota Kurtis SEO workspace: run once in the Supabase SQL editor.
-- No browser-facing role can add itself to seo_admins.
create table if not exists public.seo_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.seo_workspace (
  id integer primary key default 1 check (id = 1),
  state jsonb not null default '{}'::jsonb check (jsonb_typeof(state) = 'object' and pg_column_size(state) <= 1048576),
  updated_at timestamptz not null default now(),
  updated_by uuid not null references auth.users(id)
);

alter table public.seo_admins enable row level security;
alter table public.seo_workspace enable row level security;

revoke all on table public.seo_admins from anon, authenticated;
grant select on table public.seo_admins to authenticated;
revoke all on table public.seo_workspace from anon, authenticated;
grant select, insert, update on table public.seo_workspace to authenticated;

drop policy if exists "Admins can read own admin membership" on public.seo_admins;
create policy "Admins can read own admin membership"
  on public.seo_admins for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "SEO admins can read workspace" on public.seo_workspace;
create policy "SEO admins can read workspace"
  on public.seo_workspace for select to authenticated
  using (exists (select 1 from public.seo_admins a where a.user_id = (select auth.uid())));

drop policy if exists "SEO admins can initialize workspace" on public.seo_workspace;
create policy "SEO admins can initialize workspace"
  on public.seo_workspace for insert to authenticated
  with check (updated_by = (select auth.uid()) and exists (select 1 from public.seo_admins a where a.user_id = (select auth.uid())));

drop policy if exists "SEO admins can update workspace" on public.seo_workspace;
create policy "SEO admins can update workspace"
  on public.seo_workspace for update to authenticated
  using (exists (select 1 from public.seo_admins a where a.user_id = (select auth.uid())))
  with check (updated_by = (select auth.uid()) and exists (select 1 from public.seo_admins a where a.user_id = (select auth.uid())));

-- Validate lengths and collection shapes inside Postgres as well as in the browser.
create or replace function public.validate_seo_workspace_state()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  item jsonb;
  field_name text;
  max_chars integer;
begin
  if jsonb_typeof(new.state) <> 'object' then
    raise exception 'SEO workspace state must be a JSON object';
  end if;
  if new.state ? 'products' and jsonb_typeof(new.state->'products') <> 'object' then
    raise exception 'Products must be a JSON object';
  end if;
  if new.state ? 'pages' and jsonb_typeof(new.state->'pages') <> 'array' then
    raise exception 'Pages must be a JSON array';
  end if;
  if new.state ? 'keywords' and jsonb_typeof(new.state->'keywords') <> 'array' then
    raise exception 'Keywords must be a JSON array';
  end if;
  if new.state ? 'content' and jsonb_typeof(new.state->'content') <> 'array' then
    raise exception 'Content must be a JSON array';
  end if;

  for item in
    select value from jsonb_each(coalesce(new.state->'products', '{}'::jsonb))
    union all
    select value from jsonb_array_elements(coalesce(new.state->'pages', '[]'::jsonb))
    union all
    select value from jsonb_array_elements(coalesce(new.state->'keywords', '[]'::jsonb))
    union all
    select value from jsonb_array_elements(coalesce(new.state->'content', '[]'::jsonb))
  loop
    if jsonb_typeof(item) <> 'object' then
      raise exception 'SEO workspace records must be JSON objects';
    end if;
    foreach field_name in array array['title','metaTitle','ogTitle','h1'] loop
      max_chars := case field_name when 'h1' then 200 else 70 end;
      if char_length(coalesce(item->>field_name, '')) > max_chars then
        raise exception 'SEO field % exceeds % characters', field_name, max_chars;
      end if;
    end loop;
    foreach field_name in array array['description','ogDescription'] loop
      if char_length(coalesce(item->>field_name, '')) > 180 then
        raise exception 'SEO field % exceeds 180 characters', field_name;
      end if;
    end loop;
    if char_length(coalesce(item->>'keyword', '')) > 90
       or char_length(coalesce(item->>'secondary', '')) > 180
       or char_length(coalesce(item->>'alt', '')) > 160
       or char_length(coalesce(item->>'canonical', '')) > 2048 then
      raise exception 'SEO keyword, alt text, or canonical URL exceeds allowed length';
    end if;
  end loop;
  return new;
end;
$$;

drop trigger if exists validate_seo_workspace_state on public.seo_workspace;
create trigger validate_seo_workspace_state
  before insert or update of state on public.seo_workspace
  for each row execute function public.validate_seo_workspace_state();
revoke all on function public.validate_seo_workspace_state() from public, anon, authenticated;
