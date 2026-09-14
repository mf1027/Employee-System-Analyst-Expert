import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { validateBundle } from "./validate-artifacts.mjs";

const REQUIRED_MARKDOWN = {
  "plan.md": [
    "## Problem",
    "## Recommended Approach",
    "## Acceptance Criteria",
    "## Rollout and Monitoring",
    "## Rollback",
    "## Explicit Non-Scope",
  ].join("\n"),
  "rca.md": ["## Evidence Register", "## Root Cause Register"].join("\n"),
  "gap-analysis.md": "## Gap Register",
  "review-ledger.md": [
    "## Review Coverage",
    "## Adapter Runs",
    "## Degradation Register",
    "## Decision Audit Trail",
  ].join("\n"),
  "test-rollout.md": ["## Test Matrix", "## Release Gates"].join("\n"),
};
const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const validatorPath = path.join(scriptDirectory, "validate-artifacts.mjs");

function phase(evidenceRef) {
  return { status: "COMPLETE", evidenceRefs: [evidenceRef] };
}

function completeCycle(number, changeSummary) {
  return {
    number,
    status: "COMPLETE",
    changeSummary,
    findingIds: [],
    phases: {
      intake: phase("rca.md#evidence-register"),
      rca: phase("rca.md#root-cause-register"),
      gapAnalysis: phase("gap-analysis.md#gap-register"),
      review: phase("review-ledger.md#review-coverage"),
      plan: phase("plan.md#recommended-approach"),
      reAudit: phase("review-ledger.md#decision-audit-trail"),
    },
  };
}

function validRun() {
  return {
    schemaVersion: "2.0",
    skill: "plan-analysis",
    runId: "test-run",
    mode: "BUNDLE",
    persistence: "CLIENT_BUNDLE",
    client: {
      name: "test-client",
      project: "test-project",
      artifactPath: "memory/clients/test-client/test-project/deliverables/documents/plan-analysis/test-run",
    },
    startedAt: "2026-09-14T10:00:00Z",
    completedAt: "2026-09-14T10:05:00Z",
    status: "COMPLETE",
    cycleTarget: 3,
    maxCycles: 5,
    cycles: [
      completeCycle(1, "Baseline complete."),
      completeCycle(2, "Independent challenge complete."),
      completeCycle(3, "Final re-audit complete."),
    ],
    findings: [],
    reviews: [
      {
        id: "REV-PRODUCT",
        area: "PRODUCT",
        applicable: true,
        method: "INTERNAL",
        adapter: "INTERNAL_CHECKLIST",
        status: "COMPLETED",
        reason: "Premises and scope were reviewed.",
        outcome: "No premise changes were needed.",
        findingIds: [],
        degradationIds: [],
      },
      {
        id: "REV-DESIGN",
        area: "DESIGN",
        applicable: false,
        method: "INTERNAL",
        adapter: "INTERNAL_CHECKLIST",
        status: "NOT_APPLICABLE",
        reason: "The plan has no UI surface.",
        outcome: "No design review was needed.",
        findingIds: [],
        degradationIds: [],
      },
      {
        id: "REV-ENGINEERING",
        area: "ENGINEERING",
        applicable: true,
        method: "INTERNAL",
        adapter: "INTERNAL_CHECKLIST",
        status: "COMPLETED",
        reason: "Failure modes and verification controls were reviewed.",
        outcome: "Controls and verification are sufficient.",
        findingIds: [],
        degradationIds: [],
      },
      {
        id: "REV-DX",
        area: "DX",
        applicable: false,
        method: "INTERNAL",
        adapter: "INTERNAL_CHECKLIST",
        status: "NOT_APPLICABLE",
        reason: "The plan has no developer-facing surface.",
        outcome: "No DX review was needed.",
        findingIds: [],
        degradationIds: [],
      },
    ],
    degradations: [],
    acceptanceCriteria: [
      {
        id: "AC-001",
        statement: "The planned behavior is testable.",
        verification: "Execute the stated test matrix.",
        status: "VERIFIED",
      },
    ],
    residualRisks: [],
    decisions: [
      {
        id: "DEC-001",
        phase: "PLAN",
        decision: "Use the bounded implementation approach.",
        classification: "MECHANICAL",
        rationale: "It matches the evidence and scope.",
      },
    ],
  };
}

function finding(overrides = {}) {
  return {
    id: "GAP-001",
    kind: "GAP",
    severity: "P2",
    classification: "CONTRIBUTING_FACTOR",
    statement: "A non-critical control is incomplete.",
    evidenceRefs: ["gap-analysis.md#gap-001"],
    status: "OPEN",
    owner: "Engineering",
    disposition: "Track as a residual risk.",
    verification: "Run the targeted control test.",
    ...overrides,
  };
}

