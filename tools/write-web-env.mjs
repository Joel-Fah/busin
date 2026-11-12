// Writes apps/admin_web/.env.local from the running local Supabase stack.
// Only public values are written (the API URL and the publishable key). Local development only.
import { execSync } from 'node:child_process';
import { existsSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const target = resolve('apps/admin_web/.env.local');
if (existsSync(target) && !process.argv.includes('--force')) {
  console.log(`${target} already exists. Use --force to replace it.`);
  process.exit(0);
}

let output;
try {
  output = execSync('npx supabase status -o env', { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
} catch {
  console.error('The local backend is not running. Start it first with: npm run backend:start');
  process.exit(1);
}

function read(name) {
  const match = output.match(new RegExp(`^${name}="?([^"\\r\\n]+)"?`, 'm'));
  if (!match) throw new Error(`Could not read ${name} from "supabase status".`);
  return match[1];
}

writeFileSync(
  target,
  `NEXT_PUBLIC_SUPABASE_URL=${read('API_URL')}\nNEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=${read('PUBLISHABLE_KEY')}\n`,
);
console.log(`Wrote ${target}`);
