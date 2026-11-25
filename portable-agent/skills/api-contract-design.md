# API Contract Design

## Purpose
Design, review, and document API contracts — endpoints, request/response schemas, error codes, versioning, and backward compatibility. Ensure APIs are consistent, well-documented, and resilient to change.

## When to use
Invoke when asked to design an API, review API contracts, document endpoints, assess backward compatibility, or when architecture work produces external-facing interfaces.

## Prerequisites
- The system or feature the API serves.
- Known consumers (frontend, mobile, third-party integrations).
- Existing API conventions or style guide (if any).

## Procedure

1. **Read context.** Review architecture, requirements, existing API documentation, and known consumers. Identify existing conventions (naming, versioning, error format, auth model).
2. **Define the resource model.** Identify the domain objects and their relationships:
   - Resources (nouns, not verbs).
   - Relationships: 1:1, 1:N, M:N.
   - Lifecycle: what creates, reads, updates, deletes each resource?
3. **Design endpoints:**
   a. URL structure following conventions (REST, RPC, or hybrid — match existing patterns).
   b. HTTP methods: GET (read), POST (create), PUT/PATCH (update), DELETE (remove).
   c. Request schemas: required vs optional fields, types, constraints, defaults.
   d. Response schemas: success shape, pagination, included/embedded resources.
   e. Status codes: standard HTTP codes with consistent semantics.
4. **Error contract:**
   - Consistent error response shape across all endpoints.
   - Machine-readable error codes (not just HTTP status).
   - Human-readable messages (developer-facing, not user-facing).
   - Validation error details pointing to specific fields.
5. **Versioning strategy:**
   - URL-based, header-based, or content-negotiation — match existing practice.
   - Breaking vs non-breaking change classification.
   - Deprecation lifecycle with timelines.
6. **Backward compatibility check** (for changes to existing APIs):
   - Additive changes (new optional fields, new endpoints) are safe.
   - Removals, renames, type changes, required-field additions are breaking.
   - Assess consumer impact; recommend migration path for breaking changes.
7. **Document the contract.** Produce endpoint specifications with examples.

## Output contract
- Resource model: entities, relationships, lifecycle.
- Endpoint specification table: Method | Path | Description | Auth Required | Request Schema | Response Schema | Status Codes
- Error response contract with example.
- Versioning and deprecation policy.
- Breaking change assessment (for modifications).

## Safety and approval gates
- API design is analysis/planning — do not implement without authorization.
- Never remove or rename a field in a published API without version bump and migration plan.
- Flag any endpoint that handles PII, financial data, or authentication credentials.
- Ensure auth/authz requirements are explicit for every endpoint.

## Verification
- Every endpoint has defined request/response schemas with examples.
- Error contract is consistent across endpoints.
- Breaking changes are identified and have migration paths.
- Auth requirements are explicit, not assumed.
