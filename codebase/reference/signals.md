# Signal interpretation guide

How to read the raw outputs of Phase 2 (git) and Phase 3 (LSP). The signals only help if you know what they're actually telling you — and what they're *not*.

This guide is language-agnostic. Where examples mention a framework (web framework, ORM, DI), treat it as a placeholder for whatever framework your project actually uses — the stop-expansion and boundary heuristics apply identically regardless of language or framework.

## Git signals

Git is the highest-signal datasource for legacy code because it records **actual human behavior**: what people really changed, together, when stressed, under deadline. That behavior reveals logical coupling that static analysis cannot — because it captures intent and co-responsibility, not just syntax.

### Co-change = logical coupling (the core signal)

**What it is:** two files that appear together in the same commit more than once.

**Why it matters:** in a clean codebase the call graph and the co-change graph roughly agree. In a technical-debt codebase they **diverge** — and the divergence is exactly where the interesting stuff is:

- Two files with **no static edge** that always commit together → hidden logical coupling. Classic case: a "legacy util" and a "new service" that both encode the same business rule, so every rule change touches both. **This is how you find the "third place" a concept's logic lives** — the static graph doesn't connect them, but git shows they always move together.
- Two files **statically connected** that never commit together → the connection is vestigial / the callee is a stable utility. Safe to treat as a boundary.

**How to weight it:**
- 1 shared commit = coincidence.
- 2–3 shared commits = probably coupled.
- 4+ shared commits, especially recent = **definitely one logical unit**, treat them as inseparable for the change.
- Shared commits with concept-matching messages ("fix token bug", "refactor auth") → strong; shared commits that are all "bump version" / "format" → weak (ignore those).

**Failure mode:** merges and big refactors can touch many unrelated files at once. If a single commit touches 15+ candidate files, it's probably a sweep — discard it as a co-change signal, look at the smaller commits.

### Parallel implementations = the pattern co-change misses

**What it is:** N files that implement the *same* concept with *intentional or accidental drift* (6 versions of an edit form, 3 retry strategies, duplicate validators). This is the signature pattern of severe technical debt.

**Why co-change fails here:** co-change assumes "coupled files change together." But parallel implementations often *don't* change together — and that's the bug. When a developer updates the concept in only 3 of 6 forms, co-change is weak (they rarely commit together), and the skill would wrongly conclude "not a logical unit." The absence of co-change is actually the signal of drift, not of independence.

**How to detect it instead:**
- Phase 1 returns ≥3 candidates with similar concept-stems in filenames/paths, all matching the same concept query.
- Phase 2 shows all are `active` (recent churn) but co-change among them is weak — active-but-not-co-changing is the parallel-impl signature.
- The user mentions "variants", "duplicates", "versions", "6 forms that do the same thing".

**The signal you actually need here is `diff`, not `git log`.** For parallel implementations, the divergence between files is the deliverable — run Phase 2b. Co-change tells you "are they coupled"; diff tells you "where have they drifted." You need both, but diff is the one that produces the actionable artifact (the divergence matrix).

**Intentional divergence vs drift — how blame helps:**
- Same logic, diverged recently, commit message on one side says "fix bug X" but the other side has no matching commit → **drift** (forgot to sync). Likely a bug.
- Divergent logic, both sides have commits with different feature names → **intentional** (per-variant rule). Preserve both.
- Divergent logic, one side's blame is ancient (2+ years), other side is recent → the ancient one is legacy-frozen, the recent one is canonical. Changing the concept means updating the recent one + deciding whether to backport.

**Failure mode:** don't try to classify divergences by reading both files in context — near-identical code conflates in the LLM's working memory. Always go via `git diff --no-index` output, which isolates only the differing hunks.

### Churn = activation, not importance

**What it is:** commit count per file in a recent window.

**What it tells you:** which implementation is **currently alive**. In a debt-laden project there are usually 2–3 implementations of the same concept (the current one + legacy ones). Churn tells them apart:

- High churn, recent → the **active** path. This is where your change probably goes.
- Zero churn in 1+ years → **legacy/dead-suspected**. May still be called by dead code paths; confirm with LSP `incomingCalls` in Phase 3.
- Churn that stopped recently (was active, now silent) → likely **superseded**. Look for a replacement that started churning around when this one stopped — that's the handoff point.

**What it does NOT tell you:** importance. A 1-line config file with low churn might be more critical than a 500-line file with high churn. Churn tells you *liveness*, not *centrality* — use LSP for centrality.

### Recency = the "current truth" anchor

**What it is:** date of last meaningful commit.

**Why it matters:** in legacy code, the **most recent** change to a concept area is usually the canonical current implementation. When you find N implementations of a concept, the one touched last (with a non-trivial commit message) is most likely the one the team currently considers authoritative — even if an older one has more code.

Pair this with blame: `git blame` on the entry-point line tells you *exactly when* the current logic landed and *why* (commit message). A blame pointing at "fix CVE-2023-xxxx" → this is the post-fix canonical path, full stop.

### Blame = the "why" behind the current logic

**What it is:** per-line author + commit + date.

**How to use it (sparingly):** blame only the **1–3 most central entry-point lines** from Phase 1. The commit message on that line is often more informative than the code itself:

- "fix …" / "hotfix …" → this line exists because something broke. Don't refactor it blindly; the fix encodes a constraint you must preserve.
- "refactor …" / "rewrite …" → the surrounding code was deliberately restructured; there may be sibling files from the same refactor.
- "WIP" / "temp" / no message → technical debt marker, likely safe to change but flag it.
- date much older than the file's other lines → an island of legacy logic surviving in an otherwise-refreshed file. High-interest spot.

