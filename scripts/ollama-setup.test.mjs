import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { DEFAULT_MIN_CONTEXT_TOKENS, isCloudModel, verifyOllama } from './verify-ollama-runtime.mjs';
import { SOUP_SHA256, SOUP_VERSION } from './soup-setup.mjs';

const root = path.resolve(import.meta.dirname, '..');
const powershell = fs.readFileSync(path.join(root, 'scripts', 'setup.ps1'), 'utf8');
const bash = fs.readFileSync(path.join(root, 'scripts', 'setup.sh'), 'utf8');
const agents = fs.readFileSync(path.join(root, 'AGENTS.md'), 'utf8');
const claude = fs.readFileSync(path.join(root, 'CLAUDE.md'), 'utf8');
const employeeSkill = fs.readFileSync(path.join(root, 'ai-sa-employee', 'SKILL.md'), 'utf8');
const skillIndex = fs.readFileSync(path.join(root, 'ai-sa-employee', 'skills', 'skills.md'), 'utf8');
const runtimeSkill = fs.readFileSync(path.join(root, 'ai-sa-employee', 'skills', 'ollama-agent-runtime.md'), 'utf8');
const soupSkill = fs.readFileSync(path.join(root, 'ai-sa-employee', 'skills', 'soup-model-preparation.md'), 'utf8');
const runtimeWrapper = fs.readFileSync(path.join(root, '.claude', 'commands', 'ollama-agent-runtime.md'), 'utf8');
const soupWrapper = fs.readFileSync(path.join(root, '.claude', 'commands', 'soup-model-preparation.md'), 'utf8');
const claudeSettings = fs.readFileSync(path.join(root, '.claude', 'settings.json'), 'utf8');

for (const [name, script] of [['PowerShell', powershell], ['Bash', bash]]) {
  test(`${name} setup checks explicit local Ollama model without mutating user state`, () => {
    assert.match(script, /OLLAMA_MODEL/);
    assert.match(script, /ollama/);
    assert.match(script, /ollama launch claude/);
    assert.match(script, /ollama launch codex/);
    assert.match(script, /ollama pull/);
    assert.match(script, /verify-ollama-runtime\.mjs/);
    assert.match(script, /Context capacity/);
    assert.match(script, /Tool calling verified/);
    assert.match(script, /Ollama installed/);
    assert.match(script, /Ollama service reachable/);
    assert.match(script, /Explicit model configured/);
    assert.match(script, /installed locally/);
    assert.match(script, /Claude host available/);
    assert.match(script, /Codex host available/);
    assert.match(script, /Ponytail installed\/enabled/);
    assert.match(script, /Ponytail marketplace available/);
    assert.match(script, /Ponytail hook trust verified by fresh-host smoke/);
    assert.doesNotMatch(script, /Ponytail runtime verified/);
    assert.match(script, /RUNTIME_SYNC_PROVIDER/);
    assert.match(script, /runtime-sync\.mjs/);
    assert.match(script, /cloud/i);
    assert.match(script, /never|not automatic|do not/i);
  });
}

test('setup exposes explicit isolated Soup installation without automatic training or deployment', () => {
  assert.match(powershell, /InstallSoup/);
  assert.match(powershell, /InstallSoupTraining/);
  assert.match(powershell, /SoupArchivePath/);
  assert.match(bash, /--install-soup/);
  assert.match(bash, /--install-soup-training/);
  assert.match(bash, /--soup-archive/);
  for (const script of [powershell, bash]) {
    assert.match(script, /soup-setup\.mjs/);
    assert.doesNotMatch(script, /soup\s+(train|export|deploy)\b/i);
    assert.doesNotMatch(script, /ollama\s+create\b/i);
  }
});

test('setup delegates Ollama capability checks to the shared verifier', () => {
  for (const script of [powershell, bash]) {
    assert.match(script, /verify-ollama-runtime\.mjs/);
    assert.doesNotMatch(script, /api\/tags|ollama\s+ls/i);
  }
});

test('PowerShell setup discovers conventional Windows Ollama installs outside PATH', () => {
  assert.match(powershell, /OLLAMA_EXE/);
  assert.match(powershell, /LOCALAPPDATA/);
  assert.match(powershell, /Programs\\Ollama\\ollama\.exe/);
});

