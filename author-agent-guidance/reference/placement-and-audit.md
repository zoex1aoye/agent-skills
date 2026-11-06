# Placement and audit matrix

Use this matrix when deciding where repository knowledge belongs.

| Knowledge | Best location | Why |
|---|---|---|
| "All API errors use envelope X" | Schema/type or API guide; always-on constraint only if every task needs it | Detailed format belongs at its canonical reference |
| "Do not import implementation packages across domains" | Architecture rule plus ArchUnit/test if possible | Executable enforcement prevents drift |
| "Java files use formatter X" | Formatter configuration | Tools should enforce deterministic style |
| "When changing auth, inspect token refresh call sites" | Task skill or path-scoped rule | It is attached to a specific change class |
| "This repo uses pnpm and `pnpm test`" | Always-on repository instructions | Needed before most implementation work |
| "Legacy adapter patterns and migration edge cases" | Skill reference | Only needed during that migration |
| "Five-step release checklist" | Skill or script | Repeatable procedural sequence |
| "Project-specific risk sign-off names" | Project policy, not a generic skill | Local ownership fact |

## Duplication audit

For each candidate instruction, record:

| Check | Action |
|---|---|
| Enforced by a tool | Remove the prose or replace it with a pointer |
| Needed for every task | Keep only the minimum in always-on instructions |
| Needed only for some paths | Move to a path-scoped rule |
| Needed only for a task outcome | Move to a skill |
| Needed only in one branch of a skill | Move to a reference |
| Deterministic and repeatedly typed | Move to a tested script |
| Project-only fact | Keep it in the project, not a reusable skill |

## Conflict rules

- Executable project configuration wins over a stale written command.
- A narrower project rule wins over a generic skill default.
- If two canonical documents disagree, stop and ask which one is authoritative.
- When migrating a rule, add it to the destination before deleting the source.
- Preserve user-owned uncommitted changes while reorganizing guidance.
