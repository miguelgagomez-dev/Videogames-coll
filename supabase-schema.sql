-- Retro Game Vault · Supabase schema
-- Ejecutar en Supabase > SQL Editor. Diseñado para una colección privada.
-- Desactiva el registro público en Authentication > Settings tras crear tu usuario.
create extension if not exists pgcrypto;

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null, platform text not null, year integer, genre text,
  region text default 'PAL España', edition text, condition text, completeness text,
  estimated_value numeric(10,2), min_value numeric(10,2), max_value numeric(10,2),
  currency text not null default 'EUR', notes text, cover_path text,
  photo_paths jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint games_year_range check (year is null or year between 1970 and 2100),
  constraint games_value_nonnegative check (
    (estimated_value is null or estimated_value >= 0) and
    (min_value is null or min_value >= 0) and (max_value is null or max_value >= 0)
  )
);
create index if not exists games_user_id_idx on public.games(user_id);
create index if not exists games_title_idx on public.games using gin (to_tsvector('simple', title));
alter table public.games enable row level security;

drop policy if exists "Owner can read own games" on public.games;
create policy "Owner can read own games" on public.games for select to authenticated using (auth.uid() = user_id);
drop policy if exists "Owner can add own games" on public.games;
create policy "Owner can add own games" on public.games for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "Owner can edit own games" on public.games;
create policy "Owner can edit own games" on public.games for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Owner can delete own games" on public.games;
create policy "Owner can delete own games" on public.games for delete to authenticated using (auth.uid() = user_id);

create table if not exists public.price_observations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  game_id uuid not null references public.games(id) on delete cascade,
  observed_at date not null default current_date,
  amount numeric(10,2) not null check (amount >= 0),
  currency text not null default 'EUR', source text,
  sale_type text not null default 'asking', condition text, notes text,
  created_at timestamptz not null default now()
);
create index if not exists price_observations_user_game_idx on public.price_observations(user_id, game_id, observed_at desc);
alter table public.price_observations enable row level security;

drop policy if exists "Owner can read own price observations" on public.price_observations;
create policy "Owner can read own price observations" on public.price_observations for select to authenticated using (auth.uid() = user_id);
drop policy if exists "Owner can add own price observations" on public.price_observations;
create policy "Owner can add own price observations" on public.price_observations for insert to authenticated with check (
  auth.uid() = user_id and exists (select 1 from public.games g where g.id = game_id and g.user_id = auth.uid())
);
drop policy if exists "Owner can edit own price observations" on public.price_observations;
create policy "Owner can edit own price observations" on public.price_observations for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Owner can delete own price observations" on public.price_observations;
create policy "Owner can delete own price observations" on public.price_observations for delete to authenticated using (auth.uid() = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('game-photos','game-photos',false,10485760,array['image/jpeg','image/png','image/webp','image/avif'])
on conflict (id) do update set public=false, file_size_limit=10485760, allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "Owner reads own game photos" on storage.objects;
create policy "Owner reads own game photos" on storage.objects for select to authenticated using (bucket_id='game-photos' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "Owner uploads own game photos" on storage.objects;
create policy "Owner uploads own game photos" on storage.objects for insert to authenticated with check (bucket_id='game-photos' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "Owner updates own game photos" on storage.objects;
create policy "Owner updates own game photos" on storage.objects for update to authenticated using (bucket_id='game-photos' and (storage.foldername(name))[1]=auth.uid()::text) with check (bucket_id='game-photos' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "Owner deletes own game photos" on storage.objects;
create policy "Owner deletes own game photos" on storage.objects for delete to authenticated using (bucket_id='game-photos' and (storage.foldername(name))[1]=auth.uid()::text);

create or replace function public.set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at=now(); return new; end; $$;
drop trigger if exists games_set_updated_at on public.games;
create trigger games_set_updated_at before update on public.games for each row execute function public.set_updated_at();
