# Account deletion: setup and checks

How deletions run is in [ADR 0028](../decisions/0028-account-deletion.md).

## Locally
1. Sign in to any app with a test account and use Profile, Delete my account. The app shows the date.
2. `npm run dev:erase -- <that email>` runs the night's erasure for that account now: its proof files are removed, its
   sign-in account soft-deleted and its profile emptied. The school's records stay under "Deleted account".
3. Signing up again with the same email gives a new, empty account.

## On the hosted project (owner, each step with approval)
1. Apply the migration `20261116180000_account_deletion.sql`.
2. Set the function secret: `npx supabase secrets set DELETIONS_SECRET="$(openssl rand -hex 32)" --project-ref <ref>`.
3. Deploy: `npx supabase functions deploy delete-accounts --project-ref <ref> --use-api`.
4. In the SQL editor, store where the function lives and the same secret, so the nightly job can call it:
   `select vault.create_secret('https://<ref>.supabase.co/functions/v1/delete-accounts', 'deletions_url');`
   `select vault.create_secret('<the same secret>', 'deletions_secret');`
5. Check the next morning in the console's Health tab: the job `busin-erase-accounts` ran.
6. Give Google Play the page `https://<site>/delete-account` as the account deletion link.
