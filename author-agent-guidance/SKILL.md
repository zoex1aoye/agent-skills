---
name: author-agent-guidance
description: >-
  Audit and organize repository guidance for AI agents. Decide whether knowledge
  belongs in always-on project instructions, path-scoped rules, task skills,
  references, scripts, or executable enforcement. Use when authoring AGENTS.md,
  skills, or rules, reducing duplicated guidance, fixing over- or under-triggering,
  or turning a repeated workflow into reusable assets. Not for ordinary product
  documentation or one-off task notes.
---

# Author Agent Guidance

Make repository guidance discoverable, executable, and maintainable. The goal
is not to write more instructions; it is to put each durable fact and workflow
at the narrowest layer where agents will reliably encounter it.

## First audit the existing system

Before adding a file, inspect the current repository:

- repository-level instructions such as `AGENTS.md`, `CLAUDE.md`, or the active
  platform equivalent;
- path-scoped rules and their matching semantics;
- available skills and their descriptions;
- linters, formatters, type checks, tests, CI checks, hooks, and generation
  tools that already enforce or encode the same rule;
- project docs and reference material.

Search for duplicates, conflicting commands, stale paths, and guidance that is
already enforced by tooling. Preserve working project-specific decisions unless
the user explicitly asks to change them.

## Placement ladder

Use the earliest layer that fits:

1. **Executable enforcement** — compiler, linter, formatter, type checker, test,
   schema, CI rule, or code generation.
2. **Always-on repository context** — only facts needed for every task, such as
   repository identity, module boundaries, build commands, and hard constraints.
3. **Path-scoped rule** — conventions that apply only when editing a directory,
   language, or file type.
4. **Task skill** — a repeatable workflow entered when the user requests a
   particular outcome.
5. **Reference inside a skill** — detailed procedures, schemas, examples, or
   variants needed only in certain branches of that workflow.
6. **Script or asset** — deterministic operations, templates, or generated
   outputs that should be reused rather than retyped.

Read [reference/placement-and-audit.md](reference/placement-and-audit.md) for the
decision matrix and examples.

## Authoring workflow

1. **Name the task intent.** Describe what outcome the agent is trying to
   produce, not merely which technology it uses. A technology name is acceptable
   when the task itself is inseparable from that technology.
2. **Identify the trigger boundary.** Write `name` and `description` around
   situations where the guidance changes decisions. Add an exclusion only when
   nearby requests would otherwise be misrouted.
3. **Extract only non-obvious structure.** Capture required inputs,
   decision points, invariants, stop conditions, outputs, and validation.
   Remove generic advice the agent already knows.
4. **Separate facts from procedure.** Project facts belong in project
   instructions or references; reusable procedure belongs in a skill. Do not
   disguise one project's vocabulary, paths, credentials, or versions as a
   universal workflow.
5. **Apply progressive disclosure.** Keep `SKILL.md` focused on routing,
   essential constraints, and the main workflow. Move detailed schemas,
   branching procedures, examples, and templates into resources read on demand.
6. **Verify executable details.** Run commands, validate frontmatter and scripts,
   confirm paths exist, and test link targets. If the target environment is not
   available, state what remains unverified.
7. **Check discovery.** Test that realistic requests select the intended skill,
   and that unrelated requests do not. Adjust the description before expanding
   the body.
8. **Register in the repository.** Update any skill index or catalog and include
   every referenced file required by the repository's install mechanism.

When the environment provides a skill initializer or validator, use it. Do not
copy a scaffold validator from another platform and assume its semantics apply.

## Writing rules

- Prefer a verifiable action over “be careful”, “follow best practices”, or
  “ensure quality”.
- Keep one authoritative source for each rule or fact.
- State when project-specific guidance overrides generic defaults.
- Make approvals and destructive boundaries explicit when the workflow can
  mutate external state.
- Do not include secrets, personal machine paths, transient branches, or
  environment-specific credentials.
- Do not copy a long external manual. Summarize the decision relevance and link
  only when the current workflow needs the source.
- Do not impose a fixed document count, line count, team role, or branch naming
  scheme on unrelated projects.

## Validation checklist

- [ ] The description makes the trigger and exclusions legible.
- [ ] The selected layer is the narrowest reliable one.
- [ ] Existing guidance was checked for duplication and conflict.
- [ ] Project facts are separated from reusable task logic.
- [ ] Commands and paths were verified in the target environment or marked
      unverified.
- [ ] Required resources are linked from the entrypoint and fit in the install
      manifest.
- [ ] The skill does not silently expand authorization or scope.
- [ ] At least one realistic request would select it for the right reason.