test('repository runtime instructions preserve canonical skill ownership', () => {
  for (const document of [agents, claude, employeeSkill, skillIndex]) {
    assert.match(document, /OLLAMA_MODEL/);
    assert.match(document, /Ollama/);
    assert.match(document, /rollback-readiness-test\.md/);
    assert.match(document, /Ponytail/);
  }
  assert.match(agents, /\.claude\/skills\/plan-analysis\/SKILL\.md/);
  assert.match(agents, /code-behavior-audit\.md/);
  assert.match(agents, /ai-sa-employee\/skills\/skills\.md/);
  assert.doesNotMatch(agents, /C:\\Users\\Msi\\\.codex\\skills/);
});

test('flat canonical skills and Claude wrappers remain in parity', () => {
  const skillDir = path.join(root, 'ai-sa-employee', 'skills');
  const wrapperDir = path.join(root, '.claude', 'commands');
  const skills = fs.readdirSync(skillDir)
    .filter((name) => name.endsWith('.md') && name !== 'skills.md')
    .map((name) => name.slice(0, -3))
    .sort();
  const wrappers = fs.readdirSync(wrapperDir)
    .filter((name) => name.endsWith('.md'))
    .map((name) => name.slice(0, -3))
    .sort();
  const aliases = new Set(['board', 'capture-workflow', 'check-improvements', 'check-memory']);
  assert.deepEqual(wrappers.filter((name) => !aliases.has(name)), skills);
  assert.match(agents, /rollback-readiness-test\.md/);
  assert.match(claude, /rollback-readiness-test\.md/);
  for (const skill of skills) assert.equal(skillIndex.includes(`\`${skill}.md\``), true, `${skill} is not indexed`);
  assert.equal(fs.existsSync(path.join(root, '.codex', 'skills', 'ponytail')), false);
  assert.equal(fs.existsSync(path.join(skillDir, 'ponytail.md')), false);
});

test('runtime and Soup skills are discoverable by both host entry points', () => {
  for (const skill of [runtimeSkill, soupSkill]) {
    assert.match(skill, /^---\r?\nname: [a-z0-9-]+/);
    assert.match(skill, /Use when/i);
    assert.match(skill, /approval|approved/i);
  }
  assert.match(runtimeWrapper, /ollama-agent-runtime\.md/);
  assert.match(soupWrapper, /soup-model-preparation\.md/);
  assert.match(runtimeSkill, /Mind-map sync/);
  assert.match(soupSkill, /soup advise/);
  assert.match(soupSkill, /global Soup first/i);
  assert.match(soupSkill, /duplicate/i);
});

test('runtime documentation requires evidence dry-runs and explicit mind-map authorization', () => {
  for (const document of [agents, claude, fs.readFileSync(path.join(root, 'README.md'), 'utf8'), runtimeSkill]) {
    assert.match(document, /dry-run/);
    assert.match(document, /authorize-mindmap/);
    assert.match(document, /VAULT_READY/);
  }
  assert.match(runtimeSkill, /--evidence/);
  assert.match(runtimeSkill, /--status VERIFIED.*rejected/);
  for (const document of [agents, runtimeSkill]) assert.match(document, /session_end/);
});

test('Claude hooks are repository-owned and Codex support is checked honestly', () => {
  const claudeConfig = JSON.parse(claudeSettings);
  assert.equal((claudeSettings.match(/"PostToolUse"/g) || []).length, 1);
  assert.ok(claudeConfig.hooks.SessionStart);
  assert.ok(claudeConfig.hooks.UserPromptSubmit);
  assert.ok(claudeConfig.hooks.PostToolUse);
  assert.ok(claudeConfig.hooks.Stop);
  assert.match(JSON.stringify(claudeConfig), /runtime-sync\.mjs/);
  const stopCommands = claudeConfig.hooks.Stop.flatMap((group) => group.hooks.map((hook) => hook.command));
  assert.equal(stopCommands.length, 1);
  assert.match(stopCommands[0], /--hook --host claude --phase session_end/);
  assert.doesNotMatch(claudeSettings, /--phase postflight/);
  assert.match(agents, /Codex project-hook support.*verified|explicit.*runtime-sync/i);
  assert.match(powershell, /Codex project-hook support/);
  assert.match(bash, /Codex project-hook support/);
  for (const document of [agents, claude]) {
    assert.match(document, /Claude\/native|Claude, Ollama-backed Claude|four separate verification/i);
    assert.match(document, /RUNTIME_SYNC_PROVIDER/);
    assert.match(document, /Agent Tooling Mindmap/);
  }
});

