#!/usr/bin/env node

import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

export const MIN_CONTEXT_TOKENS = 65536;
export const CANONICAL_SKILL_PATHS = [
  '.claude/skills/plan-analysis/SKILL.md',
  'ai-sa-employee/skills/code-behavior-audit.md',
  'ai-sa-employee/skills/rollback-readiness-test.md',
  'ai-sa-employee/skills/ollama-agent-runtime.md',
  'ai-sa-employee/skills/soup-model-preparation.md',
];

function normalizeHost(host) {
  if (!['claude', 'codex'].includes(host)) throw new Error(`unsupported host: ${host}`);
  return host;
}

function normalizeProvider(provider) {
  if (!['native', 'ollama'].includes(provider)) throw new Error(`unsupported provider: ${provider}`);
  return provider;
}

export function inferRuntimeIdentity({ host, provider, model = null }) {
  const normalizedHost = normalizeHost(host);
  const normalizedProvider = normalizeProvider(provider);
  return {
    host: normalizedHost,
    provider: normalizedProvider,
    launchMode: normalizedProvider === 'ollama' ? 'ollama-native' : 'standard',
    model: model || null,
  };
}

export function classifyRuntimeStatus({
  provider,
  ollama = {},
  hostToolsVerified = false,
  hooksVerified = false,
  ponytailVerified = false,
  vaultVerified = false,
  mindmapWriteAuthorized = false,
}) {
  if (!['native', 'ollama'].includes(provider)) return 'UNVERIFIED';
  if (!vaultVerified || !mindmapWriteAuthorized) return 'BLOCKED';
  if (!hostToolsVerified || !hooksVerified || !ponytailVerified) return 'UNVERIFIED';
  if (provider === 'ollama') {
    const normalizedOllama = {
      installed: ollama.installed ?? ollama.serviceReachable,
      serviceReachable: ollama.serviceReachable,
      modelConfigured: ollama.modelConfigured ?? ollama.explicitModelConfigured,
      modelInstalled: ollama.modelInstalled ?? ollama.localModelVerified,
      toolCallingVerified: ollama.toolCallingVerified,
      contextVerified: ollama.contextVerified,
    };
    const required = ['installed', 'serviceReachable', 'modelConfigured', 'modelInstalled', 'toolCallingVerified'];
    if (required.some((key) => normalizedOllama[key] !== true)) return 'UNVERIFIED';
    if (normalizedOllama.contextVerified !== true) return 'LIMITED';
  }
  return 'VERIFIED';
}

export function sanitizeEvent(event) {
  const safe = { ...event };
  delete safe.prompt;
  delete safe.toolResponse;
  delete safe.tool_input;
  delete safe.tool_response;
  return safe;
}

export function buildRuntimeEvent({
  host,
  provider,
  model = null,
  sessionId = null,
  phase,
  status = 'UNVERIFIED',
  skillPaths = CANONICAL_SKILL_PATHS,
  mindmapPath = null,
  ponytailStatus = 'UNVERIFIED',
  soupStatus = 'NOT_APPLICABLE',
  ollama = null,
  evidenceSummary = null,
  mindmapStatus = 'NOT_REQUESTED',
  ...ignored
}) {
  const identity = inferRuntimeIdentity({ host, provider, model });
  return sanitizeEvent({
    schema_version: 1,
    event_id: crypto.randomUUID(),
    timestamp_utc: new Date().toISOString(),
    host: identity.host,
    provider: identity.provider,
    launch_mode: identity.launchMode,
    model: identity.model,
    session_id: sessionId || null,
    repository: 'Employee-System-Analyst-Expert',
    phase,
    canonical_skill_paths: [...new Set([...CANONICAL_SKILL_PATHS, ...(skillPaths || [])])],
    mindmap_path: mindmapPath,
    ollama_status: identity.provider === 'ollama' ? (ollama || {}) : 'NOT_APPLICABLE',
    ponytail_status: ponytailStatus,
    soup_status: soupStatus,
    evidence: evidenceSummary,
    mindmap_status: mindmapStatus,
    overall_status: status,
  });
}

