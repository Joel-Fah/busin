-- Private buckets and policies.
--
-- proofs/{school_id}/{user_id}/{file}  payment proofs, written by the student, read by the
--                                       student and by admins of the same school
-- stops/{school_id}/{file}              stop photos, written by admins, read by the school
--
-- Both buckets are private: files are read through short-lived signed URLs, never public URLs.
-- Clients cannot update or delete files, so evidence cannot be swapped after review;
-- a resubmission uploads a new file.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('proofs', 'proofs', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('stops', 'stops', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- proofs: a student writes into their own folder only.
create policy proofs_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'proofs'
    and (storage.foldername(name))[1] = (select private.my_school_id())::text
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and (select private.my_role()) = 'student'
  );

-- proofs: the owner reads their own files; admins read their school's files.
create policy proofs_select on storage.objects for select to authenticated
  using (
    bucket_id = 'proofs'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or (
        (storage.foldername(name))[1] = (select private.my_school_id())::text
        and (select private.is_admin())
      )
    )
  );

-- stop photos: members of the school read; admins of the school write.
create policy stops_select on storage.objects for select to authenticated
  using (
    bucket_id = 'stops'
    and (storage.foldername(name))[1] = (select private.my_school_id())::text
  );

create policy stops_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'stops'
    and (storage.foldername(name))[1] = (select private.my_school_id())::text
    and (select private.is_admin())
  );

create policy stops_update on storage.objects for update to authenticated
  using (
    bucket_id = 'stops'
    and (storage.foldername(name))[1] = (select private.my_school_id())::text
    and (select private.is_admin())
  )
  with check (
    bucket_id = 'stops'
    and (storage.foldername(name))[1] = (select private.my_school_id())::text
    and (select private.is_admin())
  );

create policy stops_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'stops'
    and (storage.foldername(name))[1] = (select private.my_school_id())::text
    and (select private.is_admin())
  );