**Don't** blame whole files — it's noise. Just the lines you're about to change.

## LSP signals

LSP gives you **ground-truth structure** but only for the files you point it at. Its value is precision, not coverage.

### documentSymbol = the file's contract, fast

Use it to get a file's public surface without reading it. What to look for (adapt "public method" to your language's visibility model — exported functions in Go, `pub` items in Rust, non-underscored members in Python, etc.):

- **Exported/public surface only** → that's the file's real API. Changes should stay within this surface unless you're refactoring.
- **A symbol named after your concept** (e.g. `verifyToken`, `issue_token`) → that's your entry point for Phase 3 call expansion.
- **Many private helpers all named around the concept** → this file is *dedicated* to the concept (high centrality). Promote it in your logical-unit clustering.
- **One concept symbol buried among 30 unrelated ones** → this file is a god-object; the concept is a tenant, not an owner. Lower centrality, but flag the god-object as a risk (changes here have wide blast radius).

### incomingCalls = blast radius upward

"Who depends on this?" → tells you what breaks if you change this symbol.

**Interpretation:**
- All callers are in your candidate set → you've found a closed cluster.
- Callers include framework entry points (web-framework handlers, scheduled jobs, ORM hooks, DI-managed beans) → this is a **leaf of the app**; its upward blast radius ends at the framework. Good — contained.
- Callers include files **outside** your candidate set → you missed a consumer in Phase 1. Either pull it in (if app-internal) or recognize a boundary (if it's a public API consumed elsewhere).
- **Zero app-internal callers** → dead code (confirm with `references` to rule out reflection/indirect calls). Demote to dead.

### outgoingCalls = blast radius downward

"What does this depend on?" → tells you the change's downstream reach.

**Stop-expansion heuristics (critical):**
- Callee is in a standard-library / framework namespace (language-dependent — e.g. `java.*`, `org.springframework.*`, `react`, `django.*`, `encoding/`, `std::`) → framework boundary, **stop**. Recursing into framework code is pure token burn.
- Callee is in your candidate set → merge into the same logical unit (you just found an internal edge).
- Callee is a project file but *outside* the candidate set → could be a shared util. Note it, but don't expand unless it owns part of the concept logic. Most shared utils are stable boundaries, not part of the change.
- Callee is generated code (any `generated/` / `build/` / `.gen.` path convention) → ignore, it regenerates.

### references = the completeness check

Run on your 1–3 central entry points after `incomingCalls`. `references` is broader (includes non-call usages: type refs, annotations, decorator/macro usage, imports). Use it to catch:

- A usage that isn't a direct call (e.g. a decorator/attribute referencing your verifier, a type reference in a serializer config). These are invisible to `incomingCalls` but are real consumers.
- Test files referencing the symbol → tells you which tests will need updating.

If `references` and `incomingCalls` agree on the app-internal caller set, you're done — the cluster is closed.

## Combining signals — the decision matrix

| Concept layer says | History layer says | Structure layer says | Verdict |
|---|---|---|---|
| candidate | active + co-changes with others | app-internal callers | **core of a logical unit — change here** |
| candidate | active, lone churn | framework callers only | active leaf — change here, contained |
| candidate | legacy (no recent churn) | still has app-internal callers | **legacy-but-live** — must change too, or explicitly migrate. Flag as risk. |
| candidate | dead (no churn, no callers) | no app-internal callers | dead — leave alone, note for cleanup |
| candidate | active | callers outside candidate set | Phase-1 miss — pull the caller in or treat as boundary |
| not a candidate | — | but incomingCalls from a survivor | **hidden consumer** — add to candidate set, re-cluster |
| ≥3 candidates, similar concept-stem | all active, weak co-change among them | similar symbol surfaces | **parallel implementations — run Phase 2b, divergence matrix is the deliverable** |

The last two rows are the self-correcting loop: history and structure can send you back to Phase 1 to pull in files the text search missed. That's the skill working as intended — but cap it: if you loop back more than twice, ask the user for a seed (see SKILL.md "When to bail out and ask").

### Degraded flow (no git history)

Without Phase 2, the "History layer says" column is empty. You can only use the Concept + Structure columns, which collapses several verdicts:

- You cannot distinguish `active` from `legacy` from `dead` structurally — `incomingCalls` only tells you *live*, not *recent*. A file with callers might still be legacy-but-live.
- Co-change-based "logical unit" clustering is unavailable; rely on Phase-3 `outgoingCalls`/`references` edges to group files, which catches *static* coupling but misses *hidden* coupling.
- Ask the user explicitly about legacy/duplicate implementations (see SKILL.md "Degraded flow"). The decision matrix becomes weaker; the "bail out and ask" path fires more often — that's expected, not a failure.

## What signals deliberately are NOT used here

- **Embeddings / semantic similarity.** Deliberately excluded. For concept-to-file mapping, naming + git co-change is higher-signal than vector proximity in legacy code, and far cheaper. Embeddings smooth over the exact inconsistencies (3 different implementations of the same concept) that are the whole point.
- **Full pre-computed call graph.** Too expensive to build upfront, mostly irrelevant to any single change. LSP on-demand on ≤8 survivors gets you the edges that actually matter.
- **AST-level import analysis at scale.** Imports are a weak signal (everyone imports the standard library). Only useful at Phase 3 to resolve a specific type — `goToDefinition` does that precisely without a full import graph.
