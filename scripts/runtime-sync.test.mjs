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
  runRuntimeSync,
  sanitizeEvent,
  updateMindmap,
  validateRuntimeEvidence,
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

test('requires verified canonical skill paths before any runtime can be VERIFIED', () => {
  assert.equal(classifyRuntimeStatus({
    provider: 'native',
    hostToolsVerified: true,
    hooksVerified: true,
    ponytailVerified: true,
    vaultVerified: true,
    mindmapWriteAuthorized: true,
    skillPathsVerified: false,
  }), 'UNVERIFIED');
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

function verifiedCodexOllamaEvidence(model = 'qwen3-coder:30b') {
  return {
    host: 'codex',
    provider: 'ollama',
    model,
    ollama: {
      host: 'http://localhost:11434',
      model,
      explicitModelConfigured: true,
      serviceReachable: true,
      localModelVerified: true,
      contextCapacity: 262144,
      contextVerified: true,
      toolCallingVerified: true,
      status: 'VERIFIED',
    },
    host_tool: { read_only_completed: true },
    ponytail: { installed: true, hook_trusted: true, full_mode_applied: true },
    soup_status: 'NOT_APPLICABLE',
    prompt: 'must never reach the ledger',
    tool_response: { secret: 'must never reach the ledger' },
  };
}

function createVault() {
  const vault = fs.mkdtempSync(path.join(os.tmpdir(), 'runtime-sync-contract-'));
  const architecture = path.join(vault, '01 - Application Architecture');
  fs.mkdirSync(architecture, { recursive: true });
  fs.writeFileSync(path.join(architecture, 'Agent Tooling Mindmap.md'), '# Agent Tooling Mindmap\n\n## Change log\n', 'utf8');
  return vault;
}

test('requires matching independently verified evidence instead of caller-supplied VERIFIED status', () => {
  const evidence = verifiedCodexOllamaEvidence();
  const result = validateRuntimeEvidence({ host: 'codex', provider: 'ollama', model: 'qwen3-coder:30b' }, evidence);
  assert.equal(result.hostToolsVerified, true);
  assert.equal(result.hooksVerified, true);
  assert.equal(result.ponytailVerified, true);
  assert.equal(result.ollama.status, 'VERIFIED');
  assert.equal('prompt' in result.summary, false);
  assert.equal('tool_response' in result.summary, false);

  const credentialedHost = validateRuntimeEvidence({ host: 'codex', provider: 'ollama', model: 'qwen3-coder:30b' }, {
    ...evidence,
    ollama: { ...evidence.ollama, host: 'http://operator:secret@localhost:11434' },
  });
  assert.equal(credentialedHost.summary.ollama.host, 'http://localhost:11434');

  assert.throws(
    () => validateRuntimeEvidence({ host: 'codex', provider: 'ollama', model: 'gpt-oss:20b' }, evidence),
    /model does not match/,
  );
  assert.throws(
    () => validateRuntimeEvidence({ host: 'codex', provider: 'ollama', model: 'qwen3-coder:30b' }, {
      ...evidence,
      ollama: { ...evidence.ollama, status: 'UNVERIFIED' },
    }),
    /Ollama verifier status must be VERIFIED/,
  );
});

test('dry-run validates evidence without appending a ledger event or changing the mind-map', async () => {
  const vault = createVault();
  const evidencePath = path.join(vault, 'evidence.json');
  fs.writeFileSync(evidencePath, JSON.stringify(verifiedCodexOllamaEvidence()), 'utf8');
  const architecture = path.join(vault, '01 - Application Architecture');
  const mapPath = path.join(architecture, 'Agent Tooling Mindmap.md');
  const before = fs.readFileSync(mapPath, 'utf8');
  const output = [];

  const result = await runRuntimeSync([
    '--postflight', '--dry-run', '--authorize-mindmap', '--host', 'codex', '--provider', 'ollama',
    '--model', 'qwen3-coder:30b', '--vault', vault, '--evidence', evidencePath,
  ], { writeOutput: (line) => output.push(line) });

  assert.equal(result.event.overall_status, 'VERIFIED');
  assert.equal(fs.existsSync(path.join(architecture, 'Agent Runtime Sync Ledger.jsonl')), false);
  assert.equal(fs.readFileSync(mapPath, 'utf8'), before);
  assert.equal(output.length, 1);
  assert.match(output[0], /"dry_run":true/);
});

test('postflight leaves the mind-map byte-identical until --authorize-mindmap is supplied', async () => {
  const vault = createVault();
  const evidencePath = path.join(vault, 'evidence.json');
  fs.writeFileSync(evidencePath, JSON.stringify(verifiedCodexOllamaEvidence('gpt-oss:20b')), 'utf8');
  const architecture = path.join(vault, '01 - Application Architecture');
  const mapPath = path.join(architecture, 'Agent Tooling Mindmap.md');
  const before = fs.readFileSync(mapPath, 'utf8');
  const args = ['--postflight', '--host', 'codex', '--provider', 'ollama', '--model', 'gpt-oss:20b', '--vault', vault, '--evidence', evidencePath];

  const blocked = await runRuntimeSync(args, { writeOutput: () => {} });
  assert.equal(blocked.event.overall_status, 'BLOCKED');
  assert.equal(fs.readFileSync(mapPath, 'utf8'), before);

  const authorized = await runRuntimeSync([...args, '--authorize-mindmap'], { writeOutput: () => {} });
  assert.equal(authorized.event.overall_status, 'VERIFIED');
  assert.match(fs.readFileSync(mapPath, 'utf8'), /Overall status: VERIFIED/);
});

test('vault verification reports vault readiness, not live runtime verification', async () => {
  const vault = createVault();
  const output = [];
  const result = await runRuntimeSync(['--verify', '--vault', vault, '--json'], {
    writeOutput: (line) => output.push(line),
  });

  assert.equal(result.exitCode, 0);
  assert.equal(result.result.status, 'VAULT_READY');
  assert.equal(result.result.scope, 'vault-only');
  assert.match(output[0], /VAULT_READY/);
});
