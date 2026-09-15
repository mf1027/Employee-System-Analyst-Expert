#!/usr/bin/env node

import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

export const SOUP_VERSION = '0.75.0';
export const SOUP_SHA256 = '61AD531DA5C4779E50390B6589202DD1EBA69D93A30156441542DD185C94F029';
export const TRAINING_PACKAGES = ['torch', 'transformers', 'peft', 'trl', 'datasets', 'bitsandbytes', 'accelerate'];

function parseArgs(argv) {
  const args = { repo: process.cwd(), archive: process.env.SOUP_ARCHIVE || '', install: false, training: false, json: false };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--repo') args.repo = argv[++i];
    else if (argv[i] === '--archive') args.archive = argv[++i];
    else if (argv[i] === '--install') args.install = true;
    else if (argv[i] === '--training') args.training = true;
    else if (argv[i] === '--json') args.json = true;
  }
  if (!args.archive) args.archive = path.join(os.homedir(), 'Downloads', `Soup-${SOUP_VERSION}.zip`);
  return args;
}

function run(command, args, options = {}) {
  return spawnSync(command, args, { encoding: 'utf8', ...options });
}

function soupVersionOf(output) {
  const match = String(output || '').match(/(?:soup(?:-cli)?\s+)?v?(0\.\d+\.\d+)/i);
  return match?.[1] || null;
}

function pythonCommand() {
  for (const candidate of process.platform === 'win32' ? ['python', 'py'] : ['python3', 'python']) {
    const args = candidate === 'py' ? ['-3', '--version'] : ['--version'];
    const result = run(candidate, args);
    const match = String(result.stdout || result.stderr).match(/Python\s+(\d+)\.(\d+)/i);
    if (match) {
      const major = Number(match[1]);
      const minor = Number(match[2]);
      if (major === 3 && minor >= 10 && minor <= 12) return { command: candidate, prefix: candidate === 'py' ? ['-3'] : [], version: `${major}.${minor}` };
    }
  }
  return null;
}

function repoLocalSoupPath(repo) {
  return process.platform === 'win32'
    ? path.join(repo, '.venv-soup', 'Scripts', 'soup.exe')
    : path.join(repo, '.venv-soup', 'bin', 'soup');
}

function repoLocalPythonPath(repo) {
  return process.platform === 'win32'
    ? path.join(repo, '.venv-soup', 'Scripts', 'python.exe')
    : path.join(repo, '.venv-soup', 'bin', 'python');
}

function normalizePackageName(name) {
  return String(name || '').trim().toLowerCase().replace(/[-_.]+/g, '-');
}

export function isExpectedSoupVersion(version) {
  return version === SOUP_VERSION;
}

export function hasTrainingExtras(packages) {
  const installed = new Set(Array.from(packages || [], normalizePackageName));
  return TRAINING_PACKAGES.every((name) => installed.has(normalizePackageName(name)));
}

function verifyTrainingExtras(repo) {
  const python = repoLocalPythonPath(repo);
  if (!fs.existsSync(python)) return false;
  const probe = [
    'import importlib.metadata as m, sys',
    `required = ${JSON.stringify(TRAINING_PACKAGES)}`,
    'installed = {name.lower().replace("_", "-") for name in m.packages_distributions()}',
    'sys.exit(1 if any(package not in installed for package in required) else 0)',
  ].join('\n');
  return run(python, ['-c', probe]).status === 0;
}

function hashFile(file) {
  return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex').toUpperCase();
}

export function inspectSoup(args) {
  const result = {
    globalAvailable: false,
    globalVersion: null,
    globalVersionVerified: false,
    archiveFound: fs.existsSync(args.archive),
    archiveHashVerified: false,
    repoLocalAvailable: false,
    repoLocalVersion: null,
    repoLocalVersionVerified: false,
    trainingExtrasVerified: false,
    trainingAvailable: false,
    duplicateInstallations: false,
    status: 'UNAVAILABLE',
    reasons: [],
  };
  const global = run('soup', ['--version']);
  if (global.status === 0) {
    result.globalAvailable = true;
    result.globalVersion = soupVersionOf(`${global.stdout}\n${global.stderr}`);
    result.globalVersionVerified = result.globalVersion === SOUP_VERSION;
  }
  if (result.archiveFound) {
    result.archiveHashVerified = hashFile(args.archive) === SOUP_SHA256;
    if (!result.archiveHashVerified) result.reasons.push('Soup archive hash mismatch');
  }
  const localSoup = repoLocalSoupPath(args.repo);
  if (fs.existsSync(localSoup)) {
    const local = run(localSoup, ['--version']);
    result.repoLocalAvailable = local.status === 0;
    result.repoLocalVersion = soupVersionOf(`${local.stdout}\n${local.stderr}`);
    result.repoLocalVersionVerified = result.repoLocalAvailable && isExpectedSoupVersion(result.repoLocalVersion);
    result.trainingExtrasVerified = result.repoLocalVersionVerified && verifyTrainingExtras(args.repo);
    result.trainingAvailable = result.trainingExtrasVerified;
    if (result.repoLocalAvailable && !result.repoLocalVersionVerified) result.reasons.push(`repo-local Soup version is not ${SOUP_VERSION}`);
    if (result.repoLocalVersionVerified && args.training && !result.trainingExtrasVerified) result.reasons.push('repo-local Soup training extras are not verified');
  }
  result.duplicateInstallations = result.globalAvailable && result.repoLocalAvailable;
  if (result.duplicateInstallations) {
    result.reasons.push('global and repo-local Soup installations detected; setup will not remove either one');
  }
  const baseVerified = result.globalVersionVerified || result.repoLocalVersionVerified;
  const trainingGate = !args.training || result.trainingExtrasVerified;
  if (baseVerified && trainingGate) result.status = 'VERIFIED';
  else if (result.archiveFound && result.archiveHashVerified) result.status = 'READY_TO_INSTALL';
  else result.reasons.push(result.archiveFound ? 'Soup 0.75.0 archive is not verified' : 'Soup 0.75.0 archive not found');
  return result;
}

