# Tools cheatsheet — exact commands per phase

Map of phase → tool → exact invocation. Use ripgrep (`rg`) over `grep` whenever available. MiMo-Code exposes LSP via the `lsp` tool — operations listed below match that tool's verbs.

Commands are language-agnostic. Where a `--type` flag is shown, use the ripgrep type for your language (`java`, `ts`, `py`, `go`, `rs`, …) or omit it to search all files. Where examples reference an identifier like `TokenManager`, treat it as a placeholder for whatever your concept query (Phase 0) produced.

## Phase 1 — Concept layer (text tools)

### ripgrep — multi-term with anchors

```bash
# single term, whole words only (avoids 'token' matching 'tokenizer')
rg -w "token" --type java -l
# no --type if the project is polyglot or you don't know the language yet:
rg -w "token" -l

# polysemous term: require a second anchor in the same file
rg -l "token" | xargs rg -l "auth|login|jwt"

# both terms on nearby lines (within 5 lines) — tighter coupling signal
rg -n "token" -C5 | rg "auth|login"

# identifier-style search (camelCase / PascalCase / snake_case variants at once)
rg "TokenManager|TokenService|token_manager|verifyToken|create_token" -l
```

### glob — name-based candidates

```bash
# concept in filename (strongest naming signal) — don't hardcode extensions,
# match whatever the project actually uses
ls **/*Token* **/*Auth* **/*Login* 2>/dev/null

# concept in path
ls **/auth/** **/security/** 2>/dev/null
```

### LSP workspaceSymbol — declaration discovery

```
lsp operation=workspaceSymbol query="Token"
lsp operation=workspaceSymbol query="Auth"
```

This catches declarations text search misses (e.g. inside generated/minified files, or when the identifier is split across lines). Returns symbol name + location + kind (class/function/etc.).

> Cap: de-dup to ≤30 files. If bigger, narrow the concept query (Phase 0), don't expand tools.

## Phase 2 — History layer (git, only on Phase-1 survivors)

> Only run if the precondition check (`git rev-parse --is-inside-work-tree`) passed AND the repo has non-trivial history. Otherwise see SKILL.md "Degraded flow".

### Per-file recent history

```bash
git log --oneline -20 -- path/to/file
```

### Co-change detection across the candidate set

```bash
# list commits that touched ANY candidate, with the files each commit touched
git log --since="6 months ago" --name-only --format="COMMIT %h %s" -- \
  path/to/file1 path/to/file2 path/to/file3
```

Then scan the output: a single `COMMIT` line followed by **2+ candidate files** = a co-change edge. Group those files into a logical unit. This is the single most valuable signal in this skill.

**Quick co-change clustering (one-liner):**

