# Google sign-in setup

BusIn signs people in with Google only. This guide creates the Google OAuth client and shows where its two keys go. It covers the local backend first, then notes for a hosted project.

## The two keys, and where they live

| Key | Where it goes | Never |
|---|---|---|
| Client ID | `supabase/.env` as `SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID` | in `config.toml`, in a commit, in an issue or chat |
| Client secret | `supabase/.env` as `SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET` | in `config.toml`, in a commit, in an issue or chat |

`supabase/.env` is git-ignored. `npm run backend:start` creates it with placeholder values the first time, so the backend starts before you have real keys. The committed file `supabase/config.toml` only refers to the variable names, and `supabase/.env.example` lists them without values. The apps and the portal never see these keys: only the Supabase Auth service uses them.

Treat the secret like a password. If it ever leaks, create a new secret in Google Cloud Console and delete the old one.

## 1. Create the OAuth client (about 10 minutes)

Use your personal Google account (see [ADR 0004](../decisions/0004-accounts-ownership.md)).

1. Open the [Google Cloud Console](https://console.cloud.google.com/) and create a project, for example `busin`.
2. Go to **Google Auth Platform** and start the setup.
   - **Branding**: app name `BusIn`, your support email.
   - **Audience**: choose **External**. While the app is in Testing mode, only the test users you list can sign in, so add every account you will try (your school address and any other admin you want to test).
   - **Data access**: the default scopes `openid`, `email` and `profile` are all BusIn needs. No sensitive scopes means no Google review beyond branding.
3. Go to **Clients**, then **Create client**.
   - Application type: **Web application**. Name: `BusIn local`.
   - **Authorized redirect URIs**, add both:
     - `http://127.0.0.1:54321/auth/v1/callback`
     - `http://localhost:54321/auth/v1/callback`
   - You do not need Authorized JavaScript origins for this flow.
4. Create it and copy the **Client ID** and **Client secret** from the dialog.

## 2. Put the keys in place

Open `supabase/.env` (run `npm run backend:start` once if it does not exist yet) and replace the placeholders:

```
SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID=<your client id>
SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET=<your client secret>
```

Restart the backend so Auth reads them:

```bash
npm run backend:stop
npm run backend:start
```

## 3. Sign in

```bash
npm run web
```

Open http://127.0.0.1:3000 and choose **Continue with Google**.

- The first sign-in creates a **student** account. Only emails on a school's allowed domain can sign up (locally, `ictuniversity.edu.cm`). Anyone else gets "This account could not be created".
- Nobody is an administrator by default. Promote your own account, on your machine only:

```bash
docker exec -i supabase_db_busin psql -U postgres -c "update public.profiles set role = 'admin' where email = 'you@ictuniversity.edu.cm';"
```

- To try the portal with a personal Gmail address, add its domain to the local school (local database only, never a hosted project):

```bash
docker exec -i supabase_db_busin psql -U postgres -c "insert into public.school_domains (domain, school_id) values ('gmail.com', '00000000-0000-4000-8000-000000000001');"
```

## Without Google: the development sign-in

For quick local work there is a second, development-only way in. It works only on a development server whose backend is on your own machine, and the page returns "not found" in any production build.

```bash
npm run dev:user        # creates or resets a local admin and prints its email and password
npm run web
```

Open http://127.0.0.1:3000/dev/login and sign in with the printed details. The password changes every time you run the script. This does not replace Google sign-in and does not exist outside local development.

## Hosted projects (later)

- Create a **separate** OAuth client for production, with the redirect URI `https://<project-ref>.supabase.co/auth/v1/callback` and no localhost URIs.
- Enter its ID and secret in the Supabase dashboard under **Authentication, Providers, Google**. They never go in the repository, and `supabase/config.toml` does not apply to a hosted project.
- Set the **Site URL** and the allowed redirect URLs under **Authentication, URL configuration** to the portal's real address.
- Keep the **Email** provider switched off in the hosted project. Only the local stack has it on, so the browser tests can open sessions.
- When ready for everyone, move the consent screen from Testing to **In production** in Google Auth Platform.
- The mobile apps (Phase 3) need their own Android and iOS OAuth clients.

## Troubleshooting

| What you see | Cause and fix |
|---|---|
| Google says `redirect_uri_mismatch` | The redirect URI in Google must match exactly, including `http`, the port `54321` and `/auth/v1/callback` |
| Google says the app is blocked or you are not a test user | Add the account under **Audience, Test users**. A school Google Workspace can also block third-party apps; use another account or ask its admin |
| `invalid_client` or "Unable to exchange external code" | The ID or secret is wrong, has stray spaces, or the backend was not restarted after editing `supabase/.env` |
| Back on the login page with "This account could not be created" | The email domain is not allowed by any school. Use `ictuniversity.edu.cm` or add the domain locally as shown above |
| Signed in but "No access" | The account is a student. Promote it with the command above, or use `npm run dev:user` |
