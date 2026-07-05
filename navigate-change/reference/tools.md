# Tools cheatsheet — exact commands per phase

Map of phase → tool → exact invocation. Use ripgrep (`rg`) over `grep` whenever available.

Commands are language-agnostic. Where a `--type` flag is shown, use the ripgrep type for your language (`java`, `ts`, `py`, `go`, `rs`, …) or omit it to search all files. Where examples reference an identifier like `TokenManager`, treat it as a placeholder for whatever your concept query (Phase 0) produced.

**Phase 3 has runtime-specific sections below.** Use the section that matches your agent. If unsure, use **Fallback (no LSP)** — it works everywhere.

---

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

### Optional LSP — declaration discovery (skip if unavailable)

See Phase 3 runtime sections for `workspaceSymbol` invocations.

> Cap: de-dup to ≤30 files. If bigger, narrow the concept query (Phase 0), don't expand tools.

---

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

Confirm dead-status in Phase 3: if no app-internal callers are found, it's dead (or test-only).

---

## Phase 2b — Parallel-implementation detection (only when ≥3 similar candidates)

### Pairwise diff (the core operation)

```bash
# diff every pair in the cluster — isolates divergences without reading whole files
git diff --no-index path/to/fileA path/to/fileB

# if not tracked, or git unavailable:
diff -u path/to/fileA path/to/fileB
```

For a cluster of N files, pick one as the **reference** (most recently churned, or user-named) and diff each other file against it: N-1 diffs.

```bash
for f in <other candidates...>; do
  echo "=== diff vs reference: $f ==="
  git diff --no-index path/to/reference "$f"
done
```

### Blame a divergent hunk (classify intentional vs drift)

```bash
git blame -L L1,L2 --date=short path/to/fileA
git log -1 --format="%ci %s" -L L1,L2:path/to/fileA
```

### Divergence classification cheat-sheet

| Diff hunk looks like | Verdict |
|---|---|
| renamed variable / reformatted / comment-only | cosmetic — ignore |
| extra/missing field in a payload, form, or config | structural divergence — flag, likely forgotten sync |
| different condition (`if X` vs `if X && Y`) | logic divergence — flag, the dangerous kind |
| different formula / constant | logic divergence — flag |
| one file has a whole extra block the other lacks | structural divergence — flag, classify via blame |
| only imports differ | cosmetic — ignore (unless the import changes behavior) |

---

## Phase 3 — Structure layer (on ≤8 survivors only)

Pick **one** section below based on your runtime.

### Fallback (no LSP) — Cursor, Codex, most CLI agents

Use when your agent has `Grep`/`rg`, `Glob`, `Read`, and `Shell` but no LSP tool.

#### Public surface of a file (replaces `documentSymbol`)

```bash
# exported/public declarations — adapt regex to language
rg -n "^(export |pub |class |def |func |interface |type )" path/to/survivor
```

Or read only the first ~80 lines of the file (imports + top-level declarations).

#### Blast radius upward — who uses this symbol? (replaces `incomingCalls` / `references`)

```bash
# whole-word symbol search across the repo
rg -w "verifyToken" -l
rg -w "TokenManager" -l

# also catch import-style references
rg "from.*TokenManager|import.*TokenManager" -l
```

Exclude `node_modules/`, `vendor/`, `target/`, `dist/`, `.git/` from results. Framework-only callers → app boundary, stop expanding.

#### Blast radius downward — what does this depend on? (replaces `outgoingCalls`)

Read the survivor's imports/includes, then grep each imported project symbol to see if it's another survivor (→ same logical unit) or framework/stdlib (→ stop).

```bash
rg -n "^import |^from |^use " path/to/survivor
```

#### Resolve a type to its definition (replaces `goToDefinition`)

```bash
rg -n "class TokenManager|def verify_token|func VerifyToken" --type py --type ts --type go
```

#### Stop-expansion rule

The moment results are entirely framework/stdlib/test/scaffold paths, that branch is done. Don't recurse into the language standard library, web framework, ORM, or serializer.

---

### Cursor

