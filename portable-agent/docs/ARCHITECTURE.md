# Architecture

The architecture design keeps root `AGENT.md` as the single source of truth. Host files must direct the agent to `AGENT.md` and may not define parallel policy.

Each adapter pointer contains the repository-relative path to its canonical skill and a clear manual fallback. These files are not proven Codex/Claude-native discovered skills; open the root skill directly when discovery fails or is unverified.
- Root `AGENTS.md` and host-specific instruction files are bootstrap pointers only, with host-specific precedence documented in `docs/INSTALLATION.md`.
- Claude Code direct `AGENTS.md` support depends on CLI version, nearer `CLAUDE.md` files and project-instruction settings; a nearer Claude instruction may take precedence.
- Adapter skill pointers contain repository-relative paths and a manual fallback. They are not proven native-discovery bundles; open the canonical root skill directly when discovery is unverified.
- Workflows provide lifecycle sequences; they do not override safety/approval policy.
- `LEGACY-INVENTORY.md` is provenance/inventory, not active routing or parity evidence.
- No external memory, issue tracker, plugin, service or dependency is required for the portable core. Project/client knowledge belongs in the operator's designated source of truth, not inside this package by default.
- Browser, memory, MCP, hooks, command execution and delegation are optional host capabilities. The agent must verify availability and permission before relying on them, and must report an honest fallback if unavailable.
- Host discovery and tool behavior are product-, harness- and version-specific. Adapter files and setup notes are not host certification until the actual host runtime has been exercised and evidence recorded.
- Host sandbox, trust, approval and permission controls always remain in force; instruction text cannot guarantee or enforce compliance by itself.
