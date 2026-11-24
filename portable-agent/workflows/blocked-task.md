# Blocked / Repeated-Failure Workflow

1. Stop repeating an identical failed action.
2. Record objective, blocker, attempts, exact error/output, environment, and what each attempt changed.
3. Classify blocker: missing input/authority, access/tool, dependency, environment, design uncertainty, test failure, external outage, safety, or scope.
4. Separate verified root cause from hypotheses; propose discriminating checks.
5. Set a retry budget: after two materially different unsuccessful attempts, stop and escalate unless the user explicitly requests a further bounded investigation.
6. Do not bypass permissions, disable safeguards, conceal failure, or invent workarounds that increase risk.
7. Offer safe options with prerequisites, trade-offs, owner and expected evidence.
8. Mark BLOCKED with one concrete unblock action; checkpoint state and resume only when conditions change.
