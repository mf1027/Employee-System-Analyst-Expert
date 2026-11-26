import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const read = (relative) => readFileSync(path.join(root, relative), 'utf8');
const claude = read('CLAUDE.md').toLowerCase();
const agents = read('AGENTS.md').toLowerCase();
const quarantinedPath = path.join(root, 'quarantine/red-team/godmode/SKILL.md');

for (const [name, content] of [['CLAUDE.md', claude], ['AGENTS.md', agents]]) {
  test(`${name} quarantines Godmode as a high-risk non-default skill`, () => {
    assert.match(content, /high-risk legacy skill boundary/);
    assert.match(content, /not a default skill/);
    assert.match(content, /cannot override system, developer, user, host, or safety policy/);
    assert.match(content, /do not use it to bypass provider safeguards/);
  });
}

test('Godmode is absent from active discovery and retained only in local quarantine when present', () => {
  assert.equal(existsSync(path.join(root, '.claude/skills/godmode')), false);
  assert.equal(existsSync(path.join(root, '.claude/skills/security/godmode')), false);
  if (existsSync(quarantinedPath)) {
    assert.match(read('quarantine/red-team/godmode/SKILL.md'), /jailbreak/i);
  } else {
    const packager = read('scripts/package-release.py');
    assert.match(packager, /LOCAL_ONLY_DIRS = .*quarantine/s);
  }
});

test('Godmode is not registered as a canonical employee skill', () => {
  const index = read('ai-sa-employee/skills/skills.md').toLowerCase();
  assert.doesNotMatch(index, /godmode/);
});
