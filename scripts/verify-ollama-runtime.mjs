#!/usr/bin/env node

import process from 'node:process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const DEFAULT_HOST = 'http://localhost:11434';
export const DEFAULT_MIN_CONTEXT_TOKENS = 65536;

function parseArgs(argv) {
  const args = { host: process.env.OLLAMA_HOST || DEFAULT_HOST, model: process.env.OLLAMA_MODEL || '', json: false };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--host') args.host = argv[++i];
    else if (argv[i] === '--model') args.model = argv[++i];
    else if (argv[i] === '--min-context') args.minContext = Number(argv[++i]);
    else if (argv[i] === '--json') args.json = true;
  }
  return args;
}

export function isCloudModel(model) {
  return /(^|[-:])cloud($|[-:])/i.test(model);
}

function findContextLength(value) {
  if (!value || typeof value !== 'object') return undefined;
  for (const [key, child] of Object.entries(value)) {
    if (/context[_-]?length|num[_-]?ctx/i.test(key) && Number.isFinite(Number(child))) {
      return Number(child);
    }
    const nested = findContextLength(child);
    if (nested !== undefined) return nested;
  }
  return undefined;
}

function endpoint(host, path) {
  return `${host.replace(/\/+$/, '')}${path}`;
}

async function getJson(fetchImpl, url, options = {}) {
  const response = await fetchImpl(url, options);
  const body = await response.json();
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return body;
}

export async function verifyOllama({
  host = DEFAULT_HOST,
  model = '',
  minContext = DEFAULT_MIN_CONTEXT_TOKENS,
  fetchImpl = fetch,
} = {}) {
  const result = {
    host,
    model: model || null,
    explicitModelConfigured: Boolean(model),
    serviceReachable: false,
    availableLocalModels: [],
    localModelVerified: false,
    contextCapacity: null,
    contextVerified: false,
    toolCallingVerified: false,
    status: 'UNVERIFIED',
    errors: [],
  };

  if (isCloudModel(model)) {
    result.errors.push('cloud model names are not allowed for local verification');
    return result;
  }

  let tags;
  try {
    tags = await getJson(fetchImpl, endpoint(host, '/api/tags'));
    result.serviceReachable = true;
  } catch (error) {
    result.errors.push(`service unreachable: ${error.message}`);
    return result;
  }

  const models = Array.isArray(tags.models) ? tags.models : [];
  result.availableLocalModels = models
    .map((entry) => entry && entry.name)
    .filter((name) => typeof name === 'string' && name.length > 0);
  if (!model) {
    result.status = 'BLOCKED';
    result.errors.push('OLLAMA_MODEL is not configured');
    return result;
  }
  result.localModelVerified = models.some((entry) => entry && entry.name === model);
  if (!result.localModelVerified) {
    result.errors.push('exact model is not present in /api/tags');
    return result;
  }

  let metadata;
  try {
    metadata = await getJson(fetchImpl, endpoint(host, '/api/show'), {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ model }),
    });
    result.contextCapacity = findContextLength(metadata);
    if (result.contextCapacity === undefined) {
      result.errors.push('context capacity is not exposed by model metadata');
    } else if (result.contextCapacity < minContext) {
      result.errors.push(`context capacity ${result.contextCapacity} is below ${minContext}`);
    } else {
      result.contextVerified = true;
    }
  } catch (error) {
    result.errors.push(`model metadata unavailable: ${error.message}`);
  }

  try {
    const response = await getJson(fetchImpl, endpoint(host, '/api/chat'), {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        model,
        stream: false,
        options: { temperature: 0 },
        messages: [{
          role: 'user',
          content: 'For this read-only capability probe, call read_only_probe exactly once with path ".". Do not answer with prose.',
        }],
        tools: [{
          type: 'function',
          function: {
            name: 'read_only_probe',
            description: 'A harmless read-only probe. The host must not execute this probe during verification.',
            parameters: {
              type: 'object',
              properties: { path: { type: 'string' } },
              required: ['path'],
            },
          },
        }],
      }),
    });
    const calls = response?.message?.tool_calls;
    const call = Array.isArray(calls) ? calls.find((item) => item?.function?.name === 'read_only_probe') : null;
    result.toolCallingVerified = Boolean(call && call.function.arguments && typeof call.function.arguments === 'object');
    if (!result.toolCallingVerified) result.errors.push('model did not return the expected read-only tool call');
  } catch (error) {
    result.errors.push(`tool-calling probe failed: ${error.message}`);
  }

  if (result.localModelVerified && result.contextVerified && result.toolCallingVerified) result.status = 'VERIFIED';
  else if (result.localModelVerified && result.contextCapacity !== null && result.contextCapacity < minContext) result.status = 'LIMITED';
  return result;
}

function printHuman(result) {
  const line = (label, value) => console.log(`${label}: ${value}`);
  line('Ollama host', result.host);
  line('Ollama model', result.model || 'NOT CONFIGURED');
  line('Explicit model configured', result.explicitModelConfigured ? 'yes' : 'no');
  line('Ollama service reachable', result.serviceReachable ? 'yes' : 'no');
  line('Available local models', result.availableLocalModels.length ? result.availableLocalModels.join(', ') : 'none reported');
  line('Model installed locally', result.localModelVerified ? 'yes' : 'no');
  line('Context capacity', result.contextCapacity ?? 'unknown');
  line('Context capacity verified', result.contextVerified ? 'yes' : 'no');
  line('Tool calling verified', result.toolCallingVerified ? 'yes' : 'no');
  line('Overall status', result.status);
  for (const error of result.errors) console.log(`Reason: ${error}`);
}

if (process.argv[1] && path.resolve(fileURLToPath(import.meta.url)) === path.resolve(process.argv[1])) {
  const args = parseArgs(process.argv.slice(2));
  const result = await verifyOllama({
    host: args.host,
    model: args.model,
    minContext: Number.isFinite(args.minContext) ? args.minContext : DEFAULT_MIN_CONTEXT_TOKENS,
  });
  if (args.json) console.log(JSON.stringify(result));
  else printHuman(result);
  process.exitCode = result.status === 'VERIFIED' ? 0 : 2;
}
