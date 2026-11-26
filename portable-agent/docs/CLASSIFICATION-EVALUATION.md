# Semantic Skill Classification Evaluation

## Purpose

The deterministic resolver validates explicit selections. It does not decide what a user means. This evaluation measures the missing semantic step: whether a specific model, with a specific host and prompt context, maps representative natural-language requests to the expected primary intent, specialists and support skills.

## Procedure

1. Use a clean disposable workspace with the exact package version under test.
2. Record host, host version, model/provider, model version, system/developer prompt version, enabled tools and relevant settings.
3. Give the model each `evals/routing-cases.json` input in a fresh context. Ask it to return a JSON array with `id`, `intent`, `specialists`, `support`, `dominant_intent`, `primary_deliverable`, `trigger_evidence`, `specialist_evidence`, `support_output_need`, `excluded_candidates` and `uncertainty` for every case. The model must not see expected answers during the run. Require the complete decision record fields shown above; specialist/support evidence keys must exactly match selected IDs.
4. Save the output as a JSON file. Do not manually correct the model output before scoring.
5. Run `python tools/evaluate_classification.py path/to/model-classifications.json`.
6. Preserve raw prompts, outputs, score, failures and environment metadata. Repeat at least three runs per model/host to expose variance.
7. Add any observed misroute as a regression fixture before changing routing policy.

## Scoring and release gates

- Exact intent, specialist and support agreement is required for a fixture to pass.
- The resolver requires a decision record: dominant intent, primary deliverable, trigger evidence, evidence for each specialist, distinct output need for each support skill, excluded candidates and uncertainty. It then validates each candidate classification to ensure its workflow and final skill list match the fixture.
- Unknown IDs, selection overflow, or resolver rejection are failures.
- Report accuracy per run and per fixture; do not average away a safety-critical misroute.
- A routing score alone is not production certification. Host instruction discovery, tool permission enforcement, prompt-injection behavior, continuation and approval boundaries require separate live tests.

## Current evidence

The package contains 30 natural-language routing fixtures. The offline suite proves that fixture metadata is internally consistent and that each expected classification resolves to the expected workflow and skill list. **No model has been evaluated by this harness yet.** A candidate JSON output from a real host/model is required to produce a semantic classification score.
