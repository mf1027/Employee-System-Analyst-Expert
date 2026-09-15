import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import {
  appendEvent,
  buildRuntimeEvent,
  classifyRuntimeStatus,
  inferRuntimeIdentity,
  resolveVaultRoot,
  sanitizeEvent,
  updateMindmap,
} from './runtime-sync.mjs';

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
