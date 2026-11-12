// Fails if a relative link in a tracked Markdown file points to a missing file.
// External (http/https/mailto) links and pure #anchors are not checked.
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const EXCLUDE = [/^apps\/legacy\//];
const LINK = /\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g;

const files = execFileSync('git', ['ls-files', '--cached', '--others', '--exclude-standard', '*.md'], { encoding: 'utf8' })
  .split('\n')
  .filter((f) => f && !EXCLUDE.some((re) => re.test(f)));

const broken = [];
for (const file of files) {
  const text = readFileSync(file, 'utf8').replace(/```[\s\S]*?```/g, '');
  for (const [, raw] of text.matchAll(LINK)) {
    if (/^(https?:|mailto:|#)/.test(raw)) continue;
    const target = decodeURIComponent(raw.split('#')[0]);
    if (!target) continue;
    if (!existsSync(resolve(dirname(file), target))) broken.push(`${file}: ${raw}`);
  }
}

if (broken.length) {
  console.error(`Broken relative links (${broken.length}):\n${broken.join('\n')}`);
  process.exit(1);
}
console.log(`All relative links resolve in ${files.length} Markdown files.`);