| Phase 3 goal | Cursor tool |
|---|---|
| Text search | `Grep` (ripgrep) |
| File discovery | `Glob` |
| Read declarations / confirm | `Read` (partial reads OK) |
| Git commands | `Shell` |

Cursor has no first-class LSP tool. **Use the Fallback section above** with Cursor's `Grep`, `Glob`, `Read`, and `Shell`.

Example mappings:
```
Grep pattern="verifyToken" output_mode="files_with_matches"
Glob glob_pattern="**/*Token*"
Read path="src/auth/token_manager.ts" limit=80
Shell command="git blame -L 42,42 --date=short src/auth/token_manager.ts"
```

---

### Claude Code

| Phase 3 goal | Claude Code tool |
|---|---|
| Text search | `Grep` / `rg` via Bash |
| File discovery | `Glob` |
| Read source | `Read` |
| Git | `Bash` |

Claude Code may have IDE-integrated language services, but there is no portable `lsp operation=...` API across setups. **Default to the Fallback section.** If your session exposes LSP-like tools, use them with the same semantics as the MiMo-Code section below.

Optional frontmatter for Claude Code (in SKILL.md):
```yaml
allowed-tools: Read, Grep, Glob, Bash
```

---

### Codex (OpenAI)

| Phase 3 goal | Codex tool |
|---|---|
| Text search | shell `rg` / built-in search |
| File discovery | `glob` / `ls` |
| Read source | `read_file` |
| Git | shell |

**Use the Fallback section.** Codex discovers skills from `.agents/skills/` (project) or `~/.agents/skills/` (global). Invoke explicitly with `$navigate-change`.

Optional sidecar `agents/openai.yaml` in the skill directory:
```yaml
display_name: Navigate Change
dependencies:
  tools:
    - shell
```

---

### MiMo-Code / OpenCode (LSP available)

MiMo-Code exposes LSP via the `lsp` tool. Always pass `path` + `line` + `character` for position-based ops.

#### workspaceSymbol (Phase 1 optional)

```
lsp operation=workspaceSymbol query="Token"
lsp operation=workspaceSymbol query="Auth"
```

#### documentSymbol — public surface

```
lsp operation=documentSymbol path="src/.../token_manager"
```

#### incomingCalls — blast radius upward

```
lsp operation=incomingCalls path="..." line=42 character=5
```

#### outgoingCalls — blast radius downward

```
lsp operation=outgoingCalls path="..." line=42 character=5
```

#### references — completeness check

```
lsp operation=references path="..." line=42 character=5
```

#### definition — resolve an import

```
lsp operation=definition path="..." line=10 character=15
```

> **Stop-expansion rule:** the moment an LSP result is entirely framework/test/scaffold, that branch is done.

---

## Phase 4 — Source layer (read, only survivors)

Read only the 3–8 surviving files (or divergent regions if Phase 2b ran). Confirm edit sites. Note any file that shares the logic but wasn't in your candidate set — that's a Phase-1 miss worth looping back on.

---

## Phase 5 — Output

No tool calls. Produce the navigation artifact (see SKILL.md "Phase 5") and pause for review.

---

## Tool-call budget guideline

| Phase | Expected calls | If you exceed… |
|-------|---------------|----------------|
| 1 | 3–8 greps/globs + 0–2 workspaceSymbol | concept too loose → refine Phase 0 |
| 2 | 1 co-change log + 1 churn pass + 1–3 blames | candidate set too big → back to Phase 1 |
| 2b | N-1 diffs (N = parallel files) + ≤3 blames per logic divergence | if N > 6, pick reference + diff vs reference only |
| 3 | ≤8 symbol scans + ≤6 ref/call searches per central symbol | survivors >8 → Phase 2 didn't prune enough |
| 4 | 3–8 reads (only divergent regions if Phase 2b ran) | — |

**Degraded-flow budget (no git):** Phase 3 may double (run structure analysis on every survivor). Hard cap total tool calls at ~50; beyond that, ask the user for a seed.

If total tool calls for a navigation exceed ~40 (full flow) / ~50 (degraded), stop and ask the user for a seed (see SKILL.md "When to bail out and ask").
