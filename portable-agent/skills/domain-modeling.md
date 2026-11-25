# Domain Modeling

## Purpose
Model the business domain — entities, relationships, behaviors, rules, and terminology — using structured analysis. Produce a shared vocabulary and entity model that drives database design, API contracts, and business logic.

## When to use
Invoke when asked to model the domain, define entities, map business rules, create a data model, establish a glossary, or when requirements analysis reveals complex business concepts that need structured representation.

## Prerequisites
- Business domain description: what the system does, who uses it, what concepts are central.
- Requirements or stakeholder input describing the business rules and relationships.
- Existing data models or glossaries (if available).

## Procedure

1. **Read context.** Review requirements, existing data models, glossaries, and business documentation.
2. **Build the glossary:**
   a. Identify key business terms used by stakeholders.
   b. Define each term precisely — one definition per term, no synonyms without explicit mapping.
   c. Note terms that are ambiguous or used differently by different stakeholders.
   d. This glossary becomes the canonical vocabulary for the project.
3. **Identify entities:**
   a. List the core business objects (nouns) that the system must represent.
   b. For each entity: purpose, lifecycle (created/active/archived/deleted), key attributes.
   c. Distinguish entities (have identity and lifecycle) from value objects (defined by attributes, no identity).
4. **Map relationships:**
   a. Cardinality: 1:1, 1:N, M:N — with direction and optionality.
   b. Ownership: which entity controls the lifecycle of related entities?
   c. Referential integrity: what happens when a parent is deleted?
   d. Temporal relationships: do relationships change over time?
5. **Extract business rules:**
   a. Invariants: conditions that must always be true (e.g., "an order must have at least one item").
   b. Constraints: limits on values, states, or transitions (e.g., "status can only move from Draft to Submitted, never backward").
   c. Calculations: derived values and their formulas.
   d. Authorization rules: who can create, read, update, delete each entity?
6. **Model state transitions** for entities with lifecycle:
   - Valid states and allowed transitions.
   - Events or actions that trigger each transition.
   - Guards: conditions that must be true for a transition to occur.
7. **Validate against requirements:** every functional requirement should map to at least one entity, relationship, or rule in the domain model.
8. **Present the model** for review. Wait for confirmation before using as implementation input.

## Output contract
- Glossary: Term | Definition | Synonyms (if any) | Notes
- Entity model: Entity | Purpose | Key Attributes | Lifecycle | Owner
- Relationship map: Entity A | Relationship | Entity B | Cardinality | Optionality
- Business rules: ID | Rule | Type (Invariant/Constraint/Calculation/Authorization) | Affected Entities
- State transition diagrams (for stateful entities).

## Safety and approval gates
- Domain modeling is analysis — do not create database tables or code from the model without authorization.
- Distinguish confirmed business rules from analyst interpretation.
- Flag ambiguous or contested terminology explicitly.
- Do not invent business rules not stated by stakeholders or found in documentation.

## Verification
- Every entity has a clear purpose and lifecycle.
- Relationships have defined cardinality and direction.
- Business rules are traceable to requirements or stakeholder statements.
- Glossary terms are used consistently throughout the model.
