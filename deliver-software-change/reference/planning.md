# Planning and decomposition

Read this when the change is larger than a local edit, crosses ownership or
contracts, or lacks a clear executable plan.

## 1. Decision brief

Use a short structure proportional to the risk:

```markdown
## Intent
<Problem and user outcome>

## Scope
- In: ...
- Out: ...

## Acceptance
- [ ] <Observable result>
- [ ] <Failure or boundary behavior>

## Constraints and assumptions
- Confirmed: ...
- Inferred, needs confirmation: ...
- Decision: ... | rationale: ... | owner/date: ...

## Verification
- Automated: ...
- Runtime/manual: ...
- Rollback or recovery: ...
```

For a product request, separate:

- verified facts;
- interpretations of those facts;
- value or priority judgments;
- the desired outcome.

Do not turn a preference into a universal requirement. Ask one dependent
question at a time. Stop when additional questions would not change the result.

## 2. Spec threshold

Create or update a persistent spec when any of these is true:

- more than one person or agent will implement it;
- acceptance is not obvious from the request;
- work spans sessions, modules, teams, or releases;
- shared behavior, data, permissions, APIs, or migrations are involved;
- a decision is likely to be revisited.

Keep the spec focused on decisions and observable outcomes. Do not copy entire
project rulebooks into it; link to their canonical source.

## 3. Vertical slices

For feature work, each ticket should cut a narrow path through the layers needed
to demonstrate one user-visible capability. It should:

- have explicit dependencies;
- be independently demonstrable or verifiable;
- fit in one focused implementation context;
- name its acceptance evidence;
- point to the exact spec section it implements.

Record ticket state as not-started, in-progress, or complete. Update it when the
slice changes; incomplete verification means incomplete.

Do not force vertical slices onto a broad mechanical migration. Use:

1. **Expand:** add the replacement while the old form still works.
2. **Migrate:** move call sites in reviewable batches, keeping validation green.
3. **Contract:** remove the old form only after all callers are migrated.

## 4. Readiness gate

Before implementation, confirm:

- every in-scope requirement has an owner and acceptance criterion;
- dependencies form an acyclic graph;
- shared contracts, data changes, permissions, and rollback are addressed;
- each ready ticket names the implementation references it needs;
- the selected verification environment actually exists;
- unresolved questions are isolated rather than silently guessed.
