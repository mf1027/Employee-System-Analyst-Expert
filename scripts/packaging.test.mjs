import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const shellFiles = [
  ...fs.readdirSync(path.join(root, 'scripts')).filter((name) => name.endsWith('.sh')).map((name) => path.join(root, 'scripts', name)),
  ...fs.readdirSync(path.join(root, '.claude/hooks')).filter((name) => name.endsWith('.sh')).map((name) => path.join(root, '.claude/hooks', name)),
];

test('every packaged Bash script has LF endings and parses', () => {
  for (const file of shellFiles) {
    const bytes = fs.readFileSync(file);
    assert.equal(bytes.includes(Buffer.from('\r')), false, `${path.relative(root, file)} contains CR characters`);
    execFileSync('bash', ['-n', file]);
  }
});

test('memory reminder hook emits informational context and never decides permission', () => {
  const gate = path.join(root, '.claude/memory/gate');
  fs.rmSync(gate, { recursive: true, force: true });
  try {
    const payload = JSON.stringify({ session_id: '../../unsafe/id', tool_name: 'Write', tool_input: { file_path: 'x' } });
    const output = execFileSync('bash', [path.join(root, '.claude/hooks/memory-gate-check.sh')], {
      cwd: root, input: payload, encoding: 'utf8',
    });
    assert.notEqual(output.trim(), '');
    const result = JSON.parse(output);
    assert.equal('permissionDecision' in result, false);
    assert.equal('permissionDecision' in result.hookSpecificOutput, false);
    assert.equal(result.hookSpecificOutput.hookEventName, 'PreToolUse');
    assert.match(result.systemMessage, /reminder only/i);
  } finally {
    fs.rmSync(gate, { recursive: true, force: true });
  }
});

test('backup shell wrapper creates a verified archive in a disposable destination', () => {
  const destination = fs.mkdtempSync(path.join(os.tmpdir(), 'employee-backup-wrapper-'));
  execFileSync('bash', [path.join(root, 'scripts/backup.sh'), destination], { cwd: root, env: { ...process.env, KEEP: '2' } });
  const archives = fs.readdirSync(destination).filter((name) => name.endsWith('.zip'));
  assert.equal(archives.length, 1);
  execFileSync('python', ['-c', 'import sys,zipfile; z=zipfile.ZipFile(sys.argv[1]); assert z.testzip() is None; assert "BACKUP-MANIFEST.json" in z.namelist()', path.join(destination, archives[0])]);
  fs.rmSync(destination, { recursive: true, force: true });
});

test('setup scripts use lockfile installs and project-local Python dependencies', () => {
  for (const name of ['scripts/setup.sh', 'scripts/setup.ps1']) {
    const content = fs.readFileSync(path.join(root, name), 'utf8');
    assert.match(content, /npm ci/);
    assert.match(content, /requirements-docs\.txt/);
    assert.doesNotMatch(content, /npm install|pip install chromadb|pip install defusedxml/i);
  }
  const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  const lock = JSON.parse(fs.readFileSync(path.join(root, 'package-lock.json'), 'utf8'));
  assert.equal(pkg.engines.node, '>=20.19.0');
  assert.deepEqual(pkg.dependencies, { '@opendataloader/pdf': '2.4.7' });
  assert.equal(lock.packages[''].version, pkg.version);
  assert.equal(lock.packages[''].engines.node, pkg.engines.node);
  assert.equal(lock.packages['node_modules/@opendataloader/pdf'].version, '2.4.7');
  const requirements = fs.readFileSync(path.join(root, 'requirements-docs.txt'), 'utf8');
  assert.match(requirements, /pypdf==5\.9\.0/);
  assert.doesNotMatch(requirements, /latest|>=|~/i);
});

test('release packager excludes local memory, red-team payloads and runtime caches', () => {
  const out = fs.mkdtempSync(path.join(os.tmpdir(), 'employee-release-test-'));
  const archive = path.join(out, 'release.zip');
  execFileSync('python', [path.join(root, 'scripts/package-release.py'), '--root', root, '--output', archive]);
  const listing = execFileSync('python', ['-c', 'import sys,zipfile; print("\\n".join(zipfile.ZipFile(sys.argv[1]).namelist()))', archive], { encoding: 'utf8' });
  assert.match(listing, /portable-agent\/AGENT\.md/);
  assert.doesNotMatch(listing, /memory\/memory\.md|memory\/archive\/|memory\/clients\/|quarantine\/red-team\/|\.claude-mem\/|node_modules\/|\.venv\/|temp\//);
  fs.rmSync(out, { recursive: true, force: true });
});
