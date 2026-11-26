begin;

create table if not exists public.sensor_readings (
  id uuid primary key default gen_random_uuid(),
  sensor_type text not null,
  x double precision,
  y double precision,
  z double precision,
  latitude double precision,
  longitude double precision,
  accuracy double precision,
  recorded_at timestamptz default now()
);

-- Las filas existentes conservan sus datos y quedan sin propietario hasta su asignación.
alter table public.sensor_readings
  add column if not exists owner_id uuid references auth.users (id);

alter table public.sensor_readings
  alter column owner_id set default auth.uid(),
  enable row level security;

create index if not exists sensor_readings_owner_date_idx
  on public.sensor_readings (owner_id, recorded_at desc nulls last, id desc);

create index if not exists sensor_readings_owner_type_date_idx
  on public.sensor_readings (owner_id, sensor_type, recorded_at desc nulls last, id desc);

-- La política restrictiva también limita las políticas permisivas existentes.
drop policy if exists sensor_track_owner_only on public.sensor_readings;
create policy sensor_track_owner_only on public.sensor_readings
  as restrictive for all to public
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

drop policy if exists sensor_track_select_own on public.sensor_readings;
create policy sensor_track_select_own on public.sensor_readings
  for select to authenticated using ((select auth.uid()) = owner_id);

drop policy if exists sensor_track_insert_own on public.sensor_readings;
create policy sensor_track_insert_own on public.sensor_readings
  for insert to authenticated with check ((select auth.uid()) = owner_id);

grant select, insert on public.sensor_readings to authenticated;

create or replace function public.sensor_statistics()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'total', count(*),
    'accelerometer', count(*) filter (where sensor_type = 'accelerometer'),
    'gyroscope', count(*) filter (where sensor_type = 'gyroscope'),
    'gps', count(*) filter (where sensor_type = 'gps'),
    'min_x', min(x) filter (where sensor_type = 'accelerometer'),
    'min_y', min(y) filter (where sensor_type = 'accelerometer'),
    'min_z', min(z) filter (where sensor_type = 'accelerometer'),
    'max_x', max(x) filter (where sensor_type = 'accelerometer'),
    'max_y', max(y) filter (where sensor_type = 'accelerometer'),
    'max_z', max(z) filter (where sensor_type = 'accelerometer'),
    'latest_location', (
      select to_jsonb(location)
      from (
        select id, sensor_type, latitude, longitude, accuracy, recorded_at
        from public.sensor_readings
        where owner_id = (select auth.uid())
          and sensor_type = 'gps'
          and latitude is not null
          and longitude is not null
        order by recorded_at desc nulls last, id desc
        limit 1
      ) as location
    )
  )
  from public.sensor_readings
  where owner_id = (select auth.uid());
$$;

revoke execute on function public.sensor_statistics() from public, anon;
grant execute on function public.sensor_statistics() to authenticated;

notify pgrst, 'reload schema';

commit;
