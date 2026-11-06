# Verification and closeout

Read this after implementation and before claiming completion.

## Four different evidence types

| Layer | Question answered | Typical evidence |
|---|---|---|
| Static checks | Does the code parse, type-check, lint, or build? | Compiler/linter output |
| Automated tests | Do specified behaviors hold in controlled inputs? | Unit/integration/e2e results |
| Exploratory QA | What unexpected failures or UX issues appear in real use? | Reproducible steps, screenshots, console/network evidence |
| Acceptance | Does the product produce the expected observable outcome for the story? | Result-state evidence tied to the acceptance criterion |

Do not substitute one layer for another.

## Acceptance status

Each acceptance item ends in exactly one state:

- **Pass:** the expected observable result was present and remained valid on a
  retry.
- **Fail:** the expected result is clear, but the product produced a different
  result or error.
- **Cannot verify:** the expected result, prerequisite data, permission,
  environment, or access is missing.

“Cannot verify” is not a pass and is not automatically a code defect. Record what
is missing and who can resolve it.

## Test data and side effects

- Prefer isolated test data with a recognizable prefix.
- Avoid destructive actions against real business data.
- Ask before changing shared environments or user-owned running processes.
- Keep authentication state and temporary evidence out of commits.
- Repeat a failure once before filing it; distinguish deterministic failures
  from flaky behavior.

## Exploratory QA versus acceptance

- With a story or acceptance list, run the specified paths and report each story
  as pass, fail, or cannot verify.
- Without a story, explore for defects and document reproducible issues. Keep
  issues found outside the requested stories in a separate section.
- Stop after enough high-quality evidence to make a decision. More shallow
  findings are not automatically better than a few reproducible ones.

## Completion record

A final report should contain only what is needed to defend the outcome:

- change or request identifier;
- scope delivered and explicit non-goals;
- verification commands and results;
- runtime or acceptance evidence with paths;
- unresolved defects, warnings, and risks;
- rollback or recovery information when risk requires it;
- documentation, guidance, or version records updated.

Do not claim pixel parity, performance, security, or production readiness unless
the corresponding evidence was observed at the target viewport, load, or
environment.

## Closeout and learning loop

1. Compare the final change with the delivery contract.
2. Update the canonical source for changed commands, architecture, contracts,
   policies, or user-facing documentation.
3. Remove duplicate or stale guidance instead of appending another copy.
4. If the same failure or correction happened twice, promote it to a test,
   linter, template, rule, or skill.
5. Report what was verified and what was not. Unverified work remains unverified.
