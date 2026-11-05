---
name: plan-change
description: Draft and review a small change specification, technical plan, and QA plan without implementing code.
---

# Plan a change

1. Read `AGENTS.md` and inspect relevant existing code and architecture.
2. Ask for the change ID and objective if they are missing.
3. Create `changes/<id>-<short-name>/` using copies of the templates in `changes/_templates/`.
4. Draft `spec.md` with observable requirements and testable acceptance criteria. Surface important open questions.
5. Ask for review and approval of the specification before treating it as final.
6. Draft `plan.md` describing the smallest viable design, affected components, and constraints.
7. Ask for review and approval of the plan.
8. Draft `qa.md` with test cases covering the acceptance criteria and applicable non-functional requirements.
9. Ask for review and approval of the QA plan. Do not implement code.
