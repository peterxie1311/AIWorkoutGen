-- Run this in Supabase SQL Editor before using the moddate-based app.
-- The private.user_settings table and api.getsettings function stay unchanged.
-- Session identity always comes from validatesession_internal, never the payload.

begin;

create or replace function api.insupdatesettings(
    i_payload jsonb,
    i_sessionid uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_userid uuid;
    v_moddate timestamptz;
    s jsonb;
begin
    select private.validatesession_internal(i_sessionid) into v_userid;
    if v_userid is null then
        raise exception 'Invalid or expired session.' using errcode = '28000';
    end if;

    if jsonb_typeof(i_payload) is distinct from 'array' then
        raise exception 'Settings payload must be a JSON array.' using errcode = '22023';
    end if;

    for s in select value from jsonb_array_elements(i_payload)
    loop
        if jsonb_typeof(s) is distinct from 'object'
           or jsonb_typeof(s->'settingName') is distinct from 'string'
           or jsonb_typeof(s->'value') is distinct from 'string'
           or jsonb_typeof(s->'moddate') is distinct from 'string'
        then
            raise exception 'Each setting requires settingName, value and moddate strings.'
                using errcode = '22023';
        end if;
        v_moddate := (s->>'moddate')::timestamptz;
        if v_moddate is null or not isfinite(v_moddate) then
            raise exception 'Invalid settings modification date.' using errcode = '22023';
        end if;

        insert into private.user_settings as stored (
            user_id, setting_name, value, moddate
        )
        values (
            v_userid, s->>'settingName', s->>'value', v_moddate
        )
        on conflict (user_id, setting_name)
        do update set
            value = excluded.value,
            moddate = excluded.moddate
        where excluded.moddate > stored.moddate;
    end loop;
end;
$function$;

revoke execute on function api.insupdatesettings(jsonb, uuid)
from public, anon, authenticated;
grant execute on function api.insupdatesettings(jsonb, uuid)
to anon, authenticated;

commit;

