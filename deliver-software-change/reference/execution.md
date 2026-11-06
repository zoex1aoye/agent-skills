# Implementation and review

Read this before changing code in a multi-step delivery.

## Baseline

1. Read the repository-level agent instructions and the guidance that applies to
   the files being changed.
2. Inspect the working tree and preserve unrelated changes.
3. Identify the actual package manager, build, test, lint, and run commands.
4. Check domain models, architecture decisions, and similar implementations
   before inventing a new pattern.
5. If documentation and runtime behavior conflict, report the conflict. Use the
   working configuration for immediate execution, not an unverified document.

## TDD and test strategy

Use test-first development when the behavior has a stable public seam. Before
writing tests, name the seam and expected observable behavior.

- A good test fails for the intended reason and then passes for the intended
  reason.
- Test behavior through public boundaries rather than private implementation
  details.
- Derive expected values from the spec or an independent known-good source, not
  by repeating the implementation formula.
- Prefer one failing test, one minimal implementation, then the next slice.

Legacy code, generated code, or an untestable boundary may require a different
strategy. Do not pretend TDD was used. Add the smallest stable seam or targeted
characterization tests available, and state the limitation.

## During implementation

- Keep one active vertical slice or migration batch.
- Run focused checks frequently; run the broader suite before handoff.
- Stop at the boundary of the ticket. Record newly discovered work rather than
  expanding scope silently.
- If a ticket's checks are incomplete, leave it in-progress.
- Do not refactor unrelated code merely because it is nearby.
- In non-git projects, identify the equivalent versioning, backup, or change-log
  mechanism before editing.

## Dual-axis review

Review the diff from a fixed point and keep these reports separate.

### Standards axis

- documented repository and language conventions;
- correctness, security, maintainability, and test quality;
- duplicated logic, misplaced responsibilities, speculative abstraction,
  repeated branching, unnecessary forwarding, and other code smells;
- generated or tool-enforced rules already satisfied by the toolchain.

Repository documentation overrides generic style heuristics. Code-smell findings
are judgments, not automatic blockers.

### Spec axis

- required behavior missing or incomplete;
- behavior added outside the accepted scope;
- implementation that superficially satisfies an acceptance criterion but does
  not produce the required outcome;
- unresolved decision records or assumptions.

If independent reviewers are available, assign one axis to each so they cannot
anchor on each other. If they are not available, perform two sequential passes
with separate notes. Never merge the two axes into one severity list.

## Commit boundary

Commit only when requested or required by the project's authorized workflow.
Before committing, inspect the diff for unrelated files, credentials, temporary
artifacts, and generated output that should not be tracked. A successful test
run does not imply permission to commit or push.