export function parseArgs(argv) {
  const args = {
    command: 'help', host: null, provider: null, model: null, phase: null, vault: null,
    evidence: null, dryRun: false, authorizeMindmap: false, deprecatedStatus: null,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const value = argv[i];
    if (value === '--hook') args.command = 'hook';
    else if (value === '--preflight') args.command = 'preflight';
    else if (value === '--postflight') args.command = 'postflight';
    else if (value === '--verify') args.command = 'verify';
    else if (value === '--json') args.json = true;
    else if (value === '--dry-run') args.dryRun = true;
    else if (value === '--authorize-mindmap') args.authorizeMindmap = true;
    else if (value === '--host') args.host = argv[++i];
    else if (value === '--provider') args.provider = argv[++i];
    else if (value === '--model') args.model = argv[++i];
    else if (value === '--phase') args.phase = argv[++i];
    else if (value === '--status') args.deprecatedStatus = argv[++i];
    else if (value === '--vault') args.vault = argv[++i];
    else if (value === '--evidence') args.evidence = argv[++i];
  }
  return args;
}

function readEvidence(evidencePath) {
  if (!evidencePath) return null;
  let raw;
  try { raw = fs.readFileSync(path.resolve(evidencePath), 'utf8'); }
  catch (error) { throw new Error(`evidence file cannot be read: ${error.message}`); }
  try { return JSON.parse(raw); }
  catch { throw new Error('evidence file must contain valid JSON'); }
}

function requireEvidence(condition, message) {
  if (!condition) throw new Error(`runtime evidence invalid: ${message}`);
}

function safeHost(host) {
  if (typeof host !== 'string' || !host) return null;
  try {
    const parsed = new URL(host);
    return `${parsed.protocol}//${parsed.host}`;
  } catch {
    return null;
  }
}

function safeOllamaSummary(ollama) {
  return {
    host: safeHost(ollama.host),
    model: ollama.model || null,
    status: ollama.status || 'UNVERIFIED',
    explicit_model_configured: ollama.explicitModelConfigured === true,
    service_reachable: ollama.serviceReachable === true,
    local_model_verified: ollama.localModelVerified === true,
    context_capacity: Number.isFinite(ollama.contextCapacity) ? ollama.contextCapacity : null,
    context_verified: ollama.contextVerified === true,
    tool_calling_verified: ollama.toolCallingVerified === true,
  };
}

export function validateRuntimeEvidence(identity, evidence) {
  requireEvidence(evidence && typeof evidence === 'object' && !Array.isArray(evidence), 'a JSON object is required');
  requireEvidence(evidence.host === identity.host, 'host does not match command identity');
  requireEvidence(evidence.provider === identity.provider, 'provider does not match command identity');
  if (identity.model) requireEvidence(evidence.model === identity.model, 'model does not match command identity');

  const soupStatus = evidence.soup_status || 'NOT_APPLICABLE';
  requireEvidence(
    soupStatus === 'NOT_APPLICABLE' || evidence.soup_in_scope === true,
    'Soup activity requires explicit soup_in_scope: true',
  );
  const hostToolsVerified = evidence.host_tool?.read_only_completed === true;
  const hooksVerified = evidence.ponytail?.hook_trusted === true;
  const ponytailVerified = evidence.ponytail?.installed === true
    && evidence.ponytail?.hook_trusted === true
    && evidence.ponytail?.full_mode_applied === true;
  let ollama = {};
  if (identity.provider === 'ollama') {
    requireEvidence(evidence.ollama && typeof evidence.ollama === 'object', 'raw Ollama verifier result is required');
    requireEvidence(evidence.ollama.status === 'VERIFIED', 'Ollama verifier status must be VERIFIED');
    requireEvidence(evidence.ollama.model === identity.model, 'Ollama verifier model does not match command identity');
    ollama = evidence.ollama;
  }
  return {
    hostToolsVerified,
    hooksVerified,
    ponytailVerified,
    soupStatus,
    ollama,
    summary: {
      host_tool: { read_only_completed: hostToolsVerified },
      ponytail: {
        installed: evidence.ponytail?.installed === true,
        hook_trusted: hooksVerified,
        full_mode_applied: evidence.ponytail?.full_mode_applied === true,
      },
      ollama: identity.provider === 'ollama' ? safeOllamaSummary(ollama) : 'NOT_APPLICABLE',
      soup_status: soupStatus,
    },
  };
}

function repoRootFromScript() {
  return path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
}

