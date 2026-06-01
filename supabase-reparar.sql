-- ============================================================
--  Sorteo Prekínder B · REPARAR base de datos Supabase
--  Es SEGURO de correr aunque ya tengas datos: NO borra tickets.
--  Cómo usarlo:
--   1. Supabase → SQL Editor → New query
--   2. Pega TODO este archivo y presiona Run
--   3. Debe terminar en "Success". Si algo sale amarillo
--      (NOTICE), es normal, no es error.
-- ============================================================

-- ---------- 1. Tablas (se crean solo si faltan) ----------
create table if not exists public.config (
  id   int  primary key,
  data jsonb not null default '{}'::jsonb
);

create table if not exists public.tickets (
  number     bigint generated always as identity primary key,
  code       text   not null default '…',
  name       text   not null default '',
  contact    text,
  student    text,
  status     text   not null default 'pending',
  method     text,
  price      int    not null default 0,
  created_at timestamptz not null default now()
);

-- ---------- 2. Columnas faltantes (por si la tabla quedó a medias) ----------
alter table public.tickets add column if not exists code       text   not null default '…';
alter table public.tickets add column if not exists name       text   not null default '';
alter table public.tickets add column if not exists contact    text;
alter table public.tickets add column if not exists student    text;
alter table public.tickets add column if not exists status     text   not null default 'pending';
alter table public.tickets add column if not exists method     text;
alter table public.tickets add column if not exists price      int    not null default 0;
alter table public.tickets add column if not exists created_at timestamptz not null default now();

-- ---------- 3. Seguridad (RLS) ----------
alter table public.config  enable row level security;
alter table public.tickets enable row level security;

drop policy if exists "config_read"   on public.config;
drop policy if exists "config_write"  on public.config;
drop policy if exists "config_update" on public.config;
create policy "config_read"   on public.config for select using (true);
create policy "config_write"  on public.config for insert with check (true);
create policy "config_update" on public.config for update using (true) with check (true);

drop policy if exists "tickets_read"   on public.tickets;
drop policy if exists "tickets_insert" on public.tickets;
drop policy if exists "tickets_update" on public.tickets;
drop policy if exists "tickets_delete" on public.tickets;
create policy "tickets_read"   on public.tickets for select using (true);
create policy "tickets_insert" on public.tickets for insert with check (true);
create policy "tickets_update" on public.tickets for update using (true) with check (true);
create policy "tickets_delete" on public.tickets for delete using (true);

-- ---------- 4. Tiempo real (no corta si ya estaba activo) ----------
do $$
begin
  begin
    alter publication supabase_realtime add table public.tickets;
  exception when duplicate_object then null;
            when others then null;
  end;
  begin
    alter publication supabase_realtime add table public.config;
  exception when duplicate_object then null;
            when others then null;
  end;
end $$;

-- ---------- 5. Fila de configuración inicial ----------
insert into public.config (id, data)
values (1, '{"config":{},"winners":[]}'::jsonb)
on conflict (id) do nothing;

-- ---------- 6. Verificación rápida ----------
select
  (select count(*) from public.tickets) as tickets_guardados,
  (select count(*) from public.config)  as filas_config;
