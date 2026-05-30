-- ============================================================
--  Sorteo Prekínder B · Base de datos Supabase
--  Cómo usarlo:
--   1. Entra a https://supabase.com y crea un proyecto (gratis).
--   2. En el menú lateral abre  SQL Editor  →  New query.
--   3. Pega TODO este archivo y presiona  Run.
--   4. Ve a  Project Settings → API  y copia:
--        - Project URL        → pégalo en SUPABASE_URL
--        - anon public key     → pégalo en SUPABASE_ANON_KEY
--      (ambos van dentro del archivo "Sorteo Prekínder B.html")
-- ============================================================

-- ---------- Tabla de configuración (una sola fila) ----------
create table if not exists public.config (
  id   int  primary key,
  data jsonb not null default '{}'::jsonb
);

-- ---------- Tabla de tickets ----------
-- "number" se asigna solo y de forma única, incluso con
-- varios compradores comprando al mismo tiempo.
create table if not exists public.tickets (
  number     bigint generated always as identity primary key,
  code       text   not null,
  name       text   not null,
  contact    text,
  student    text,
  status     text   not null default 'pending',
  method     text,
  price      int    not null default 0,
  created_at timestamptz not null default now()
);

-- ---------- Seguridad (RLS) ----------
alter table public.config  enable row level security;
alter table public.tickets enable row level security;

-- Sorteo público: cualquiera puede leer/escribir tickets y leer la config.
-- (La clave de organizadores NO se guarda aquí; vive en el HTML.)
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

-- ---------- Tiempo real (live sync) ----------
-- Si alguna línea da el error "is already member", ignóralo: ya estaba activo.
alter publication supabase_realtime add table public.tickets;
alter publication supabase_realtime add table public.config;

-- ---------- Fila de configuración inicial ----------
insert into public.config (id, data)
values (1, '{"config":{},"winners":[]}'::jsonb)
on conflict (id) do nothing;