```bash
# prints "fileA|fileB <commit-count>" for every pair that committed together
git log --since="1 year ago" --name-only --format="%H" -- <candidates...> \
  | awk 'NF==0{next} {files[NR]=$0} END{...}'
```
(In practice it's clearer to just eyeball the `--name-only` output for shared commits — the pairs jump out.)

### Recent churn ranking

```bash
# count commits per candidate file in the last N months
for f in <candidates...>; do
  echo "$(git log --since='3 months ago' --oneline -- "$f" | wc -l) $f"
done | sort -rn
```

High count + recent = **active**. Zero commits in the window = **legacy/dead-suspected**.

### Blame the entry point

```bash
# who/when/why for a specific line
git blame -L 42,42 --date=short path/to/file
```

Look at the **commit message** on the blamed line — it often says *why* the current logic exists ("fix CVE-2023-xxxx", "refactor token flow"), which tells you if this is the canonical implementation.

### Is a file actually dead?

```bash
# last touch date — if years ago AND no commits in recent feature branches, suspect dead
git log -1 --format="%ci %s" -- path/to/suspected_dead_file
```

Confirm dead-status in Phase 3: if `incomingCalls` returns nothing app-internal, it's dead (or test-only).

## Phase 2b — Parallel-implementation detection (only when ≥3 similar candidates)

### Pairwise diff (the core operation)

```bash
# diff every pair in the cluster — isolates divergences without reading whole files
# if the files are tracked by git, --no-index lets you diff any two paths:
git diff --no-index path/to/fileA path/to/fileB

# if not tracked, or git unavailable:
diff -u path/to/fileA path/to/fileB
```

For a cluster of N files, that's N*(N-1)/2 pairs. For 6 files = 15 pairs — too many to eyeball. **Pick one as the reference** (the most recently churned, or the one the user named) and diff each other file against it: N-1 diffs. 5 diffs for 6 files is manageable.

```bash
# reference = the most-active file; diff others against it
for f in <other candidates...>; do
  echo "=== diff vs reference: $f ==="
  git diff --no-index path/to/reference "$f"
done
```

### Blame a divergent hunk (classify intentional vs drift)

When the diff shows a logic divergence on lines L1–L2 in fileA:

```bash
# when did fileA's version of this logic land? was it deliberate?
git blame -L L1,L2 --date=short path/to/fileA
git log -1 --format="%ci %s" -L L1,L2:path/to/fileA
```

Compare the commit message + date to the same range in fileB. Same commit date + message → they were once in sync and diverged later (drift suspect). Different messages referencing different features → intentional per-variant rule.

### Divergence classification cheat-sheet

| Diff hunk looks like | Verdict |
|---|---|
| renamed variable / reformatted / comment-only | cosmetic — ignore |
| extra/missing field in a payload, form, or config | structural divergence — flag, likely forgotten sync |
| different condition (`if X` vs `if X && Y`) | logic divergence — flag, the dangerous kind |
| different formula / constant | logic divergence — flag |
| one file has a whole extra block the other lacks | structural divergence — flag, classify via blame |
| only imports differ | cosmetic — ignore (unless the import changes behavior, e.g. different validator) |

## Phase 3 — Structure layer (LSP, on ≤8 survivors only)

MiMo-Code `lsp` tool verbs. Always pass `path` + `line` + `character` for position-based ops.

### Public surface of a file

```
lsp operation=documentSymbol path="src/.../token_manager"
```

Returns the symbol tree of one file — classes, methods, fields. Use this *instead* of reading the file when you just need to know what's exported.

### Blast radius upward (who calls THIS)

```
lsp operation=incomingCalls path="..." line=42 character=5
```

If this returns framework symbols (web-framework handlers, ORM repos, DI-managed beans) or test code only — you've hit an app boundary, stop expanding. App-internal callers are your real blast radius.

### Blast radius downward (what THIS calls)

```
lsp operation=outgoingCalls path="..." line=42 character=5
```

Follows the implementation's dependencies. Stop when you cross into library/framework code.

### Find call sites you missed

```
lsp operation=references path="..." line=42 character=5
```

Broader than `incomingCalls` (includes non-call references like type annotations, imports). Good for catching a usage that isn't a direct call.

### Go-to-definition (resolve an import)

```
lsp operation=definition path="..." line=10 character=15
```

Use when a survivor file imports/uses a type and you need to know if that type is *also* a survivor (→ merge into the same logical unit) or framework (→ stop).

> **Stop-expansion rule:** the moment an LSP result is entirely framework/test/scaffold, that branch is done. Don't recurse into the language standard library, your web framework, ORM, or serializer.

## Phase 4 — Source layer (read, only survivors)

```
Read path/to/survivor1
Read path/to/survivor2
```

Confirm edit sites. Note any file that shares the logic but wasn't in your candidate set — that's a Phase-1 miss worth looping back on (and a signal to tighten the concept query next time).

## Phase 5 — Output

No tool calls. Produce the navigation artifact (see SKILL.md "Phase 5") and pause for review.

---

## Tool-call budget guideline

| Phase | Expected calls | If you exceed… |
|-------|---------------|----------------|
| 1 | 3–8 greps/globs + 1–2 workspaceSymbol | concept too loose → refine Phase 0 |
| 2 | 1 co-change log + 1 churn pass + 1–3 blames | candidate set too big → back to Phase 1 |
| 2b | N-1 diffs (N = parallel files) + ≤3 blames per logic divergence | if N > 6, pick reference + diff vs reference only, don't do all-pairs |
| 3 | ≤8 documentSymbol + ≤6 call/ref per central symbol | survivors >8 → Phase 2 didn't prune enough |
| 4 | 3–8 reads (only divergent regions if Phase 2b ran) | — |

**Degraded-flow budget (no git):** Phase 3 may double (run call/ref on every survivor, not just central ones). Hard cap total tool calls at ~50; beyond that, ask the user for a seed.

If total tool calls for a navigation exceed ~40 (full flow) / ~50 (degraded), you've lost the plot — stop and ask the user for a seed (see SKILL.md "When to bail out and ask").