function writeBundle(t, mutate = () => {}, buildRun = validRun) {
  const agentRoot = fs.mkdtempSync(path.join(os.tmpdir(), "plan-analysis-agent-"));
  t.after(() => fs.rmSync(agentRoot, { recursive: true, force: true }));

  const run = buildRun();
  const markdown = { ...REQUIRED_MARKDOWN };
  mutate({ run, markdown });
  const root =
    run.persistence === "CLIENT_BUNDLE" && run.client?.artifactPath
      ? path.join(agentRoot, ...run.client.artifactPath.split("/"))
      : path.join(agentRoot, "chat-only-bundle");
  fs.mkdirSync(root, { recursive: true });

  for (const [name, content] of Object.entries(markdown)) {
    fs.writeFileSync(path.join(root, name), content, "utf8");
  }
  fs.writeFileSync(path.join(root, "run.json"), JSON.stringify(run, null, 2), "utf8");
  return { root, agentRoot, run, markdown };
}

function validateFixture(fixture) {
  return validateBundle(fixture.root, { agentRoot: fixture.agentRoot });
}

function expectError(errors, fragment) {
  assert.ok(errors.some((error) => error.includes(fragment)), `Expected an error containing: ${fragment}`);
}

test("accepts a complete client bundle", (t) => {
  const fixture = writeBundle(t);
  assert.deepEqual(validateFixture(fixture), []);
});

test("runs the validator through its CLI entry point", (t) => {
  const fixture = writeBundle(t);
  const result = spawnSync(process.execPath, [validatorPath, fixture.root], {
    encoding: "utf8",
    env: { ...process.env, PLAN_ANALYSIS_AGENT_ROOT: fixture.agentRoot },
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /^PASS: plan-analysis bundle is valid/m);
});

test("keeps the documented v2 example executable", (t) => {
  const schema = fs.readFileSync(path.join(scriptDirectory, "..", "references", "evidence-schema.md"), "utf8");
  const match = schema.match(/```json\r?\n([\s\S]*?)\r?\n```/);
  assert.ok(match, "Expected a JSON example in evidence-schema.md");
  const fixture = writeBundle(
    t,
    ({ markdown }) => {
    for (const key of Object.keys(markdown)) {
      markdown[key] = REQUIRED_MARKDOWN[key];
    }
    },
    () => JSON.parse(match[1]),
  );
  assert.deepEqual(validateFixture(fixture), []);
});

test("rejects an unsupported schema version", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.schemaVersion = "1.0";
  });
  expectError(validateFixture(fixture), "schemaVersion must be 2.0");
});

test("rejects missing artifacts", (t) => {
  const fixture = writeBundle(t, ({ markdown }) => {
    delete markdown["plan.md"];
  });
  expectError(validateFixture(fixture), "missing required artifact: plan.md");
});

test("rejects a noncanonical client artifactPath", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.client.artifactPath = "docs/plans/test-run";
  });
  expectError(validateFixture(fixture), "must use the approved client-deliverables location");
});

test("rejects a bundle directory outside its recorded client-deliverables path", (t) => {
  const fixture = writeBundle(t);
  const relocated = path.join(fixture.agentRoot, "relocated-bundle");
  fs.cpSync(fixture.root, relocated, { recursive: true });
  expectError(
    validateBundle(relocated, { agentRoot: fixture.agentRoot }),
    "bundle directory must match the recorded client artifactPath under the agent root",
  );
});

test("rejects malformed JSON", (t) => {
  const fixture = writeBundle(t);
  fs.writeFileSync(path.join(fixture.root, "run.json"), "{", "utf8");
  expectError(validateFixture(fixture), "run.json is not valid JSON");
});

test("rejects incomplete cycle phase coverage", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    delete run.cycles[0].phases.reAudit;
  });
  expectError(validateFixture(fixture), "phase reAudit must be an object");
});

test("requires the default three complete cycles for a completed run", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.cycles = run.cycles.slice(0, 2);
  });
  expectError(validateFixture(fixture), "COMPLETE requires at least 3 complete cycles");
});

test("requires a reason for a non-default cycle target", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.cycleTarget = 2;
    run.cycles = run.cycles.slice(0, 2);
  });
  expectError(validateFixture(fixture), "cycleTargetOverrideReason must be a non-empty string");
});

test("rejects unresolved P1 findings for COMPLETE", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.findings.push(finding({ id: "GAP-CRITICAL", severity: "P1" }));
  });
  expectError(validateFixture(fixture), "cannot retain unresolved P0/P1 findings");
});

test("rejects a blocked high-impact assumption for COMPLETE", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.findings.push(
      finding({
        id: "ASM-CRITICAL",
        kind: "ASSUMPTION",
        severity: "P1",
        classification: "ASSUMPTION",
        status: "BLOCKED",
      }),
    );
  });
  expectError(validateFixture(fixture), "cannot retain unresolved high-impact assumptions");
});

test("requires verified acceptance evidence for COMPLETE", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.acceptanceCriteria[0].status = "PENDING";
  });
  expectError(validateFixture(fixture), "requires verified acceptance criteria");
});

