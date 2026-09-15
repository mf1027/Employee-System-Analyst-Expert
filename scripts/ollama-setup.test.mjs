import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const root = path.resolve(import.meta.dirname, '..');
const powershell = fs.readFileSync(path.join(root, 'scripts', 'setup.ps1'), 'utf8');
const bash = fs.readFileSync(path.join(root, 'scripts', 'setup.sh'), 'utf8');
const agents = fs.readFileSync(path.join(root, 'AGENTS.md'), 'utf8');
const claude = fs.readFileSync(path.join(root, 'CLAUDE.md'), 'utf8');
const employeeSkill = fs.readFileSync(path.join(root, 'ai-sa-employee', 'SKILL.md'), 'utf8');
const skillIndex = fs.readFileSync(path.join(root, 'ai-sa-employee', 'skills', 'skills.md'), 'utf8');

for (const [name, script] of [['PowerShell', powershell], ['Bash', bash]]) {
  test(`${name} setup checks explicit local Ollama model without mutating user state`, () => {
    assert.match(script, /OLLAMA_MODEL/);
    assert.match(script, /ollama/);
    assert.match(script, /ollama launch claude/);
    assert.match(script, /ollama launch codex/);
    assert.match(script, /ollama pull/);
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
