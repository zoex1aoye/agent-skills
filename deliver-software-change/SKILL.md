---
name: deliver-software-change
description: >-
  Use for an adaptive, evidence-driven software delivery workflow from an
  ambiguous request or defined spec: clarify decisions, write acceptance
  criteria, slice work, implement and test, review standards and spec fit
  separately, verify observable outcomes, and close the change. Applies to
  features, multi-file refactors, migrations, and delivery planning. When the
  user requests only one stage such as review, testing, or specification, do
  that stage without forcing upstream documents.
---

# Deliver Software Change

Drive a change from intent to evidence without turning every task into the same
heavyweight process. The workflow is adaptive: risk and blast radius determine
how much specification, design, and reporting are justified.

## Delivery contract

Before implementation, make these items explicit enough to judge the result:

- the problem and intended user outcome;
- scope and non-goals that could otherwise cause drift;
- observable acceptance criteria;
- architectural, security, compatibility, and data constraints;
- the fixed point from which the change is measured;
- the commands or environments that can verify it.

For a small change this may fit in three lines. For a shared contract,
dependency upgrade, migration, or cross-module feature, preserve it in a spec or
decision record.

## Adaptive depth

| Change shape | Minimum useful evidence |
|---|---|
| Local, reversible edit | Short intent, acceptance check, targeted verification |
| Multi-file feature | Spec or brief, vertical slices, tests, dual-axis review |
| Shared contract, migration, security, or data change | Decision record, dependency/rollback plan, integration verification |
| Ambiguous product request | Decision-clarifying brief and rough prototype before commitment |

Raise depth when the change crosses module ownership, shared components,
external contracts, persistent data, production configuration, or irreversible
operations. Small line count does not reduce these risks.

## Workflow

1. **Establish the baseline.** Read the repository's agent instructions and
   relevant local conventions. Inspect git state before changing files. Discover
   the actual build, test, lint, and run commands instead of assuming them.
2. **Resolve decision-changing ambiguity.** Ask only questions whose answers
   could change scope, architecture, user-visible behavior, or acceptance. Ask
   dependent questions one at a time. When a rough outline, wireframe, sample,
   or mock would expose missing detail cheaply, show it before full delivery.
3. **Write the delivery contract.** Capture the problem, non-goals, acceptance
   criteria, constraints, and verification. Separate known facts from inferred
   decisions; label unresolved assumptions.
4. **Design only as far as the risk requires.** For substantial work, read
   [reference/planning.md](reference/planning.md) before decomposing the change.
5. **Slice the work.** Prefer narrow vertical slices that can each be completed
   and verified end to end. For broad mechanical refactors, use an
   expand-migrate-contract sequence instead of pretending a vertical slice is
   safe. Keep enough state that interrupted work can resume.
6. **Implement against the contract.** Read
   [reference/execution.md](reference/execution.md) before editing code. Reuse
   the project's patterns and test framework. Keep each slice within scope and
   verify continuously.
7. **Review two independent axes.** Check documented engineering standards and
   specification fit separately. A change can implement the right behavior
   poorly, or follow every convention while solving the wrong problem. Do not
   let one axis hide the other.
8. **Verify observable behavior.** Read
   [reference/verification.md](reference/verification.md) before declaring the
   work complete. Distinguish static checks, test execution, exploratory QA, and
   user acceptance; they answer different questions.
9. **Close the change.** Record the verification evidence and material
   decisions. Update affected project docs, rules, or memory only where the new
   facts belong. Commit, push, deploy, or apply destructive changes only when the
   user has authorized that action.

If the user asks for only one stage, perform that stage directly. State any
missing upstream evidence and do not silently generate a full PRD, ticket tree,
or release workflow.

## Stop conditions

Stop and report before proceeding when:

- a missing decision would change the implementation or acceptance criteria;
- the repository baseline cannot build, start, or be verified safely;
- the implementation contradicts the spec, project constraints, or discovered
  runtime behavior;
- completing the task would require an unapproved destructive or external action;
- the same failure has persisted after a small bounded repair loop and the next
  step would be speculative rather than evidence-based.

Do not stop merely because work is difficult. Exhaust safe in-scope checks first.

## Evidence rules

- A passing unit test does not prove the user story works in the running product.
- Reading source code does not prove a UI flow, integration, or migration result.
- “Page opens”, “no error was shown”, and “button is clickable” are not acceptance
  evidence unless the story explicitly defines them as the outcome.
- A failure that cannot be reproduced is not yet a defect; a success that was
  not checked against the expected state is not yet a pass.
- Record commands, inputs, observed results, and artifact paths. Do not commit
  credentials, auth state, generated screenshots, or temporary test data unless
  the project explicitly requires those artifacts.
