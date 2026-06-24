# Skill: api-contract-design

## Purpose
Design the **API contract** that sits between the database/domain and the frontend. After schema
design, the very next question is always "what endpoints expose this, and what do they take and
return?" — and today that's done freehand. This skill produces a precise, versioned contract:
routes, request/response shapes, status codes, error formats, auth, and pagination — the
agreement both backend and frontend build against so they can work in parallel without guessing.

This is design, not code: the contract is the specification a developer implements. The employee
defines the interface and hands off; it does not write the controller.

## Trigger
Invoke when the operator says "design the API", "what endpoints do we need", "REST contract",
"GraphQL schema", "API spec", "request/response shapes", "OpenAPI", "gawa tayo ng API design".
Natural chain: DESIGN mode after the data model is set, or after `database-admin` locks a schema.

## Minimum context required
- The domain/data model the API exposes (entities, relationships) — usually the locked schema.
- Style: REST or GraphQL (ask if unstated — it changes the whole contract shape).
- Consumers and their needs (web, mobile, third-party) — drives pagination, field selection, auth.

---

## What the contract defines

| Element | What to pin down |
|---|---|
| **Resources / operations** | Nouns (REST) or types+queries+mutations (GraphQL); map to domain entities |
| **Routes / signatures** | `GET /programs/{id}/projects`, or `query programs(filter): [Program]` |
| **Request shape** | Path/query params, body schema, required vs optional, types, validation rules |
| **Response shape** | Success body schema, the envelope (data/meta/errors), field types |
| **Status codes** | 200/201/204/400/401/403/404/409/422/500 — when each applies |
| **Error format** | One consistent error envelope: code, message, field-level detail |
| **Auth** | Who can call it, what scope/role, how the token is passed |
| **Pagination / filtering / sorting** | Cursor vs offset, filter params, sort syntax, limits |
| **Versioning** | URL (`/v1/`) or header; the deprecation policy |
| **Idempotency & concurrency** | Idempotency keys on writes; optimistic concurrency (ETag/version) where it matters |

---

## Steps
1. Confirm REST vs GraphQL and the consumers. State the choice and *why* in one line.
2. Map each domain entity/use case to operations. For REST, keep resources noun-based and verbs in
   the HTTP method; for GraphQL, separate queries from mutations and define the type graph.
3. For each operation, specify request + response shapes with concrete types, required/optional, and
   validation rules. Reuse the domain field names from the schema — don't rename at the boundary
   without reason.
4. Define the **global conventions once**: error envelope, pagination style, auth scheme, versioning.
   Apply them uniformly — inconsistency here is the most expensive thing to fix later.
5. Name the edge cases per endpoint: not-found, conflict, validation failure, unauthorized, empty list.
6. Apply the **triple lens**: SA (does every relevant `REQ-` have an endpoint?), PM (versioning and
   breaking-change policy in place?), DBA (do list endpoints map to indexable queries — flag any that
   force a full scan or N+1).
7. Author as Markdown (and OpenAPI/SDL on request via document-skills). Save to the project
   `deliverables/documents/`. Surface at least one `REC-`.

---

## Output format
```
API CONTRACT — [project] — [YYYY-MM-DD]
Style: REST | GraphQL    Version: v1    Auth: [scheme]

GLOBAL CONVENTIONS
  Error envelope: { code, message, details[] }
  Pagination:     cursor-based, ?limit= &cursor=
  Auth:           Bearer JWT, scope per endpoint

[METHOD] /path/{param}                                  Auth: [role/scope]
  Purpose:   [what it does] — traces REQ-…
  Request:   path {…}  query {…}  body { field: type (req/opt, validation) }
  Response:  200 { … }   | errors: 400 / 401 / 404 / 409 / 422
  Edge:      [not-found / conflict / empty / unauthorized]
  DBA note:  [index/query implication — or "indexed by PK"]

[… more operations …]

REC-NNN: [contract-level recommendation — e.g. add idempotency keys on POST /payments]
```

Close with **Decisions needed / Open questions / Next steps**.

## Quality checklist
- [ ] REST vs GraphQL chosen with a stated reason
- [ ] Error envelope, pagination, auth, versioning defined once and applied consistently
- [ ] Every operation has request + response shapes with types and validation
- [ ] Edge/error cases named per endpoint (not just the happy path)
- [ ] DBA lens: list/filter endpoints checked against indexes; N+1 and full-scan risks flagged
- [ ] Every relevant `REQ-` maps to an operation; at least one `REC-` surfaced

## Failure exit
"I can't pin the contract without the data model and the REST-vs-GraphQL call — those decide every
shape below. Give me the locked schema (or point me to it) and the API style, and I'll draft it."
