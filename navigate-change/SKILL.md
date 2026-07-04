---
name: navigate-change
description: >-
  Use before multi-file edits described by concept (not file paths) in large or legacy repos — e.g. auth token flow, payment retry, duplicate validators across modules. Runs sparse grep/git co-change navigation, on-demand structure analysis (LSP when available, grep fallback otherwise), and parallel-implementation drift detection. Proactively run before blind greps. Skip when the user named exact files or the edit is a trivial single-line fix.
---

# Navigate Change — sparse anchors, git signals, on-demand structure analysis

This skill encodes how an experienced developer scopes a change in a large, technical-debt-laden codebase: **not** by building a full static call graph upfront, but by following *sparse, pain-shaped anchors* — naming, git history, recent churn — and doing *on-demand* deep-dives with structure tools (LSP when your runtime has them; grep/read fallback otherwise) only where it actually matters.

The goal: before writing any code for a concept-described change, produce a **candidate file set** that is accurate enough to act on, and a **relationship map** tight enough to avoid surprise blast radius.

This skill is **language-agnostic** and **runtime-agnostic**. It works on Java, TypeScript, Python, Go, Rust, etc. — anywhere you have text search, git, and either an LSP tool or grep/read. Adapt exact tool flags to your language and agent; the signal layers and their order do not change.

## Precondition: this skill needs git

**Phase 2 (History) is the core of this methodology.** It depends on `git log` / `git blame` to reveal logical coupling that static analysis cannot. Before starting, verify the project is under version control:

```bash
git rev-parse --is-inside-work-tree
```

- **If yes** → run the full 6-phase workflow below.
- **If no** (not a git repo, or a fresh repo with ~0 history) → the History layer is unavailable. Fall back to the **degraded flow** described at the end of this file (Concept + Structure layers only). Be explicit with the user that without git history, hidden coupling will be harder to find, and lean harder on Phase 3 structure expansion + the "bail out and ask" path.

Do not silently run the full workflow on a non-git project — Phase 2 commands will error out and waste turns.

## When to use

Trigger this skill when **any** of these hold:

- The change is described by **concept** ("the login auth token flow", "the payment retry logic", "permission check") rather than by explicit file paths.
- The project is large or has known technical debt (duplication, scattered responsibilities, multiple implementations of the same concept).
- You're about to do a broad `grep`/`glob` without knowing which results matter — **stop and run this workflow instead**.
- A change *might* touch more than one file but you don't yet know which.

Skip this skill when the user already pointed at the exact file(s), or it's a trivial single-spot edit.

## Core principle: signals, not indexes

Do **not** pre-build a graph of the whole project. Do **not** index everything. Instead, gather cheap signals first and spend expensive tools (LSP hierarchy, reading source) only on the small candidate set that survives the cheap filters.

Four signal layers, applied **in order, narrowing at each step**:

| Layer | Signal | Cost | What it tells you |
|-------|--------|------|-------------------|
| 1. Concept | naming, identifiers, docstrings | cheap | where the concept *might* live |
| 2. History | git co-change, churn, recency, blame | cheap | which of those actually move together & recently |
| 3. Structure | imports, call/def via LSP or grep — on-demand | medium | real dependency edges for the survivors |
| 4. Source | read the 3–8 surviving files | medium | ground truth, confirm before editing |

**Never skip to layer 4 on the whole project.** Each layer must narrow the set for the next.

## The workflow

Run these phases. Output the artifacts named in each phase — they feed the next.

### Phase 0 — Restate the change as a concept query

Before searching, restate the user's request as a **concept query**: a short noun phrase + a one-line "what changes" description, plus a guess at 3–6 candidate identifiers/terms (the concept may be named inconsistently across the codebase — that inconsistency *is* the signal).

> Example: request "refactor the login auth token flow"
> → concept: `auth-token`
> → change: "how login tokens are issued/validated/refreshed"
> → candidate terms: `token`, `accessToken`, `jwt`, `TokenManager`, `TokenService`, `verifyToken`, `createToken`, `refreshToken`, `AuthFilter`, `login`

Output this as a fenced block so the user can sanity-check before you burn tool calls.

### Phase 1 — Concept layer: find *where it might live*

Goal: a **candidate file set** (raw, will be pruned). Use cheap text tools only.

1. `grep`/ripgrep for each candidate term. For polysemous tokens (like `token`), require a second anchor — e.g. `token` AND (`auth`|`login`|`jwt`) — don't accept bare `token` hits as candidates. Use `--type` to scope to the project's language(s) when known.
2. `glob` for files whose *name* carries the concept (e.g. `**/*Token*`, `**/*Auth*`, `**/auth/**`). Naming is a strong signal in legacy code: the maintainer who last touched it usually named the file after the concept they were thinking about. Don't hardcode a file extension — match the project's actual extensions.
3. **Optional — LSP `workspaceSymbol`** when your runtime exposes it: search class/function names matching the concept. Catches declarations text grep misses inside generated/minified files. If no LSP tool exists, skip — Phase 1 still works with grep + glob alone.
4. **De-duplicate** to a file list. Do **not** read any of them yet.