export function resolveVaultRoot(repoRoot, explicitVault) {
  const configuredVault = explicitVault ?? process.env.MYPS_VAULT_ROOT;
  if (configuredVault) {
    const explicit = path.resolve(configuredVault);
    return fs.existsSync(explicit) ? explicit : null;
  }
  const sibling = path.join(path.dirname(repoRoot), 'Obsidian', 'MYPS_Obsidian_Vault', 'MYPS');
  return fs.existsSync(sibling) ? path.resolve(sibling) : null;
}

function readStdin() {
  if (!process.stdin.isTTY) {
    try { return fs.readFileSync(0, 'utf8'); } catch { return ''; }
  }
  return '';
}

function parseHookInput(raw) {
  if (!raw.trim()) return {};
  try { return JSON.parse(raw); } catch { return {}; }
}

function ledgerPath(vaultRoot) {
  return path.join(vaultRoot, '01 - Application Architecture', 'Agent Runtime Sync Ledger.jsonl');
}

function mindmapPath(vaultRoot) {
  return path.join(vaultRoot, '01 - Application Architecture', 'Agent Tooling Mindmap.md');
}

function acquireLock(target) {
  const lock = `${target}.lock`;
  const started = Date.now();
  while (Date.now() - started < 5000) {
    try {
      const fd = fs.openSync(lock, 'wx');
      fs.writeFileSync(fd, JSON.stringify({ pid: process.pid, created: new Date().toISOString() }));
      fs.closeSync(fd);
      return () => fs.rmSync(lock, { force: true });
    } catch {
      try {
        if (Date.now() - fs.statSync(lock).mtimeMs > 120000) fs.rmSync(lock, { force: true });
      } catch { /* another writer owns or removed the lock */ }
    }
  }
  throw new Error(`runtime sync lock timeout: ${lock}`);
}

export function appendEvent(vaultRoot, event) {
  const target = ledgerPath(vaultRoot);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  const release = acquireLock(target);
  try { fs.appendFileSync(target, `${JSON.stringify(sanitizeEvent(event))}${os.EOL}`, 'utf8'); }
  finally { release(); }
  return target;
}

