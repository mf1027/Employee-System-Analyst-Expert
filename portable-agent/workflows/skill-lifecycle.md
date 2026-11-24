# Skill Creation / Modification Lifecycle

1. Confirm target agent/runtime, use case, trigger, intended behavior, boundaries and acceptance.
2. Search existing skills and role instructions first; prefer extending or clarifying an existing capability over duplicate skill creation.
3. Check conflict/overlap: triggers, authority, precedence, output, safety rules, duplicate procedures, adapter conventions.
4. Define canonical single source, portable format, minimal metadata, steps, inputs, outputs, exceptions, examples and references.
5. Keep skill self-contained but lean; load resources progressively. No embedded secrets, environment-specific assumptions or false tool availability.
6. Add adapter pointer(s) only as required by actual host conventions; verify pointer and host path.
7. Add routing fixture and negative/conflict cases; validator checks metadata, links, manifest and adapter parity.
8. Test skill selection/behavior separately: static checks are not agent-behavior proof. Use live host evaluation only where accessible.
9. Document version, change rationale, compatibility and rollback.
10. Update canonical registry; do not create parallel catalog.
