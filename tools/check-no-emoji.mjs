// Fails if any tracked text file outside apps/legacy contains an emoji.
// Project rule: no emojis in code, apps or docs (see CLAUDE.md).
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const TEXT_EXT = /\.(dart|ts|tsx|js|mjs|cjs|json|ya?ml|md|sql|arb|html|css|toml|sh|kts|gradle|xml|plist|swift|kt)$/i;
const EXCLUDE = [/^apps\/legacy\//, /^docs\/audit\//];
// Pictographs, emoticons, transport/map symbols, dingbats, flags, variation selector 16.
const EMOJI = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{FE0F}]/u;

const files = execFileSync('git', ['ls-files', '--cached', '--others', '--exclude-standard'], { encoding: 'utf8' })
  .split('\n')
  .filter((f) => f && TEXT_EXT.test(f) && !EXCLUDE.some((re) => re.test(f)));

const hits = [];
for (const file of files) {
  let text;
  try {
    text = readFileSync(file, 'utf8');
  } catch {
    continue;
  }
  text.split('\n').forEach((line, i) => {
    if (EMOJI.test(line)) hits.push(`${file}:${i + 1}: ${line.trim().slice(0, 80)}`);
  });
}

if (hits.length) {
  console.error(`Emoji found in ${hits.length} line(s):\n${hits.join('\n')}`);
  process.exit(1);
}
console.log(`No emoji in ${files.length} checked files.`);
