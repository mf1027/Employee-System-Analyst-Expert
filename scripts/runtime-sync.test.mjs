import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import {
  appendEvent,
  buildRuntimeEvent,
  classifyRuntimeStatus,
  eventFromInput,
  inferRuntimeIdentity,
  resolveVaultRoot,
  sanitizeEvent,
  updateMindmap,
} from './runtime-sync.mjs';

const CANONICAL_SKILL_PATHS = [
  '.claude/skills/plan-analysis/SKILL.md',
  'ai-sa-employee/skills/code-behavior-audit.md',
  'ai-sa-employee/skills/rollback-readiness-test.md',
  'ai-sa-employee/skills/ollama-agent-runtime.md',
  'ai-sa-employee/skills/soup-model-preparation.md',
];

test('identifies native and Ollama-backed Claude/Codex sessions independently', () => {
  assert.deepEqual(inferRuntimeIdentity({ host: 'claude', provider: 'native', model: 'claude' }), {
    host: 'claude',
    provider: 'native',
    launchMode: 'standard',
    model: 'claude',
  });
  assert.deepEqual(inferRuntimeIdentity({ host: 'codex', provider: 'ollama', model: 'gpt-oss:20b' }), {
    host: 'codex',
    provider: 'ollama',
    launchMode: 'ollama-native',
    model: 'gpt-oss:20b',
  });
});

test('classifies Ollama and Ponytail gates without manufacturing success', () => {
  assert.equal(classifyRuntimeStatus({ provider: 'unknown', vaultVerified: true, mindmapWriteAuthorized: true }), 'UNVERIFIED');
  assert.equal(classifyRuntimeStatus({
    provider: 'ollama',
    ollama: { installed: true, serviceReachable: true, modelConfigured: true, modelInstalled: true, contextVerified: true, toolCallingVerified: true },
    hostToolsVerified: true,
    hooksVerified: true,
    ponytailVerified: true,
    vaultVerified: true,
    mindmapWriteAuthorized: true,
  }), 'VERIFIED');
  assert.equal(classifyRuntimeStatus({
    provider: 'ollama',
    ollama: { installed: true, serviceReachable: true, modelConfigured: true, modelInstalled: true, contextVerified: false, toolCallingVerified: true },
    hostToolsVerified: true,
    hooksVerified: true,
    ponytailVerified: true,
    vaultVerified: true,
    mindmapWriteAuthorized: true,
  }), 'LIMITED');
  assert.equal(classifyRuntimeStatus({
    provider: 'native',
    hostToolsVerified: true,
    hooksVerified: false,
    ponytailVerified: false,
    vaultVerified: true,
    mindmapWriteAuthorized: false,
  }), 'BLOCKED');
});

test('event payload keeps four-mode identity and excludes sensitive hook fields', () => {
  const event = buildRuntimeEvent({
    host: 'claude',
    provider: 'ollama',
    model: 'gpt-oss:20b',
    sessionId: 'session-1',
    phase: 'postflight',
    status: 'VERIFIED',
    prompt: 'do not store this',
    toolResponse: { secret: 'do not store this' },
  });
  assert.equal(event.host, 'claude');
  assert.equal(event.provider, 'ollama');
  assert.equal(event.launch_mode, 'ollama-native');
  assert.equal(event.model, 'gpt-oss:20b');
  assert.equal(event.phase, 'postflight');
  assert.equal(event.overall_status, 'VERIFIED');
  assert.equal('prompt' in event, false);
  assert.equal('toolResponse' in event, false);
  assert.deepEqual(sanitizeEvent(event), event);
});

test('does not fall back when an explicit vault root is unavailable', () => {
  const fallback = fs.mkdtempSync(path.join(os.tmpdir(), 'runtime-sync-vault-'));
  assert.equal(resolveVaultRoot(fallback, path.join(fallback, 'missing-vault')), null);
});

test('uses MYPS_VAULT_ROOT when no explicit vault argument is supplied', () => {
  const configured = fs.mkdtempSync(path.join(os.tmpdir(), 'runtime-sync-configured-vault-'));
  const previous = process.env.MYPS_VAULT_ROOT;
  process.env.MYPS_VAULT_ROOT = configured;
  try {
    assert.equal(resolveVaultRoot(path.join(configured, 'repo'), null), configured);
  } finally {
    if (previous === undefined) delete process.env.MYPS_VAULT_ROOT;
    else process.env.MYPS_VAULT_ROOT = previous;
  }
});

test('runtime events include canonical skill paths and keep Ollama models off native events', () => {
  const previous = process.env.OLLAMA_MODEL;
  process.env.OLLAMA_MODEL = 'gpt-oss:20b';
  try {
    const native = eventFromInput({ host: 'claude', provider: 'native', phase: 'preflight', model: null }, {});
    assert.equal(native.model, null);
    assert.deepEqual(native.canonical_skill_paths, CANONICAL_SKILL_PATHS);

    const ollama = eventFromInput({ host: 'codex', provider: 'ollama', model: null, phase: 'preflight' }, {});
    assert.equal(ollama.model, 'gpt-oss:20b');
    assert.deepEqual(ollama.canonical_skill_paths, CANONICAL_SKILL_PATHS);
  } finally {
    if (previous === undefined) delete process.env.OLLAMA_MODEL;
    else process.env.OLLAMA_MODEL = previous;
  }
});

test('records an event and atomically projects the latest status into the mind-map', () => {
  const vault = fs.mkdtempSync(path.join(os.tmpdir(), 'runtime-sync-'));
  const architecture = path.join(vault, '01 - Application Architecture');
  fs.mkdirSync(architecture, { recursive: true });
  fs.writeFileSync(path.join(architecture, 'Agent Tooling Mindmap.md'), '# Agent Tooling Mindmap\n\n## Change log\n', 'utf8');
  const event = buildRuntimeEvent({ host: 'codex', provider: 'native', phase: 'postflight', status: 'VERIFIED' });
  appendEvent(vault, event);
  updateMindmap(vault, event);
  const ledger = fs.readFileSync(path.join(architecture, 'Agent Runtime Sync Ledger.jsonl'), 'utf8');
  const map = fs.readFileSync(path.join(architecture, 'Agent Tooling Mindmap.md'), 'utf8');
  assert.equal(JSON.parse(ledger).provider, 'native');
  assert.match(map, /codex\/native/);
  assert.match(map, /Overall status: VERIFIED/);
});
