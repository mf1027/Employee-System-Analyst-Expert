#!/usr/bin/env node

import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

export const MIN_CONTEXT_TOKENS = 65536;

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
    const required = ['installed', 'serviceReachable', 'modelConfigured', 'modelInstalled', 'toolCallingVerified'];
    if (required.some((key) => ollama[key] !== true)) return 'UNVERIFIED';
    if (ollama.contextVerified !== true) return 'LIMITED';
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
  skillPaths = [],
  mindmapPath = null,
  ponytailStatus = 'UNVERIFIED',
  soupStatus = 'NOT_APPLICABLE',
  ollama = null,
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
    canonical_skill_paths: [...skillPaths],
    mindmap_path: mindmapPath,
    ollama_status: identity.provider === 'ollama' ? (ollama || {}) : 'NOT_APPLICABLE',
    ponytail_status: ponytailStatus,
    soup_status: soupStatus,
    overall_status: status,
  });
}

function parseArgs(argv) {
  const args = { command: 'help', host: null, provider: null, model: null, phase: null, status: 'UNVERIFIED', vault: null };
  for (let i = 0; i < argv.length; i += 1) {
    const value = argv[i];
    if (value === '--hook') args.command = 'hook';
    else if (value === '--preflight') args.command = 'preflight';
    else if (value === '--postflight') args.command = 'postflight';
    else if (value === '--verify') args.command = 'verify';
    else if (value === '--json') args.json = true;
    else if (value === '--host') args.host = argv[++i];
    else if (value === '--provider') args.provider = argv[++i];
    else if (value === '--model') args.model = argv[++i];
    else if (value === '--phase') args.phase = argv[++i];
    else if (value === '--status') args.status = argv[++i];
    else if (value === '--vault') args.vault = argv[++i];
  }
  return args;
}

function repoRootFromScript() {
  return path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
}

export function resolveVaultRoot(repoRoot, explicitVault = process.env.MYPS_VAULT_ROOT) {
  if (explicitVault) {
    const explicit = path.resolve(explicitVault);
    return fs.existsSync(explicit) ? explicit : null;
  }
  const candidates = [];
  if (explicitVault) candidates.push(explicitVault);
  candidates.push(path.join(path.dirname(repoRoot), 'Obsidian', 'MYPS_Obsidian_Vault', 'MYPS'));
  return candidates.map((candidate) => path.resolve(candidate)).find((candidate) => fs.existsSync(candidate)) || null;
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

function eventFromInput(args, input) {
  const host = args.host || (input.host === 'claude' || input.host === 'codex' ? input.host : null);
  const provider = args.provider || input.provider || process.env.RUNTIME_SYNC_PROVIDER || 'native';
  if (!host) throw new Error('host is required: use --host claude or --host codex');
  const phase = args.phase || input.hook_event_name || 'unknown';
  return buildRuntimeEvent({
    host,
    provider,
    model: args.model || process.env.OLLAMA_MODEL || input.model || null,
    sessionId: input.session_id || process.env.RUNTIME_SYNC_SESSION_ID || null,
    phase,
    status: args.status,
    mindmapPath: null,
    skillPaths: [],
    ponytailStatus: process.env.PONYTAIL_RUNTIME_STATUS || 'UNVERIFIED',
    soupStatus: process.env.SOUP_RUNTIME_STATUS || (provider === 'ollama' ? 'NOT_APPLICABLE' : 'NOT_APPLICABLE'),
  });
}

async function main(argv) {
  const args = parseArgs(argv);
  const repoRoot = repoRootFromScript();
  const vaultRoot = resolveVaultRoot(repoRoot, args.vault);
  if (args.command === 'verify') {
    const result = {
      repository: repoRoot,
      vault: vaultRoot,
      mindmap: vaultRoot ? fs.existsSync(mindmapPath(vaultRoot)) : false,
      ledger: vaultRoot ? fs.existsSync(ledgerPath(vaultRoot)) : false,
      status: vaultRoot && fs.existsSync(mindmapPath(vaultRoot)) ? 'READY' : 'BLOCKED',
    };
    console.log(args.json ? JSON.stringify(result) : `Runtime sync: ${result.status}`);
    return result.status === 'READY' ? 0 : 2;
  }
  if (!['hook', 'preflight', 'postflight'].includes(args.command)) {
    console.log('Usage: runtime-sync.mjs --hook|--preflight|--postflight --host claude|codex [--provider native|ollama]');
    return 0;
  }
  if (!vaultRoot) throw new Error('MYPS vault could not be resolved');
  const input = parseHookInput(readStdin());
  const event = eventFromInput({ ...args, phase: args.phase || (args.command === 'preflight' ? 'preflight' : args.command === 'postflight' ? 'postflight' : null) }, input);
  event.mindmap_path = path.relative(vaultRoot, mindmapPath(vaultRoot));
  appendEvent(vaultRoot, event);
  if (args.command === 'postflight') updateMindmap(vaultRoot, event);
  console.log(JSON.stringify({ runtime_sync: event.overall_status, event_id: event.event_id, host: event.host, provider: event.provider }));
  return 0;
}

if (process.argv[1] && path.resolve(fileURLToPath(import.meta.url)) === path.resolve(process.argv[1])) {
  try { process.exitCode = await main(process.argv.slice(2)); }
  catch (error) { console.error(`runtime sync blocked: ${error.message}`); process.exitCode = 2; }
}