test("rejects a review that references an unknown finding", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.reviews[0].findingIds = ["GAP-UNKNOWN"];
  });
  expectError(validateFixture(fixture), "references an unknown finding id");
});

test("rejects absent review coverage", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.reviews = [];
  });
  expectError(validateFixture(fixture), "reviews must include the INTERNAL PRODUCT lens");
});

test("requires a degradation record for a degraded review", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.reviews[2].status = "DEGRADED";
  });
  expectError(validateFixture(fixture), "with DEGRADED status must reference a degradation");
});

test("rejects invalid residual-risk coverage", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.status = "COMPLETE_WITH_RESIDUAL_RISKS";
    run.findings.push(finding());
  });
  expectError(validateFixture(fixture), "requires at least one residual risk");
});

test("rejects a residual risk that points to a critical finding", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.status = "COMPLETE_WITH_RESIDUAL_RISKS";
    run.findings.push(finding({ id: "GAP-CRITICAL", severity: "P1", status: "CLOSED" }));
    run.residualRisks.push({
      findingId: "GAP-CRITICAL",
      owner: "Engineering",
      rationale: "Incorrectly classified as residual.",
      verification: "Review the release gate.",
      reviewDate: "2026-10-01T00:00:00Z",
    });
  });
  expectError(validateFixture(fixture), "must reference a P2 or P3 finding");
});

test("accepts complete residual-risk coverage", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.status = "COMPLETE_WITH_RESIDUAL_RISKS";
    run.findings.push(finding());
    run.residualRisks.push({
      findingId: "GAP-001",
      owner: "Engineering",
      rationale: "The risk is accepted until the next scheduled change.",
      verification: "Review the control before release.",
      reviewDate: "2026-10-01T00:00:00Z",
    });
  });
  assert.deepEqual(validateFixture(fixture), []);
});

test("rejects secrets in JSON artifacts", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.diagnostic = { apiKey: "abcdefghijklmnop" };
  });
  expectError(validateFixture(fixture), "possible secret detected in run.json");
});

test("rejects secrets in Markdown artifacts", (t) => {
  const fixture = writeBundle(t, ({ markdown }) => {
    markdown["plan.md"] += "\npassword: abcdefghijkl";
  });
  expectError(validateFixture(fixture), "possible secret detected in plan.md");
});

test("rejects persisted live mode", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.mode = "LIVE";
  });
  expectError(validateFixture(fixture), "LIVE mode must use CHAT_ONLY persistence");
});

test("requires explicit gstack opt-in", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.reviews[0].method = "GSTACK";
    run.reviews[0].adapter = "gstack-office-hours";
  });
  expectError(validateFixture(fixture), "using GSTACK requires operatorOptIn: true");
});

test("requires acknowledgement of the gstack side-effect warning", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.reviews.push({
      id: "REV-GSTACK-ENG",
      area: "ENGINEERING",
      applicable: true,
      method: "GSTACK",
      adapter: "gstack-plan-eng-review",
      operatorOptIn: true,
      status: "COMPLETED",
      reason: "The operator requested an independent engineering review.",
      outcome: "No additional findings were raised.",
      findingIds: [],
      degradationIds: [],
    });
  });
  expectError(validateFixture(fixture), "requires sideEffectWarningAcknowledged: true");
});

test("rejects an unrecognized gstack adapter identifier", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.reviews.push({
      id: "REV-GSTACK-ENG",
      area: "ENGINEERING",
      applicable: true,
      method: "GSTACK",
      adapter: "gstack-eng-review",
      operatorOptIn: true,
      sideEffectWarningAcknowledged: true,
      status: "COMPLETED",
      reason: "The operator requested an independent engineering review.",
      outcome: "No additional findings were raised.",
      findingIds: [],
      degradationIds: [],
    });
  });
  expectError(validateFixture(fixture), "must name an approved gstack adapter");
});

test("requires each default review lens to remain internal", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.reviews[0] = {
      ...run.reviews[0],
      method: "GSTACK",
      adapter: "gstack-office-hours",
      operatorOptIn: true,
      sideEffectWarningAcknowledged: true,
    };
  });
  expectError(validateFixture(fixture), "must include the INTERNAL PRODUCT lens");
});

test("accepts an opted-in gstack adapter with a recorded outcome", (t) => {
  const fixture = writeBundle(t, ({ run }) => {
    run.reviews.push({
      id: "REV-GSTACK-ENG",
      area: "ENGINEERING",
      applicable: true,
      method: "GSTACK",
      adapter: "gstack-plan-eng-review",
      operatorOptIn: true,
      sideEffectWarningAcknowledged: true,
      status: "COMPLETED",
      reason: "The operator requested an independent engineering review.",
      outcome: "No additional findings were raised.",
      findingIds: [],
      degradationIds: [],
    });
  });
  assert.deepEqual(validateFixture(fixture), []);
});
