# Skill: web-research

## Purpose
Conduct structured web research using the brightdata MCP — competitive analysis,
technology evaluation, regulatory lookup, and market context — feeding findings
directly into DISCOVER and ANALYZE mode outputs.

## Trigger
Invoke when the operator says:
- "research [topic]", "look up [technology]", "compare [options]"
- "what are competitors doing", "who else does this", "competitive analysis"
- "what does [regulation] require", "GDPR rules for X", "compliance requirement"
- "is [technology] production-ready", "what's the market doing"
- Or when DISCOVER mode surfaces an unknown that needs external validation

## Minimum context required
- The research question or topic
- The client / project context (to frame findings relevantly)
If missing: ask for the specific question and how it relates to the current project.

---

## MCP Tools Available (brightdata)

| Tool | Use for |
|---|---|
| `mcp__brightdata__search_engine` | General web search — technology docs, news, regulations |
| `mcp__brightdata__scrape_as_markdown` | Extract structured content from a specific URL |
| `mcp__brightdata__search_engine_batch` | Multiple searches in one call — parallel research |
| `mcp__brightdata__scraping_browser_navigate` | Interactive browsing for paginated content |

---

## Research Types and Steps

### Type A — Technology Evaluation
When comparing frameworks, tools, or platforms for a design decision:

1. Search for: `[technology] production case studies`, `[technology] vs [alternative]`, `[technology] limitations`
2. Scrape key comparison pages or documentation.
3. Summarise: maturity, adoption, known issues, licensing, community health.
4. Map findings to the client's NFRs and constraints.
5. Feed into `solution-design` skill as ADR input.

### Type B — Competitive Analysis
When the client wants to understand what similar products exist:

1. Search for: `[product category] market leaders`, `[competitor] features`, `[product] pricing`
2. Extract: key features, target market, pricing model, known gaps.
3. Produce a comparison table: Feature / Competitor A / Competitor B / Client's target.
4. Flag differentiation opportunities as REC- entries.

### Type C — Regulatory / Compliance Lookup
When a project handles regulated data or operates in a specific jurisdiction:

1. Search for: `[regulation] requirements [country/sector]`, `[regulation] 2024 updates`
2. Scrape official regulatory body sources where available.
3. Extract: obligations, timelines, penalties, exemptions.
4. Feed directly into `security-review` skill as compliance input.

### Type D — Market / Industry Context
When the operator needs background on an industry or problem space:

1. Search for: `[industry] digital transformation trends`, `[problem space] best practices`
2. Summarise: key trends, pain points, typical solutions, common failure modes.
3. Use to validate or challenge client requirements in CHALLENGE mode.

---

## Output format

```
WEB RESEARCH: [Topic]
Client: [name] | Project: [name] | Date: [YYYY-MM-DD] | Type: [A/B/C/D]
---
Research question: [What was asked]
Sources searched: [N queries / N pages scraped]

Findings:
[Structured summary — tables where applicable]

Relevance to project:
- [Finding] → [How it affects requirements / design / risk]

Generated entries:
- REQ- / RISK- / REC- / ADR- as appropriate

Next: [feed into which skill — solution-design / security-review / gather-requirements / etc.]
```

---

## Quality checklist

- [ ] Research question clearly scoped before searching?
- [ ] Multiple sources consulted — no single-source findings treated as fact?
- [ ] Findings mapped to project impact — not just raw notes?
- [ ] All generated REQ-/RISK-/REC- entries logged with IDs?
- [ ] Regulatory findings cross-referenced to official sources where possible?

## Failure exit
"Cannot research without a topic or question. Provide the research question and project context."
