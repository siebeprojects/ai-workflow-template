# Engineering Agreement

## Communication and approval
- Before changing implementation code, explain the proposed changes and wait for explicit approval.
- Reading files, inspecting code, and discussing designs do not require approval.
- Ask focused questions when requirements are unclear. Keep communication concise.

## Change documentation
- Keep each independent change (new feature, bug fix, refactoring, or other work) under `changes/<id>-<short-name>/`.
- `spec.md` defines the behavior, functional and non-functional requirements, and acceptance criteria.
- `plan.md` defines the approved technical approach and constraints.
- `qa.md` defines how the change is verified and records the results.
- Use `changes/_templates/` when starting a new change.
- Keep documentation proportional to the size of the change; a separate `tasks.md` is not required.
- Do not implement a change until its specification, plan, and QA plan have been reviewed and approved.

## Implementation
- Follow the approved `spec.md` and `plan.md`. If a deviation is needed, stop and ask for approval.
- Work in small, independently verifiable increments.
- Follow existing architecture and code conventions; avoid unrelated changes and unnecessary dependencies.
- Add or update tests for behavioral changes; run relevant tests.
- Do not create branches, commit, or push without permission.

## Completion
- Summarize changed files, tests run and their results, and outstanding risks or questions.