Cap the raw candidate set at ~30 files. If it's bigger, your concept query is too loose — go back to Phase 0 and add anchors.

### Phase 2 — History layer: which candidates actually move together & recently

This is the layer most agents skip, and it's the highest-signal one for legacy code. The git history tells you the *real* logical coupling — the things that change together are coupled, regardless of what the call graph says.

Run these on the Phase-1 candidate set (and only on them — git log on the whole repo is noise):

1. **Co-change (recent).** For each candidate file, `git log --oneline -20 -- <file>`, then look for **commits that touch ≥2 of your candidate files simultaneously**. Those clusters are your real "logical unit." This is gold: it reveals that the active token manager, a legacy token util, and an auth filter are changed together even if no static edge connects them.
2. **Recent churn.** `git log --since="3 months ago" --name-only --format=` over the candidate set. Files changed recently are more likely the *current* implementation; untouched-for-2-years files may be dead/legacy paths.
3. **Recency vs. concept.** If a candidate file hasn't been touched in the window the user cares about (recent feature work), demote it. If two files always commit together, treat them as one unit.
4. **Blame the key line.** For the 2–3 most central candidates, `git blame -L <line>,<line>` on the entry-point line — tells you *when* and *why* (commit msg) the current logic landed. Often reveals "this is the one we switched to after the 2023 incident."

Output a **logical-unit clustering**: groups of files that move together, each tagged `active`/`legacy`/`dead-suspected`.

### Phase 2b — Parallel-implementation detection (run when Phase 1 surfaces ≥3 files that look similar)

Phase 2's co-change logic assumes "files that change together are coupled." But there's a different pattern this misses: **parallel implementations** — N files that implement the *same* concept with *intentional* or *accidental* drift (6 versions of an edit form, 3 retry implementations, duplicate validators across modules). These files:

- May NOT co-change (developers often update only a subset → the drift bug).
- Have similar symbol surfaces (Phase 3 symbol scan won't distinguish them).
- Their **differences are the whole point** — "they're similar" is useless; "file A validates X but file B skips X" is the deliverable.

**Detection triggers** (run this sub-phase if any hold after Phase 2):
- Phase 1 returned ≥3 candidates whose filenames or paths cluster around the same concept stem (e.g. `ProjectEditBasic.vue`, `ProjectEditAdvanced.vue`, `ProjectEditAdmin.vue`).
- Phase 2 co-change is *weak* (the candidates rarely commit together) yet churn shows they're all *active* — the signature of parallel-but-drifting implementations.
- The user explicitly mentioned duplicates/variants in their request.

**What to do:**
1. **Pairwise diff via git, not by eye.** For every pair in the cluster, run `git diff --no-index <fileA> <fileB>` (or `diff -u` if not tracked). Reading 6 similar files in context and eyeballing differences is exactly what fails — the LLM will conflate them. The diff output isolates the real divergences.
2. **Extract a divergence matrix.** For each differing hunk, classify it:
   - **logic divergence** (different condition / branch / formula) — the dangerous kind, likely a drift bug or an intentional per-variant rule. Flag for the user.
   - **cosmetic divergence** (variable names, formatting, comments) — ignore.
   - **structural divergence** (extra/missing fields, extra/missing steps) — flag; often a forgotten sync.
3. **Per-file blame on the divergent lines.** For each logic-divergence hunk, `git blame -L <range>` on both sides — tells you *when* each side diverged and *why* (commit msg). This reveals whether the divergence was intentional ("admin form needs extra field") or accidental ("forgot to sync this change to the other 5 forms").
4. **Do NOT merge them into one logical unit.** Parallel implementations stay as N entries in the output; the divergence matrix is the artifact that connects them.

Output a **divergence matrix** (in addition to the logical-unit clustering): rows = divergent logic points, columns = the N files, cells = what each file does at that point. This is the artifact the user actually needs before editing.

### Phase 3 — Structure layer: on-demand, only on survivors

Now — and only now — map *real* edges for the **active** files from Phase 2 (usually 3–8).

**Pick the Phase 3 approach for your runtime** — see [reference/tools.md](reference/tools.md):
- **LSP available** (MiMo-Code/OpenCode, some IDE-integrated agents): `documentSymbol`, `incomingCalls`, `outgoingCalls`, `references`.
- **No LSP tool** (Cursor, Codex, most CLI agents): grep/read fallback — symbol declarations, reference search, import tracing.

Regardless of runtime:

1. Get each survivor's exported/public surface without reading the whole file.
2. For the 1–3 most central symbols, find who depends on them (blast radius up) and what they depend on (blast radius down).
3. Find call sites / references you missed in Phase 1.
4. **Stop expanding** as soon as you hit framework/boundary code (controllers calling into a web framework, ORM repos, etc.) — that's not part of the change.

Goal of this phase: a **relationship map** — for each surviving logical unit, its callers and callees within the app (not the framework).

### Phase 4 — Source layer: read the survivors & confirm

Read the 3–8 surviving files. Confirm the change is actually where you think, mark the exact edit sites, and note any **surprise coupling** (a file you didn't expect that shares the logic). This is also where you decide: is this one change, or N parallel changes across the duplicated implementations?

**If Phase 2b flagged parallel implementations:** do NOT read all N files into context at once and attempt to compare mentally — that's the failure mode Phase 2b's diff step exists to prevent. The divergence matrix from Phase 2b is your comparison substrate; use it to read *only* the divergent regions of each file, not the whole files. Confirm each divergence is real (not a false positive from diff context) and classify it as intentional rule vs drift bug.

### Phase 5 — Output the navigation result

Produce this artifact before writing any code. The user should be able to review *just this* and approve/correct:

```
## Change navigation: <concept>

**Logical units (groups that change together):**
1. <unit name> — files: [...] — status: active|legacy|dead
   - entry point: <file:line>
   - callers (blast radius up): <files/symbols>
   - callees (blast radius down): <files/symbols>
2. ...

**Parallel implementations (if Phase 2b ran):**
Divergence matrix — rows are logic points, columns are the N parallel files:

| logic point | <file A> | <file B> | <file C> | ... |
|-------------|----------|----------|----------|-----|
| validation rule | checks X | skips X | checks X | |
| save payload | sends field F | omits F | sends F | |
| ... | | | | |

Per-divergence verdict: intentional (rule differs by variant) | drift (likely forgot-to-sync) | unclear (ask user)

**Change plan:**
- Unit 1: edit <file:line> — <what changes>
- Unit 2: edit <file:line> — <what changes>
- [If parallel impls:] Propagate change to: <list which of the N files need this change, which don't, and why>

**Risk / open questions:**
- <unexpected coupling discovered>
- <file that looks dead but isn't — why>
- <drift divergences that look like forgotten syncs — confirm with user before treating as bugs>
```

Only after this is reviewed, proceed to implementation.

## Anti-patterns (do NOT do these)

- **Blind grep then immediately read top hits.** This is the failure mode this skill exists to fix. Grepping `token` across a 500k-LOC repo returns thousands of hits; reading the first 5 is random.
- **Pre-building a full call graph.** Over-engineered for an MVP, slow, and most of the graph is irrelevant to any specific change.
- **Skipping the git layer.** The git history is the *single highest-signal* datasource for legacy coupling. Skipping it is the #1 reason agents miss the "third place" that a concept's logic lives.
- **Trusting naming alone.** Phase 1 gives candidates; without Phase 2 you can't tell the active `TokenManager` from a dead `OldTokenManager`.
- **Expanding structure analysis into framework code.** Following callers into web-framework / ORM internals burns tokens for nothing. Stop at app boundaries.
- **Reading files before the candidate set is pruned.** Reading is the most expensive operation. Always narrow first.
- **Running the full workflow on a non-git project.** Phase 2 will error. Check the precondition first and use the degraded flow.
- **Eyeballing N similar files to find differences.** When ≥3 files implement the same concept, reading them all into context and comparing mentally is exactly what fails — the LLM conflates near-identical code. Use `git diff --no-index` / `diff -u` (Phase 2b) to isolate divergences *before* reading. The diff is the comparison; the read is only to confirm each divergence.

## When to bail out and ask

If after Phase 2 the candidate set is still >15 files with no clear clustering, **stop and ask the user** for one of:
- an example commit that did a similar change (→ instantly reveals the real cluster via co-change),
- a file they know is involved (→ seed for Phase 3 expansion),
- a feature flag / module name that scopes the search.

Don't flail. A 2-second human hint beats 20 minutes of blind expansion.

## Degraded flow (no git / negligible history)

When the precondition check fails, you lose Phase 2. To compensate, the remaining layers must do more work — but they are weaker without git, so set expectations:

1. **Phase 0** as usual.
2. **Phase 1** as usual, but tighten the candidate cap to ~20 (you no longer have churn to prune, so keep the input set smaller).
3. **Skip Phase 2.** Instead, ask the user directly: "Is there an older/legacy implementation of `<concept>` I should be aware of?" — surface the "third place" question explicitly, since git can't.
4. **Phase 3** does more: run structure analysis on *every* Phase-1 survivor (not just 1–3 central ones), because you have no co-change signal to tell you which symbols are central. Watch the tool-call budget.
5. **Phase 4 / Phase 5** as usual.

Tell the user up front: "This project has no git history, so I can't detect hidden coupling via co-change. I'll lean on structural analysis instead, but I may miss legacy/duplicate implementations — flag any you know of."

**Parallel implementations in degraded flow:** Phase 2b's diff step still works without git — use `diff -u <fileA> <fileB>` directly. Only the blame step (intentional-vs-drift classification) is lost; ask the user to classify each divergence instead.

## Reference files

Read these **when you reach the relevant phase** — do not load them at skill start:

- [reference/tools.md](reference/tools.md) — exact commands and tool calls per phase, with per-runtime Phase 3 mappings (Cursor, Claude Code, Codex, MiMo-Code/OpenCode).
- [reference/signals.md](reference/signals.md) — how to interpret git and structure signals (churn, co-change, blame, callers/callees).
