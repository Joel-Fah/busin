// Copies MapLibre's worker files into the portal's public folder.
//
// MapLibre runs its tile parsing in a web worker. Next's bundler (Turbopack) does not emit that worker
// file, so the browser reports "Worker failed to load" and the map stays blank: only markers draw. We
// serve the worker as a plain static file instead and point MapLibre at it (see
// apps/admin_web/components/map/providers/maplibre.tsx). The copies are generated, so they are not in git.
import { copyFileSync, mkdirSync } from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const require = createRequire(path.join(root, "apps/admin_web/package.json"));
const dist = path.join(path.dirname(require.resolve("maplibre-gl/package.json")), "dist");
const target = path.join(root, "apps/admin_web/public/vendor/maplibre");

mkdirSync(target, { recursive: true });
for (const file of ["maplibre-gl-worker.mjs", "maplibre-gl-shared.mjs"]) {
  copyFileSync(path.join(dist, file), path.join(target, file));
}
console.log("Copied the MapLibre worker to apps/admin_web/public/vendor/maplibre");
