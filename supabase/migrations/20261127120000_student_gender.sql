-- An optional gender on the profile (issue #564, owner's request): male, female, or not set. Google sign-in does not
-- provide it, so the student gives it at onboarding and can change or clear it in the profile. A person writes only
-- their own (the update grant and profiles_update); profiles are read by their owner and the school's admins only
-- (profiles_select), so staff, drivers and other students never see it. Erased with the account.

alter table public.profiles add column gender text check (gender is null or gender in ('male', 'female'));
grant update (gender) on public.profiles to authenticated;

-- Account deletion (ADR 0028) anonymises the profile by setting deleted_at: the gender goes with the rest.
create function private.erase_gender() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.deleted_at is not null and old.deleted_at is null then
    new.gender := null;
  end if;
  return new;
end;
$$;
revoke execute on function private.erase_gender() from public;

create trigger profiles_erase_gender
  before update of deleted_at on public.profiles
  for each row execute function private.erase_gender();
