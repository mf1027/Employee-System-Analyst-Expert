#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

export const REQUIRED_FILES = [
  "plan.md",
  "rca.md",
  "gap-analysis.md",
  "review-ledger.md",
  "test-rollout.md",
  "run.json",
];

const REQUIRED_HEADINGS = {
  "plan.md": [
    "## Problem",
    "## Recommended Approach",
    "## Acceptance Criteria",
    "## Rollout and Monitoring",
    "## Rollback",
    "## Explicit Non-Scope",
  ],
  "rca.md": ["## Evidence Register", "## Root Cause Register"],
  "gap-analysis.md": ["## Gap Register"],
  "review-ledger.md": [
    "## Review Coverage",
    "## Adapter Runs",
    "## Degradation Register",
    "## Decision Audit Trail",
  ],
  "test-rollout.md": ["## Test Matrix", "## Release Gates"],
};

const RUN_STATUSES = new Set([
  "COMPLETE",
  "COMPLETE_WITH_RESIDUAL_RISKS",
  "NEEDS_INPUT",
  "BLOCKED",
]);
const MODE_VALUES = new Set(["LIVE", "BUNDLE"]);
const PERSISTENCE_VALUES = new Set(["CHAT_ONLY", "CLIENT_BUNDLE"]);
const PHASE_NAMES = ["intake", "rca", "gapAnalysis", "review", "plan", "reAudit"];
const PHASE_STATUSES = new Set(["COMPLETE", "DEGRADED", "BLOCKED"]);
const CYCLE_STATUSES = new Set(["COMPLETE", "BLOCKED"]);
const FINDING_KINDS = new Set(["ROOT_CAUSE", "GAP", "ASSUMPTION", "BLOCKER"]);
const CLASSIFICATIONS = new Set([
  "SYMPTOM",
  "ROOT_CAUSE_CONFIRMED",
  "ROOT_CAUSE_PROBABLE",
  "CONTRIBUTING_FACTOR",
  "ASSUMPTION",
  "EXTERNAL_BLOCKER",
]);
const SEVERITIES = new Set(["P0", "P1", "P2", "P3"]);
const FINDING_STATUSES = new Set(["OPEN", "CLOSED", "ACCEPTED", "BLOCKED", "OUT_OF_SCOPE"]);
const REVIEW_AREAS = new Set(["PRODUCT", "DESIGN", "ENGINEERING", "DX"]);
const REVIEW_METHODS = new Set(["INTERNAL", "GSTACK"]);
const REVIEW_STATUSES = new Set(["COMPLETED", "DEGRADED", "NOT_APPLICABLE", "BLOCKED"]);
const GSTACK_ADAPTERS = new Set([
  "gstack-office-hours",
  "gstack-autoplan",
  "gstack-plan-ceo-review",
  "gstack-plan-design-review",
  "gstack-plan-eng-review",
  "gstack-plan-devex-review",
]);
const INTERNAL_ADAPTER = "INTERNAL_CHECKLIST";
const ACCEPTANCE_STATUSES = new Set(["VERIFIED", "PENDING", "BLOCKED"]);
const DEFAULT_CYCLE_TARGET = 3;
const HARD_MAX_CYCLES = 5;
const ISO_TIMESTAMP = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$/;
const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const ARTIFACT_ID = /^[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*$/;
const SECRET_PATTERNS = [
  /["']?(?:api[_-]?key|access[_-]?token|client[_-]?secret|password|private[_-]?key)["']?\s*[:=]\s*["']?[A-Za-z0-9+/=_-]{12,}/i,
  /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/,
];
const EVIDENCE_REF = /^([a-z0-9]+(?:-[a-z0-9]+)*\.md)#([a-z0-9]+(?:-[a-z0-9]+)*)$/;
const SCRIPT_DIRECTORY = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_AGENT_ROOT = path.resolve(SCRIPT_DIRECTORY, "../../../..");

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function requireString(object, key, label, errors) {
  if (!isObject(object) || typeof object[key] !== "string" || object[key].trim() === "") {
    errors.push(`${label} must be a non-empty string`);
    return "";
  }
  return object[key];
}

function requireArtifactId(object, key, label, errors) {
  const value = requireString(object, key, label, errors);
  if (value && !ARTIFACT_ID.test(value)) {
    errors.push(`${label} must use uppercase hyphenated segments`);
  }
  return value;
}

function requireStringArray(value, label, errors, { allowEmpty = false } = {}) {
  if (!Array.isArray(value) || (!allowEmpty && value.length === 0)) {
    errors.push(`${label} must be ${allowEmpty ? "an array" : "a non-empty array"}`);
    return [];
  }
  if (value.some((item) => typeof item !== "string" || item.trim() === "")) {
    errors.push(`${label} must contain only non-empty strings`);
  }
  return value;
}

function requireEnum(value, allowed, label, errors) {
  if (!allowed.has(value)) {
    errors.push(`${label} has an invalid value`);
  }
  return value;
}

function requireIsoTimestamp(value, label, errors, { allowNull = false } = {}) {
  if (allowNull && value === null) {
    return null;
  }
  if (typeof value !== "string" || !ISO_TIMESTAMP.test(value) || Number.isNaN(Date.parse(value))) {
    errors.push(`${label} must be an ISO-8601 UTC timestamp`);
    return null;
  }
  return value;
}

function markdownAnchor(heading) {
  return heading
    .replace(/<[^>]*>/g, "")
    .replace(/\s+#+\s*$/, "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
}

function markdownSections(content) {
  const sections = new Map();
  const headings = [...content.matchAll(/^#{1,6}\s+(.+?)\s*$/gm)];
  headings.forEach((match, index) => {
    const anchor = markdownAnchor(match[1]);
    if (!anchor) {
      return;
    }
    const bodyStart = match.index + match[0].length;
    const bodyEnd = headings[index + 1]?.index ?? content.length;
    sections.set(anchor, content.slice(bodyStart, bodyEnd).trim().length > 0);
  });
  return sections;
}

function validateEvidenceReferences(run, artifacts, errors) {
  if (!isObject(run)) {
    return;
  }
  const sectionsByArtifact = new Map(
    [...artifacts.entries()]
      .filter(([name]) => name.endsWith(".md"))
      .map(([name, content]) => [name, markdownSections(content)]),
  );

  const checkReferences = (references, label) => {
    if (!Array.isArray(references)) {
      return;
    }
    references.forEach((reference, index) => {
      if (typeof reference !== "string" || reference.trim() === "") {
        return;
      }
      const match = reference.match(EVIDENCE_REF);
      if (!match) {
        errors.push(`${label} evidenceRefs[${index}] must reference a Markdown artifact heading`);
        return;
      }
      const sections = sectionsByArtifact.get(match[1]);
      if (!sections) {
        errors.push(`${label} evidenceRefs[${index}] references an unknown artifact`);
      } else if (!sections.has(match[2])) {
        errors.push(`${label} evidenceRefs[${index}] does not resolve to a Markdown heading`);
      } else if (!sections.get(match[2])) {
        errors.push(`${label} evidenceRefs[${index}] resolves to an empty Markdown heading`);
      }
    });
  };

  for (const cycle of Array.isArray(run.cycles) ? run.cycles : []) {
    if (!isObject(cycle) || !isObject(cycle.phases)) {
      continue;
    }
    for (const phaseName of PHASE_NAMES) {
      checkReferences(cycle.phases[phaseName]?.evidenceRefs, `cycle ${cycle.number} phase ${phaseName}`);
    }
  }
  for (const finding of Array.isArray(run.findings) ? run.findings : []) {
    if (isObject(finding)) {
      checkReferences(finding.evidenceRefs, `finding ${finding.id ?? "?"}`);
    }
  }
  for (const review of Array.isArray(run.reviews) ? run.reviews : []) {
    if (isObject(review)) {
      checkReferences(review.evidenceRefs, `review ${review.id ?? "?"}`);
    }
  }
}

function validateCycles(run, errors) {
  const { cycles } = run;
  if (!Array.isArray(cycles) || cycles.length === 0) {
    errors.push("run.json cycles must be a non-empty array");
    return [];
  }

  if (!Number.isInteger(run.cycleTarget) || run.cycleTarget < 1 || run.cycleTarget > HARD_MAX_CYCLES) {
    errors.push(`run.json cycleTarget must be an integer from 1 to ${HARD_MAX_CYCLES}`);
  } else if (run.cycleTarget !== DEFAULT_CYCLE_TARGET) {
    requireString(run, "cycleTargetOverrideReason", "run.json cycleTargetOverrideReason", errors);
  }
  if (!Number.isInteger(run.maxCycles) || run.maxCycles < 1 || run.maxCycles > HARD_MAX_CYCLES) {
    errors.push(`run.json maxCycles must be an integer from 1 to ${HARD_MAX_CYCLES}`);
  }
  if (Number.isInteger(run.cycleTarget) && Number.isInteger(run.maxCycles) && run.cycleTarget > run.maxCycles) {
    errors.push("run.json cycleTarget cannot exceed maxCycles");
  }
  if (Number.isInteger(run.maxCycles) && cycles.length > run.maxCycles) {
    errors.push("run.json cycle count exceeds maxCycles");
  }

  cycles.forEach((cycle, index) => {
    const label = `cycle ${index + 1}`;
    if (!isObject(cycle)) {
      errors.push(`${label} must be an object`);
      return;
    }
    if (cycle.number !== index + 1) {
      errors.push(`${label} number must be ${index + 1}`);
    }
    requireEnum(cycle.status, CYCLE_STATUSES, `${label} status`, errors);
    requireString(cycle, "changeSummary", `${label} changeSummary`, errors);
    requireStringArray(cycle.findingIds, `${label} findingIds`, errors, { allowEmpty: true });

    if (!isObject(cycle.phases)) {
      errors.push(`${label} phases must be an object`);
      return;
    }
    for (const phaseName of PHASE_NAMES) {
    const phase = cycle.phases[phaseName];
      if (!isObject(phase)) {
        errors.push(`${label} phase ${phaseName} must be an object`);
        continue;
      }
      requireEnum(phase.status, PHASE_STATUSES, `${label} phase ${phaseName} status`, errors);
      requireStringArray(phase.evidenceRefs, `${label} phase ${phaseName} evidenceRefs`, errors);
    }
    const phaseStatuses = PHASE_NAMES.map((phaseName) => cycle.phases[phaseName]?.status);
    if (cycle.status === "COMPLETE" && phaseStatuses.includes("BLOCKED")) {
      errors.push(`${label} cannot be COMPLETE with a BLOCKED phase`);
    }
    if (cycle.status === "BLOCKED" && !phaseStatuses.includes("BLOCKED")) {
      errors.push(`${label} marked BLOCKED must contain a BLOCKED phase`);
    }
  });

  return cycles;
}

function validateFindings(run, errors) {
  if (!Array.isArray(run.findings)) {
    errors.push("run.json findings must be an array");
    return [];
  }

  const ids = new Set();
  run.findings.forEach((finding, index) => {
    const label = `finding ${index + 1}`;
    if (!isObject(finding)) {
      errors.push(`${label} must be an object`);
      return;
    }
    const id = requireArtifactId(finding, "id", `${label} id`, errors);
    if (id) {
      if (ids.has(id)) {
        errors.push(`${label} has a duplicate id`);
      }
      ids.add(id);
    }
    requireEnum(finding.kind, FINDING_KINDS, `${label} kind`, errors);
    requireEnum(finding.severity, SEVERITIES, `${label} severity`, errors);
    requireEnum(finding.classification, CLASSIFICATIONS, `${label} classification`, errors);
    requireString(finding, "statement", `${label} statement`, errors);
    requireStringArray(finding.evidenceRefs, `${label} evidenceRefs`, errors);
    requireEnum(finding.status, FINDING_STATUSES, `${label} status`, errors);
    requireString(finding, "owner", `${label} owner`, errors);
    requireString(finding, "disposition", `${label} disposition`, errors);
    requireString(finding, "verification", `${label} verification`, errors);
  });
  return run.findings;
}

function validateDegradations(run, errors) {
  if (!Array.isArray(run.degradations)) {
    errors.push("run.json degradations must be an array");
    return new Set();
  }
  const ids = new Set();
  run.degradations.forEach((degradation, index) => {
    const label = `degradation ${index + 1}`;
    if (!isObject(degradation)) {
      errors.push(`${label} must be an object`);
      return;
    }
    const id = requireArtifactId(degradation, "id", `${label} id`, errors);
    if (id) {
      if (ids.has(id)) {
        errors.push(`${label} has a duplicate id`);
      }
      ids.add(id);
    }
    requireString(degradation, "capability", `${label} capability`, errors);
    requireString(degradation, "reason", `${label} reason`, errors);
    requireString(degradation, "impact", `${label} impact`, errors);
    requireString(degradation, "mitigation", `${label} mitigation`, errors);
  });
  return ids;
}

function validateReviews(run, degradationIds, errors) {
  if (!Array.isArray(run.reviews)) {
    errors.push("run.json reviews must be an array");
    return [];
  }
  const internalAreas = new Set();
  const seenIds = new Set();
  const gstackAdapters = new Set();
  run.reviews.forEach((review, index) => {
    const label = `review ${index + 1}`;
    if (!isObject(review)) {
      errors.push(`${label} must be an object`);
      return;
    }
    const id = requireArtifactId(review, "id", `${label} id`, errors);
    if (id) {
      if (seenIds.has(id)) {
        errors.push(`${label} has a duplicate id`);
      }
      seenIds.add(id);
    }
    requireEnum(review.area, REVIEW_AREAS, `${label} area`, errors);
    if (typeof review.applicable !== "boolean") {
      errors.push(`${label} applicable must be a boolean`);
    }
    requireEnum(review.method, REVIEW_METHODS, `${label} method`, errors);
    requireEnum(review.status, REVIEW_STATUSES, `${label} status`, errors);
    const adapter = requireString(review, "adapter", `${label} adapter`, errors);
    requireString(review, "reason", `${label} reason`, errors);
    requireString(review, "outcome", `${label} outcome`, errors);
    requireStringArray(review.findingIds, `${label} findingIds`, errors, { allowEmpty: true });
    const degradationRefs = requireStringArray(review.degradationIds, `${label} degradationIds`, errors, {
      allowEmpty: true,
    });
    if (review.method === "INTERNAL") {
      if (adapter && adapter !== INTERNAL_ADAPTER) {
        errors.push(`${label} using INTERNAL must use adapter ${INTERNAL_ADAPTER}`);
      }
      if (REVIEW_AREAS.has(review.area)) {
        if (internalAreas.has(review.area)) {
          errors.push(`${label} duplicates the INTERNAL ${review.area} review lens`);
        }
        internalAreas.add(review.area);
      }
    }
    if (review.method === "GSTACK") {
      if (adapter && !GSTACK_ADAPTERS.has(adapter)) {
        errors.push(`${label} using GSTACK must name an approved gstack adapter`);
      }
      if (adapter) {
        if (gstackAdapters.has(adapter)) {
          errors.push(`${label} duplicates the ${adapter} adapter record`);
        }
        gstackAdapters.add(adapter);
      }
      if (review.operatorOptIn !== true) {
        errors.push(`${label} using GSTACK requires operatorOptIn: true`);
      }
      if (review.sideEffectWarningAcknowledged !== true) {
        errors.push(`${label} using GSTACK requires sideEffectWarningAcknowledged: true`);
      }
    }
    if (review.applicable === false && review.status !== "NOT_APPLICABLE") {
      errors.push(`${label} that is not applicable must use NOT_APPLICABLE status`);
    }
    if (review.applicable === true && review.status === "NOT_APPLICABLE") {
      errors.push(`${label} that is applicable cannot use NOT_APPLICABLE status`);
    }
    if (review.status === "DEGRADED" && degradationRefs.length === 0) {
      errors.push(`${label} with DEGRADED status must reference a degradation`);
    }
    for (const degradationId of degradationRefs) {
      if (!degradationIds.has(degradationId)) {
        errors.push(`${label} references an unknown degradation id`);
      }
    }
  });

  for (const area of REVIEW_AREAS) {
    if (!internalAreas.has(area)) {
      errors.push(`run.json reviews must include the INTERNAL ${area} lens`);
    }
  }
  if (gstackAdapters.has("gstack-autoplan") && gstackAdapters.size > 1) {
    errors.push("gstack-autoplan cannot be combined with individual gstack adapter records");
  }
  return run.reviews;
}

function validateAcceptanceCriteria(run, errors) {
  if (!Array.isArray(run.acceptanceCriteria) || run.acceptanceCriteria.length === 0) {
    errors.push("run.json acceptanceCriteria must be a non-empty array");
    return [];
  }
  const ids = new Set();
  run.acceptanceCriteria.forEach((criterion, index) => {
    const label = `acceptance criterion ${index + 1}`;
    if (!isObject(criterion)) {
      errors.push(`${label} must be an object`);
      return;
    }
    const id = requireArtifactId(criterion, "id", `${label} id`, errors);
    if (id) {
      if (ids.has(id)) {
        errors.push(`${label} has a duplicate id`);
      }
      ids.add(id);
    }
    requireString(criterion, "statement", `${label} statement`, errors);
    requireString(criterion, "verification", `${label} verification`, errors);
    requireEnum(criterion.status, ACCEPTANCE_STATUSES, `${label} status`, errors);
  });
  return run.acceptanceCriteria;
}

function validateResidualRisks(run, findings, errors) {
  if (!Array.isArray(run.residualRisks)) {
    errors.push("run.json residualRisks must be an array");
    return [];
  }
  const findingById = new Map(findings.filter(isObject).map((finding) => [finding.id, finding]));
  const ids = new Set();
  run.residualRisks.forEach((risk, index) => {
    const label = `residual risk ${index + 1}`;
    if (!isObject(risk)) {
      errors.push(`${label} must be an object`);
      return;
    }
    const findingId = requireString(risk, "findingId", `${label} findingId`, errors);
    if (findingId) {
      if (ids.has(findingId)) {
        errors.push(`${label} duplicates a residual risk finding`);
      }
      ids.add(findingId);
      const finding = findingById.get(findingId);
      if (!finding || !["P2", "P3"].includes(finding.severity)) {
        errors.push(`${label} must reference a P2 or P3 finding`);
      } else if (["CLOSED", "OUT_OF_SCOPE"].includes(finding.status)) {
        errors.push(`${label} cannot reference a resolved finding`);
      }
    }
    requireString(risk, "owner", `${label} owner`, errors);
    requireString(risk, "rationale", `${label} rationale`, errors);
    requireString(risk, "verification", `${label} verification`, errors);
    requireIsoTimestamp(risk.reviewDate, `${label} reviewDate`, errors);
  });
  return ids;
}

function validateDecisions(run, errors) {
  if (!Array.isArray(run.decisions)) {
    errors.push("run.json decisions must be an array");
    return;
  }
  const ids = new Set();
  run.decisions.forEach((decision, index) => {
    const label = `decision ${index + 1}`;
    if (!isObject(decision)) {
      errors.push(`${label} must be an object`);
      return;
    }
    const id = requireArtifactId(decision, "id", `${label} id`, errors);
    if (id) {
      if (ids.has(id)) {
        errors.push(`${label} has a duplicate id`);
      }
      ids.add(id);
    }
    requireString(decision, "phase", `${label} phase`, errors);
    requireString(decision, "decision", `${label} decision`, errors);
    requireString(decision, "classification", `${label} classification`, errors);
    requireString(decision, "rationale", `${label} rationale`, errors);
  });
}

function validateFindingReferences(cycles, reviews, findings, errors) {
  const findingIds = new Set(findings.filter(isObject).map((finding) => finding.id));
  for (const cycle of cycles.filter(isObject)) {
    for (const findingId of cycle.findingIds ?? []) {
      if (!findingIds.has(findingId)) {
        errors.push(`cycle ${cycle.number} references an unknown finding id`);
      }
    }
  }
  for (const review of reviews.filter(isObject)) {
    for (const findingId of review.findingIds ?? []) {
      if (!findingIds.has(findingId)) {
        errors.push(`review ${review.id} references an unknown finding id`);
      }
    }
  }
}

function validateCompletion(run, cycles, findings, reviews, acceptanceCriteria, residualRiskIds, errors) {
  const finalStatuses = new Set(["COMPLETE", "COMPLETE_WITH_RESIDUAL_RISKS"]);
  if (!finalStatuses.has(run.status)) {
    return;
  }

  if (!run.completedAt) {
    errors.push(`${run.status} requires completedAt`);
  }
  const finalCycle = cycles.at(-1);
  if (!finalCycle || finalCycle.status !== "COMPLETE" || finalCycle.phases?.reAudit?.status !== "COMPLETE") {
    errors.push(`${run.status} requires a completed final re-audit`);
  }
  const completeCycleCount = cycles.filter((cycle) => isObject(cycle) && cycle.status === "COMPLETE").length;
  if (Number.isInteger(run.cycleTarget) && completeCycleCount < run.cycleTarget) {
    errors.push(`${run.status} requires at least ${run.cycleTarget} complete cycles`);
  }

  const unresolvedCritical = findings.filter(
    (finding) =>
      isObject(finding) &&
      ["P0", "P1"].includes(finding.severity) &&
      !["CLOSED", "OUT_OF_SCOPE"].includes(finding.status),
  );
  if (unresolvedCritical.length > 0) {
    errors.push(`${run.status} cannot retain unresolved P0/P1 findings`);
  }

  const unresolvedHighImpactAssumptions = findings.filter(
    (finding) =>
      isObject(finding) &&
      finding.kind === "ASSUMPTION" &&
      ["P0", "P1"].includes(finding.severity) &&
      !["CLOSED", "OUT_OF_SCOPE"].includes(finding.status),
  );
  if (unresolvedHighImpactAssumptions.length > 0) {
    errors.push(`${run.status} cannot retain unresolved high-impact assumptions`);
  }

  if (acceptanceCriteria.some((criterion) => isObject(criterion) && criterion.status !== "VERIFIED")) {
    errors.push(`${run.status} requires verified acceptance criteria`);
  }

  if (
    reviews.some(
      (review) =>
        isObject(review) && review.applicable === true && !["COMPLETED", "DEGRADED"].includes(review.status),
    )
  ) {
    errors.push(`${run.status} requires completed or degraded applicable reviews`);
  }

  const unresolvedNonCritical = findings.filter(
    (finding) =>
      isObject(finding) &&
      ["P2", "P3"].includes(finding.severity) &&
      !["CLOSED", "OUT_OF_SCOPE"].includes(finding.status),
  );

  if (run.status === "COMPLETE") {
    if (residualRiskIds.size > 0 || unresolvedNonCritical.length > 0) {
      errors.push("COMPLETE cannot retain residual risks or unresolved P2/P3 findings");
    }
    return;
  }

  if (residualRiskIds.size === 0) {
    errors.push("COMPLETE_WITH_RESIDUAL_RISKS requires at least one residual risk");
  }
  for (const finding of unresolvedNonCritical) {
    if (!residualRiskIds.has(finding.id)) {
      errors.push("COMPLETE_WITH_RESIDUAL_RISKS must record every unresolved P2/P3 finding as a residual risk");
      break;
    }
  }
}

function validateRun(run, bundleRoot, agentRoot, errors) {
  if (!isObject(run)) {
    errors.push("run.json must contain an object");
    return;
  }
  if (run.schemaVersion !== "2.0") {
    errors.push("run.json schemaVersion must be 2.0");
  }
  if (run.skill !== "plan-analysis") {
    errors.push("run.json skill must be plan-analysis");
  }
  const runId = requireString(run, "runId", "run.json runId", errors);
  if (runId && !SLUG.test(runId)) {
    errors.push("run.json runId must be a lowercase hyphenated slug");
  }
  requireEnum(run.mode, MODE_VALUES, "run.json mode", errors);
  requireEnum(run.persistence, PERSISTENCE_VALUES, "run.json persistence", errors);
  const startedAt = requireIsoTimestamp(run.startedAt, "run.json startedAt", errors);
  const completedAt = requireIsoTimestamp(run.completedAt, "run.json completedAt", errors, { allowNull: true });
  if (startedAt && completedAt && Date.parse(completedAt) < Date.parse(startedAt)) {
    errors.push("run.json completedAt cannot precede startedAt");
  }
  requireEnum(run.status, RUN_STATUSES, "run.json status", errors);

  if (run.mode === "LIVE" && run.persistence !== "CHAT_ONLY") {
    errors.push("LIVE mode must use CHAT_ONLY persistence");
  }
  if (run.mode === "BUNDLE" && run.persistence === "CHAT_ONLY") {
    errors.push("a persisted BUNDLE must use CLIENT_BUNDLE persistence");
  }
  if (run.persistence === "CLIENT_BUNDLE") {
    if (run.mode !== "BUNDLE") {
      errors.push("CLIENT_BUNDLE persistence requires BUNDLE mode");
    }
    if (!isObject(run.client)) {
      errors.push("CLIENT_BUNDLE persistence requires a client object");
    } else {
      const clientName = requireString(run.client, "name", "client name", errors);
      const projectName = requireString(run.client, "project", "client project", errors);
      const artifactPath = requireString(run.client, "artifactPath", "client artifactPath", errors);
      if (clientName && !SLUG.test(clientName)) {
        errors.push("client name must be a lowercase hyphenated slug");
      }
      if (projectName && !SLUG.test(projectName)) {
        errors.push("client project must be a lowercase hyphenated slug");
      }
      if (runId && clientName && projectName && artifactPath) {
        const expectedPath = `memory/clients/${clientName}/${projectName}/deliverables/documents/plan-analysis/${runId}`;
        if (artifactPath !== expectedPath) {
          errors.push("client artifactPath must use the approved client-deliverables location");
        }
        const expectedBundleRoot = path.resolve(agentRoot, ...expectedPath.split("/"));
        const expectedRealBundleRoot = path.resolve(fs.realpathSync(agentRoot), ...expectedPath.split("/"));
        const actualRealBundleRoot = fs.realpathSync(bundleRoot);
        if (path.resolve(bundleRoot) !== expectedBundleRoot || actualRealBundleRoot !== expectedRealBundleRoot) {
          errors.push("bundle directory must match the recorded client artifactPath under the agent root");
        }
      }
    }
  } else if (run.client !== null && run.client !== undefined && !isObject(run.client)) {
    errors.push("run.json client must be an object or null");
  }

  const cycles = validateCycles(run, errors);
  const findings = validateFindings(run, errors);
  const degradationIds = validateDegradations(run, errors);
  const reviews = validateReviews(run, degradationIds, errors);
  const acceptanceCriteria = validateAcceptanceCriteria(run, errors);
  const residualRiskIds = validateResidualRisks(run, findings, errors);
  validateDecisions(run, errors);
  validateFindingReferences(cycles, reviews, findings, errors);
  validateCompletion(run, cycles, findings, reviews, acceptanceCriteria, residualRiskIds, errors);
}

function readArtifact(root, name, errors) {
  const filePath = path.join(root, name);
  if (!fs.existsSync(filePath)) {
    errors.push(`missing required artifact: ${name}`);
    return null;
  }
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch (error) {
    errors.push(`unable to read ${name}: ${error.message}`);
    return null;
  }
}

export function validateBundle(bundleDirectory, { agentRoot = DEFAULT_AGENT_ROOT } = {}) {
  const errors = [];
  const root = path.resolve(bundleDirectory);
  if (!fs.existsSync(root) || !fs.statSync(root).isDirectory()) {
    return [`bundle directory not found: ${root}`];
  }

  const artifacts = new Map();
  for (const name of REQUIRED_FILES) {
    const content = readArtifact(root, name, errors);
    if (content !== null) {
      artifacts.set(name, content);
    }
  }
  if (errors.length > 0) {
    return errors;
  }

  for (const [name, content] of artifacts) {
    if (SECRET_PATTERNS.some((pattern) => pattern.test(content))) {
      errors.push(`possible secret detected in ${name}`);
    }
  }

  for (const [name, headings] of Object.entries(REQUIRED_HEADINGS)) {
    const content = artifacts.get(name);
    const sections = markdownSections(content);
    for (const heading of headings) {
      if (!content.includes(heading)) {
        errors.push(`${name} is missing required heading: ${heading}`);
        continue;
      }
      const anchor = markdownAnchor(heading.replace(/^#{1,6}\s+/, ""));
      if (!sections.get(anchor)) {
        errors.push(`${name} required heading must contain substantive content: ${heading}`);
      }
    }
  }

  let run = null;
  try {
    run = JSON.parse(artifacts.get("run.json"));
  } catch (error) {
    errors.push(`run.json is not valid JSON: ${error.message}`);
  }
  if (run !== null) {
    validateRun(run, root, agentRoot, errors);
    validateEvidenceReferences(run, artifacts, errors);
  }
  return errors;
}

export function runCli(
  argumentsList,
  { agentRoot = process.env.PLAN_ANALYSIS_AGENT_ROOT || DEFAULT_AGENT_ROOT } = {},
) {
  if (argumentsList.length !== 1) {
    process.stderr.write("usage: validate-artifacts.mjs <bundle-directory>\n");
    return 2;
  }
  const errors = validateBundle(argumentsList[0], { agentRoot });
  if (errors.length > 0) {
    for (const error of errors) {
      process.stdout.write(`ERROR: ${error}\n`);
    }
    return 1;
  }
  process.stdout.write(`PASS: plan-analysis bundle is valid (${path.resolve(argumentsList[0])})\n`);
  return 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  process.exitCode = runCli(process.argv.slice(2));
}
