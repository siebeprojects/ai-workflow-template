---
name: plan-change
description: Draft and review a small change specification and technical plan without implementing code.
---

# Plan a change

1. Read `AGENTS.md` and inspect relevant existing code and architecture.
2. Ask for the change ID and objective if they are missing.
3. Create `changes/<id>-<short-name>/` using copies of the templates in `changes/_templates/`.
4. Draft `spec.md` with observable requirements and testable acceptance criteria. Surface important open questions.
5. Ask for review and approval of the specification before treating it as final.
6. Draft `plan.md` describing the smallest viable design, affected components, constraints, and verification approach.
7. Ask for review and approval of the plan. Do not implement code.
