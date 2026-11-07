---
name: plan-change
description: Draft and review a small change proposal, specification, technical plan, QA plan, and tasks without implementing code.
---

# Plan a change

1. Read `AGENTS.md` and inspect relevant existing code and architecture.
2. Ask for the change ID and objective if they are missing.
3. Create `changes/<id>-<short-name>/` using copies of the templates in `changes/_templates/`. Copy `task.md` once per task, into `tasks/`.
4. Draft `proposal.md` in plain language: the user story, why the change is needed, and what we would like to have, at a high level.
5. Ask for review and approval of the proposal.
6. Draft `spec.md` in plain language, with observable requirements and testable acceptance criteria that cover the proposal. Surface important open questions.
7. Ask for review and approval of the specification before treating it as final.
8. Draft `plan.md` stating what must exist to meet each functional requirement, as plain statements with no explanations or steps. Record each real choice between options under Decisions.
9. Ask for review and approval of the plan.
10. Draft `qa.md` with test coverage for the acceptance criteria and applicable non-functional requirements.
11. Ask for review and approval of the QA plan.
12. Draft small files in `tasks/`, numbered in the order to do them, each one a task an agent can finish and verify on its own.
13. Ask for review and approval of the tasks. Do not implement code.