test('project Claude configuration has no historical automatic permissions or machine-specific secrets', () => {
  const claudeConfig = JSON.parse(claudeSettings);
  assert.deepEqual(claudeConfig.permissions?.allow ?? [], []);
  assert.deepEqual(claudeConfig.permissions?.additionalDirectories ?? [], []);
  assert.doesNotMatch(claudeSettings, /C:\\Users\\khen|sqlcmd|(?:^|[^a-z])password(?:[^a-z]|$)|api[_-]?key/i);
  assert.ok(claudeConfig.hooks.SessionStart);
  assert.ok(claudeConfig.hooks.Stop);
});

function fakeFetch(responses) {
  return async (url) => {
    const body = responses.shift();
    assert.ok(body, `unexpected request: ${url}`);
    return { ok: true, status: 200, json: async () => body };
  };
}

test('Ollama verifier requires local model, context, and tool calling', async () => {
  const result = await verifyOllama({
    host: 'http://localhost:11434',
    model: 'qwen-local:latest',
    fetchImpl: fakeFetch([
      { models: [{ name: 'qwen-local:latest' }] },
      { model_info: { 'general.context_length': DEFAULT_MIN_CONTEXT_TOKENS } },
      { message: { tool_calls: [{ function: { name: 'read_only_probe', arguments: { path: '.' } } }] } },
    ]),
  });
  assert.equal(result.status, 'VERIFIED');
  assert.equal(result.explicitModelConfigured, true);
  assert.equal(result.serviceReachable, true);
  assert.equal(result.contextVerified, true);
  assert.equal(result.toolCallingVerified, true);
  assert.deepEqual(result.availableLocalModels, ['qwen-local:latest']);
});

test('Ollama verifier reports safe local model names when selection is missing', async () => {
  const result = await verifyOllama({
    model: '',
    fetchImpl: fakeFetch([{ models: [{ name: 'gpt-oss:20b' }, { name: 'qwen3-coder:30b' }] }]),
  });
  assert.equal(result.status, 'BLOCKED');
  assert.deepEqual(result.availableLocalModels, ['gpt-oss:20b', 'qwen3-coder:30b']);
});

test('Ollama verifier fails closed for cloud and limited models', async () => {
  assert.equal(isCloudModel('model:7b-cloud'), true);
  const cloud = await verifyOllama({ model: 'model:7b-cloud', fetchImpl: async () => { throw new Error('must not call API'); } });
  assert.equal(cloud.status, 'UNVERIFIED');

  const limited = await verifyOllama({
    model: 'small:latest',
    fetchImpl: fakeFetch([
      { models: [{ name: 'small:latest' }] },
      { model_info: { 'general.context_length': 8192 } },
      { message: { tool_calls: [{ function: { name: 'read_only_probe', arguments: { path: '.' } } }] } },
    ]),
  });
  assert.equal(limited.status, 'LIMITED');
});

test('Ollama verifier passes an abort signal to every request', async () => {
  let requestsWithSignal = 0;
  const result = await verifyOllama({
    model: 'signal-local:latest',
    requestTimeoutMs: 100,
    fetchImpl: async (_url, options) => {
      if (options?.signal) requestsWithSignal += 1;
      if (requestsWithSignal === 1) return { ok: true, status: 200, json: async () => ({ models: [{ name: 'signal-local:latest' }] }) };
      if (requestsWithSignal === 2) return { ok: true, status: 200, json: async () => ({ model_info: { 'general.context_length': DEFAULT_MIN_CONTEXT_TOKENS } }) };
      return { ok: true, status: 200, json: async () => ({ message: { tool_calls: [{ function: { name: 'read_only_probe', arguments: { path: '.' } } }] } }) };
    },
  });

  assert.equal(result.status, 'VERIFIED');
  assert.equal(requestsWithSignal, 3);
});

test('Soup source contract remains pinned to the inspected archive', () => {
  assert.equal(SOUP_VERSION, '0.75.0');
  assert.equal(SOUP_SHA256, '61AD531DA5C4779E50390B6589202DD1EBA69D93A30156441542DD185C94F029');
});