function install(args) {
  const result = inspectSoup(args);
  if ((result.globalVersionVerified && !args.training)
    || (result.repoLocalVersionVerified && (!args.training || result.trainingExtrasVerified))) return result;
  if (!result.archiveFound || !result.archiveHashVerified) {
    result.status = 'BLOCKED';
    result.reasons.push('installation requires the verified Soup archive');
    return result;
  }
  const python = pythonCommand();
  if (!python) {
    result.status = 'BLOCKED';
    result.reasons.push('Python 3.10-3.12 is required for the repo-local Soup environment');
    return result;
  }
  const sourceRoot = path.join(args.repo, '.tools', 'soup');
  const extractRoot = path.join(sourceRoot, `Soup-${SOUP_VERSION}`);
  fs.mkdirSync(sourceRoot, { recursive: true });
  if (!fs.existsSync(path.join(extractRoot, 'pyproject.toml'))) {
    const extracted = run('tar', ['-xf', args.archive, '-C', sourceRoot]);
    if (extracted.status !== 0) {
      result.status = 'BLOCKED';
      result.reasons.push('tar is required to extract the verified Soup archive');
      return result;
    }
  }
  const venv = path.join(args.repo, '.venv-soup');
  const venvResult = run(python.command, [...python.prefix, '-m', 'venv', venv]);
  if (venvResult.status !== 0) {
    result.status = 'BLOCKED';
    result.reasons.push('repo-local Soup virtual environment creation failed');
    return result;
  }
  const pipPython = process.platform === 'win32' ? path.join(venv, 'Scripts', 'python.exe') : path.join(venv, 'bin', 'python');
  const spec = args.training ? '.[train]' : '.';
  const pip = run(pipPython, ['-m', 'pip', 'install', '--disable-pip-version-check', spec], { cwd: extractRoot });
  if (pip.status !== 0) {
    result.status = 'BLOCKED';
    result.reasons.push('Soup installation failed; inspect the isolated environment output');
    return result;
  }
  return inspectSoup(args);
}

function main(argv) {
  const args = parseArgs(argv);
  const result = args.install ? install(args) : inspectSoup(args);
  if (args.json) console.log(JSON.stringify(result));
  else {
    console.log(`Soup globally available: ${result.globalAvailable ? 'yes' : 'no'}`);
    console.log(`Soup global version: ${result.globalVersion || 'unknown'}`);
    console.log(`Soup version verified: ${result.globalVersionVerified ? 'yes' : 'no'}`);
    console.log(`Soup archive found: ${result.archiveFound ? 'yes' : 'no'}`);
    console.log(`Soup archive hash verified: ${result.archiveHashVerified ? 'yes' : 'no'}`);
    console.log(`Soup repo-local environment available: ${result.repoLocalAvailable ? 'yes' : 'no'}`);
    console.log(`Soup repo-local version verified: ${result.repoLocalVersionVerified ? 'yes' : 'no'}`);
    console.log(`Soup training extras verified: ${result.trainingExtrasVerified ? 'yes' : 'no'}`);
    console.log(`Soup training extras available: ${result.trainingAvailable ? 'yes' : 'no'}`);
    console.log(`Soup duplicate installations: ${result.duplicateInstallations ? 'yes' : 'no'}`);
    console.log(`Soup status: ${result.status}`);
    for (const reason of result.reasons) console.log(`Reason: ${reason}`);
  }
  return result.status === 'VERIFIED' ? 0 : 2;
}

if (process.argv[1] && path.resolve(fileURLToPath(import.meta.url)) === path.resolve(process.argv[1])) process.exitCode = main(process.argv.slice(2));
