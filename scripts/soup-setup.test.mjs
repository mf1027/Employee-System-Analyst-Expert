import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import {
  SOUP_SHA256,
  SOUP_VERSION,
  TRAINING_PACKAGES,
  hasTrainingExtras,
  inspectSoup,
  isExpectedSoupVersion,
} from './soup-setup.mjs';

test('Soup version verification is exact', () => {
  assert.equal(isExpectedSoupVersion(SOUP_VERSION), true);
  assert.equal(isExpectedSoupVersion('0.75'), false);
  assert.equal(isExpectedSoupVersion('0.75.1'), false);
});

test('training extras require every declared package', () => {
  assert.equal(hasTrainingExtras(TRAINING_PACKAGES), true);
  assert.equal(hasTrainingExtras(TRAINING_PACKAGES.slice(0, -1)), false);
  assert.equal(hasTrainingExtras(['torch', 'transformers']), false);
});

test('Soup inspection exposes independent local-version and training-extra gates', () => {
  const repo = fs.mkdtempSync(path.join(os.tmpdir(), 'soup-inspect-'));
  const result = inspectSoup({
    repo,
    archive: path.join(repo, 'missing-Soup-0.75.0.zip'),
    training: false,
  });
  assert.equal(result.repoLocalVersion, null);
  assert.equal(result.repoLocalVersionVerified, false);
  assert.equal(result.trainingExtrasVerified, false);
  assert.equal(result.trainingAvailable, false);
  assert.equal(result.archiveFound, false);
  assert.equal(SOUP_SHA256.length, 64);
});
