-- The school leaderboard: students of the caller's school who keep a streak (opting in to streaks is opting in to the
-- board, the owner's decision), ranked by current streak, then rides this semester. Never another school's students.
-- Names are shortened to the first name and the initial of the last; nothing else about a student is shown.

-- "Amara Ngono Ekotto" becomes "Amara E.".
create function private.short_name(p_full_name text)
returns text
language sql immutable
set search_path = ''
as $$
  select case
    when array_length(w, 1) is null then ''
    when array_length(w, 1) = 1 then w[1]
    else w[1] || ' ' || upper(left(w[array_length(w, 1)], 1)) || '.'
  end
  from (select regexp_split_to_array(btrim(coalesce(p_full_name, '')), '\s+') as w) x;
$$;

create function public.school_leaderboard(p_semester_id uuid, p_limit int default 50)
returns table (rank int, display_name text, avatar_url text, current_streak int, rides int, is_me boolean)
language plpgsql stable security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_school uuid := private.my_school_id();
  v_limit int := least(greatest(coalesce(p_limit, 50), 1), 100);
begin
  if v_school is null then
    raise exception 'A verified account is required' using errcode = '42501';
  end if;
  if not exists (select 1 from public.semesters s where s.id = p_semester_id and s.school_id = v_school) then
    return;
  end if;

  return query
  with board as (
    select p.id, private.short_name(p.full_name) as name, p.avatar_url, st.current_streak, st.rides
    from public.profiles p
    cross join lateral private.streak_of(p.id, p_semester_id) st
    where p.school_id = v_school and p.role = 'student' and p.status = 'verified' and p.streak_opt_in
  ),
  ranked as (
    select (row_number() over (order by b.current_streak desc, b.rides desc, b.name, b.id))::int as r, b.*
    from board b
  )
  select ranked.r, ranked.name, ranked.avatar_url, ranked.current_streak, ranked.rides, ranked.id = v_uid
  from ranked
  where ranked.r <= v_limit or ranked.id = v_uid
  order by ranked.r;
end;
$$;

revoke execute on function public.school_leaderboard(uuid, int) from public, anon;
grant execute on function public.school_leaderboard(uuid, int) to authenticated;
