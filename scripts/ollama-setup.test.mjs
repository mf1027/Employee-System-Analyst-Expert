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
    assert.match(script, /Ponytail runtime verified/);
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

test('repository runtime instructions preserve canonical skill ownership', () => {
  for (const document of [agents, claude, employeeSkill, skillIndex]) {
    assert.match(document, /OLLAMA_MODEL/);
    assert.match(document, /Ollama/);
    assert.match(document, /rollback-readiness-test\.md/);
    assert.match(document, /Ponytail/);
  }
  assert.match(agents, /\.claude\/skills\/plan-analysis\/SKILL\.md/);
  assert.match(agents, /code-behavior-audit\.md/);
  assert.doesNotMatch(agents, /C:\\Users\\Msi\\\.codex\\skills/);
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

test('Soup source contract remains pinned to the inspected archive', () => {
  assert.equal(SOUP_VERSION, '0.75.0');
  assert.equal(SOUP_SHA256, '61AD531DA5C4779E50390B6589202DD1EBA69D93A30156441542DD185C94F029');
});