export function updateMindmap(vaultRoot, event) {
  const target = mindmapPath(vaultRoot);
  const current = fs.readFileSync(target, 'utf8');
  const start = '<!-- RUNTIME-SYNC-STATUS:START -->';
  const end = '<!-- RUNTIME-SYNC-STATUS:END -->';
  const section = [
    start,
    '## Latest runtime synchronization',
    '',
    `- Last event: ${event.timestamp_utc}`,
    `- Host/provider: ${event.host}/${event.provider}`,
    `- Launch mode: ${event.launch_mode}`,
    `- Model: ${event.model || 'not reported'}`,
    `- Ponytail: ${event.ponytail_status}`,
    `- Soup: ${event.soup_status}`,
    `- Overall status: ${event.overall_status}`,
    end,
  ].join('\n');
  const pattern = new RegExp(`${start}[\\s\\S]*?${end}`);
  const next = pattern.test(current) ? current.replace(pattern, section) : current.replace(/\n## Change log\b/, `\n${section}\n\n## Change log`);
  if (next === current) throw new Error('Agent Tooling Mindmap has no writable runtime-status location');
  const release = acquireLock(target);
  const temporary = `${target}.${process.pid}.tmp`;
  try {
    fs.writeFileSync(temporary, next, 'utf8');
    fs.renameSync(temporary, target);
  } finally {
    release();
    try { fs.rmSync(temporary, { force: true }); } catch { /* already renamed */ }
  }
  return target;
}

export function eventFromInput(args, input, { vaultVerified = false, evidence = null } = {}) {
  const host = args.host || (input.host === 'claude' || input.host === 'codex' ? input.host : null);
  const provider = args.provider || input.provider || process.env.RUNTIME_SYNC_PROVIDER || 'native';
  if (!host) throw new Error('host is required: use --host claude or --host codex');
  const phase = args.phase || input.hook_event_name || 'unknown';
  const model = args.model || input.model || (provider === 'ollama' ? process.env.OLLAMA_MODEL : process.env.NATIVE_MODEL) || null;
  const identity = inferRuntimeIdentity({ host, provider, model });
  const evidenceResult = evidence ? validateRuntimeEvidence(identity, evidence) : {
    hostToolsVerified: false,
    hooksVerified: false,
    ponytailVerified: false,
    soupStatus: 'NOT_APPLICABLE',
    ollama: {},
    summary: null,
  };
  const status = classifyRuntimeStatus({
    provider: identity.provider,
    ollama: evidenceResult.ollama,
    hostToolsVerified: evidenceResult.hostToolsVerified,
    hooksVerified: evidenceResult.hooksVerified,
    ponytailVerified: evidenceResult.ponytailVerified,
    vaultVerified,
    mindmapWriteAuthorized: args.authorizeMindmap === true,
  });
  return buildRuntimeEvent({
    ...identity,
    sessionId: input.session_id || process.env.RUNTIME_SYNC_SESSION_ID || null,
    phase,
    status,
    mindmapPath: null,
    ponytailStatus: evidenceResult.ponytailVerified ? 'VERIFIED' : 'UNVERIFIED',
    soupStatus: evidenceResult.soupStatus,
    ollama: identity.provider === 'ollama' ? safeOllamaSummary(evidenceResult.ollama) : null,
    evidenceSummary: evidenceResult.summary,
    mindmapStatus: args.authorizeMindmap === true ? 'AUTHORIZED' : 'BLOCKED',
  });
}

export async function runRuntimeSync(argv, { repoRoot = repoRootFromScript(), writeOutput = (line) => console.log(line) } = {}) {
  const args = parseArgs(argv);
  if (args.deprecatedStatus !== null) {
    throw new Error('--status is not accepted; supply matching --evidence so status can be derived');
  }
  if (args.authorizeMindmap && args.command !== 'postflight') {
    throw new Error('--authorize-mindmap is valid only with --postflight');
  }
  const vaultRoot = resolveVaultRoot(repoRoot, args.vault);
  if (args.command === 'verify') {
    const result = {
      repository: repoRoot,
      vault: vaultRoot,
      mindmap: vaultRoot ? fs.existsSync(mindmapPath(vaultRoot)) : false,
      ledger: vaultRoot ? fs.existsSync(ledgerPath(vaultRoot)) : false,
      status: vaultRoot && fs.existsSync(mindmapPath(vaultRoot)) ? 'READY' : 'BLOCKED',
    };
    writeOutput(args.json ? JSON.stringify(result) : `Runtime sync: ${result.status}`);
    return { exitCode: result.status === 'READY' ? 0 : 2, result };
  }
  if (!['hook', 'preflight', 'postflight'].includes(args.command)) {
    writeOutput('Usage: runtime-sync.mjs --hook|--preflight|--postflight --host claude|codex [--provider native|ollama] [--evidence evidence.json] [--dry-run]');
    return { exitCode: 0, event: null };
  }
  if (!vaultRoot) throw new Error('MYPS vault could not be resolved');
  if (args.command === 'postflight' && !args.evidence) {
    throw new Error('--postflight requires --evidence with independently observed host and Ponytail evidence');
  }
  const input = args.command === 'hook' ? parseHookInput(readStdin()) : {};
  const evidence = readEvidence(args.evidence);
  const event = eventFromInput(
    { ...args, phase: args.phase || (args.command === 'preflight' ? 'preflight' : args.command === 'postflight' ? 'postflight' : null) },
    input,
    { vaultVerified: fs.existsSync(mindmapPath(vaultRoot)), evidence },
  );
  event.mindmap_path = path.relative(vaultRoot, mindmapPath(vaultRoot));
  if (!args.dryRun) {
    appendEvent(vaultRoot, event);
    if (args.command === 'postflight' && args.authorizeMindmap) updateMindmap(vaultRoot, event);
  }
  writeOutput(JSON.stringify({
    runtime_sync: event.overall_status,
    event_id: event.event_id,
    host: event.host,
    provider: event.provider,
    dry_run: args.dryRun,
    mindmap_projected: args.command === 'postflight' && args.authorizeMindmap && !args.dryRun,
  }));
  return { exitCode: 0, event };
}

if (process.argv[1] && path.resolve(fileURLToPath(import.meta.url)) === path.resolve(process.argv[1])) {
  try { process.exitCode = (await runRuntimeSync(process.argv.slice(2))).exitCode; }
  catch (error) { console.error(`runtime sync blocked: ${error.message}`); process.exitCode = 2; }
}
