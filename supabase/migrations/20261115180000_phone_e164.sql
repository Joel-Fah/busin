-- Phone numbers in one form (ADR 0024): E.164, a `+` then the country code and the number, digits only
-- (`+237677123456`). The apps read what people type for the country chosen in the field and send this form; the
-- database keeps to it. Existing numbers are tidied here, best effort; one that cannot be read is cleared, so a student
-- is asked for it again by the setup gate (the phone is required) and a school simply shows none.

-- The best reading of a number saved before this rule. All data so far comes from one Cameroonian school, so a bare
-- 9-digit Cameroonian number (mobiles 6xxxxxxxx, fixed lines 2xxxxxxxx), with or without a leading 0 or 237, gets +237.
create function private.phone_e164_guess(p_raw text) returns text
language plpgsql immutable
set search_path = ''
as $$
declare
  v_plus text := regexp_replace(coalesce(p_raw, ''), '[^0-9+]', '', 'g');
  v_digits text := regexp_replace(coalesce(p_raw, ''), '[^0-9]', '', 'g');
begin
  if v_plus ~ '^\+[1-9][0-9]{6,14}$' then
    return v_plus;
  end if;
  if v_digits ~ '^0?[26][0-9]{8}$' then
    return '+237' || right(v_digits, 9);
  end if;
  if v_digits ~ '^237[26][0-9]{8}$' then
    return '+' || v_digits;
  end if;
  return null;
end;
$$;
revoke execute on function private.phone_e164_guess(text) from public;

do $$
declare
  v_profiles int;
  v_schools int;
begin
  update public.profiles set phone = private.phone_e164_guess(phone)
  where phone is not null and phone !~ '^\+[1-9][0-9]{6,14}$';
  get diagnostics v_profiles = row_count;
  update public.schools set phone = private.phone_e164_guess(phone)
  where phone is not null and phone !~ '^\+[1-9][0-9]{6,14}$';
  get diagnostics v_schools = row_count;
  raise notice 'phone numbers tidied: % profiles, % schools (a number that could not be read is now empty)', v_profiles, v_schools;
end;
$$;

alter table public.profiles add constraint profiles_phone_e164 check (phone is null or phone ~ '^\+[1-9][0-9]{6,14}$');
alter table public.schools drop constraint if exists schools_phone_check;
alter table public.schools add constraint schools_phone_check check (phone is null or phone ~ '^\+[1-9][0-9]{6,14}$');
