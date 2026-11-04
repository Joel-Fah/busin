# Running the admin portal in Docker

The portal ships as one image: Node 24 LTS, Next.js standalone output, running as an unprivileged user. There is no CI job for it (Actions minutes are limited); build it locally.

## Build

Run from the repository root. The context is the root because the portal is an npm workspace.

```bash
docker build -f apps/admin_web/Dockerfile -t busin-admin-web \
  --build-arg NEXT_PUBLIC_SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --build-arg NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=YOUR-PUBLISHABLE-KEY .
```

The two build arguments are public values (the project URL and the publishable key). The browser needs them, so they are fixed when the image is built; the build stops with a message if either is missing. Never pass a service-role key or any secret.

## Run

```bash
docker run --rm -p 3000:3000 \
  -e SITE_URL=https://admin.example.com \
  -e MAPBOX_API_KEY=pk.YOUR-RESTRICTED-PUBLIC-TOKEN \
  busin-admin-web
```

All runtime settings are optional and none is a secret: `SITE_URL` (the public address, used for the sign-in redirect), `MAPBOX_API_KEY` (a public `pk.` token restricted to your site; without one the free map is used), `MAP_PROVIDER`. See [ADR 0008](../decisions/0008-map-provider.md) for the map cost rules.

## Trying it against the local backend

With the local stack running (`npm run backend:start`), build with `NEXT_PUBLIC_SUPABASE_URL=http://host.docker.internal:54321` and the publishable key from `npx supabase status -o env`, then run with `--add-host=host.docker.internal:host-gateway`. The browser also reaches the backend at that address, so add `127.0.0.1 host.docker.internal` to your hosts file, or use the normal `npm run web` for local work.

## Notes

- The image holds no secrets; `.dockerignore` keeps `.env` files, tests and the other tiers out of the build context.
- `NEXT_OUTPUT=standalone` is set only inside the image build, so `npm run build` and `npm start` outside Docker are unchanged.
- Upgrading Node or any base image is its own issue and PR.
