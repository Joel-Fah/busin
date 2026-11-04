# BusIn admin portal image. Build from the repository root:
#   docker build -f apps/admin_web/Dockerfile -t busin-admin-web \
#     --build-arg NEXT_PUBLIC_SUPABASE_URL=... --build-arg NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=... .
# See docs/guides/docker.md.

# Node 24 LTS, the version in .nvmrc.
FROM node:24-slim AS base
WORKDIR /repo

FROM base AS deps
# Only the manifests, so this layer is reused until a dependency changes.
COPY package.json package-lock.json ./
COPY apps/admin_web/package.json apps/admin_web/package.json
# The cache mount keeps downloaded packages between builds, so a slow or dropped connection resumes instead of starting over.
RUN --mount=type=cache,target=/root/.npm \
    npm ci --ignore-scripts --fetch-retries=5 --fetch-retry-mintimeout=20000 --fetch-timeout=120000

FROM base AS build
COPY --from=deps /repo/node_modules ./node_modules
COPY package.json package-lock.json ./
COPY tools/copy-map-workers.mjs tools/copy-map-workers.mjs
COPY apps/admin_web apps/admin_web
# These two are public values the browser needs, so they are fixed when the image is built.
# They are the project URL and the publishable key, never a secret.
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY
ENV NEXT_PUBLIC_SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL \
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=$NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY \
    NEXT_OUTPUT=standalone \
    NEXT_TELEMETRY_DISABLED=1
RUN test -n "$NEXT_PUBLIC_SUPABASE_URL" && test -n "$NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY" \
    || (echo "Pass NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY as build arguments." && exit 1)
RUN npm run build -w apps/admin_web

FROM base AS run
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    HOSTNAME=0.0.0.0 \
    PORT=3000
# Run as an unprivileged user.
RUN groupadd --system app && useradd --system --gid app --no-create-home app
COPY --from=build --chown=app:app /repo/apps/admin_web/.next/standalone ./
COPY --from=build --chown=app:app /repo/apps/admin_web/.next/static apps/admin_web/.next/static
COPY --from=build --chown=app:app /repo/apps/admin_web/public apps/admin_web/public
USER app
EXPOSE 3000
# Optional runtime settings (MAPBOX_API_KEY, MAP_PROVIDER, SITE_URL) are passed with `docker run -e`.
CMD ["node", "apps/admin_web/server.js"]
