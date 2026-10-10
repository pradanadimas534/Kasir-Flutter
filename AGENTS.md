# AI Software House — Project Rules

This file is the project-level source of truth for AI-assisted work. Follow it before editing files. Detailed, task-specific guidance is in `.ai-house/skills/`.

## Mandatory rule acknowledgement and evidence
- At the start of a task, explicitly check whether this `AGENTS.md` is available in your active context. Read it and the relevant installed `SKILL.md` files before editing. Do not infer that rules were loaded merely because files exist on disk.
- In your first progress message, briefly report `AI House: active` only if you have actually read this file. Name the relevant skills you read. If you cannot access or have not read this file, say `AI House: not verified` and continue cautiously; never claim compliance without evidence.
- In your final response, always include the `AI House compliance` section specified under Phase 7. Keep it concise and factual. It is a self-report, not an external enforcement guarantee.
- If the host agent ignores this file or does not support project instructions, the CLI cannot force compliance. Report that limitation instead of pretending the rules were enforced.

## Operating contract
1. **Inspect before acting.** Read the project README, package/composer/build configuration, existing architecture, relevant tests, Git status, and nearby code before proposing changes. Do not assume a framework or invent files that already exist.
2. **Work sequentially.** Follow the phases below in order. Do not skip a phase silently. For a trivial change, explicitly compress irrelevant phases and explain why.
3. **Plan first.** Restate the goal, constraints, likely files, risks, and acceptance criteria. Ask a focused question only when a missing decision blocks safe progress; otherwise state reasonable assumptions.
4. **Respect scope.** Change only what the task requires. Preserve existing conventions and unrelated user changes. Never reset, discard, overwrite, or reformat unrelated work.
5. **Prefer the smallest sound solution.** Avoid speculative abstractions, duplicate helpers, unnecessary dependencies, placeholder implementations, fake data in production paths, and broad rewrites without approval.
6. **Security by default.** Validate untrusted input, enforce authorization on the server, protect secrets, use parameterized database access, and avoid exposing private data. Never claim a security guarantee without evidence.
7. **Do not fabricate verification.** Run relevant checks when available. Clearly distinguish checks run, checks not run, failures, and manual follow-ups. Never say tests pass unless they actually passed.
8. **Keep the user in control.** Ask before destructive data changes, dependency upgrades with meaningful risk, deployment, production actions, or changes that affect external services.

## Sequential workflow
### Phase 1 — Understand
- Inspect repository structure, framework, conventions, and current Git status.
- Identify existing user changes and avoid touching them.
- Read only the files needed to understand the task.

### Phase 2 — Plan
- Define the intended behavior and acceptance criteria.
- Identify affected files, dependencies, migration needs, security risks, and edge cases.
- For multi-file work, present a short ordered plan before implementation.

### Phase 3 — Design
- Reuse existing architecture and components where practical.
- Define interfaces, data flow, states, and failure behavior before coding.
- For UI, consider loading, empty, error, success, keyboard, mobile, and accessibility states where relevant.

### Phase 4 — Implement
- Make the smallest coherent changes that meet the criteria.
- Follow local style, naming, architecture, and dependency conventions.
- Do not leave TODOs, mock implementations, or dead code unless explicitly requested and labeled.

### Phase 5 — Verify
- Run the most relevant tests, lint, type checks, build, or static checks available.
- Add or update tests for changed behavior when practical.
- Inspect the final diff for accidental changes, secrets, generated files, and scope creep.

### Phase 6 — Review
- Review correctness, edge cases, security, accessibility, maintainability, and regressions.
- Fix issues found when safe; otherwise report them clearly.
- Do not mark the task complete while a known critical failure remains hidden.

### Phase 7 — Report
- Summarize what changed and why.
- List commands actually run and their outcomes.
- State remaining risks, skipped checks, and any manual action needed.
- Always include a concise `AI House compliance` section in the final response using this format:
  - **Status:** followed / partial / not verified. Choose `followed` only when you read this file and all applicable selected skills, completed the applicable workflow, and have no undisclosed deviations.
  - **Rules read:** list `AGENTS.md` and the exact `.ai-house/skills/.../SKILL.md` files actually read. Do not list files only discovered or assumed to be read.
  - **Workflow:** identify phases completed and phases skipped/compressed, with a brief reason for any skipped phase.
  - **Verification:** list actual checks and outcomes; distinguish pass, fail, and not run.
  - **Deviations/blockers:** state none only after checking; otherwise list them explicitly.
- For small tasks, this section may be one or two lines, but it must not be omitted. Never use the compliance label as a substitute for evidence.

## Definition of done
A task is done only when:
- Acceptance criteria are addressed or deviations are explained.
- Changes are scoped and consistent with the project.
- Relevant verification was run where possible and results are reported accurately.
- The final diff has been reviewed.
- Known limitations and unverified behavior are disclosed.

## Tool and command safety
- Inspect commands before running them; prefer project-local scripts and existing package managers.
- Do not run destructive shell commands, mass deletions, database resets, or production mutations without explicit approval.
- Do not print, copy, or commit secrets or `.env` values.
- Do not install packages merely for convenience when the project already has a suitable solution.

## Installed skills
The skills selected during setup are installed in `.ai-house/skills/`. Read the relevant `SKILL.md` before work in that area. The software-house and planning skills define the general workflow; specialist skills add focused constraints and do not override this file's safety rules.

Selected skill files:
- `.ai-house/skills/software-house/SKILL.md`
- `.ai-house/skills/planning/SKILL.md`
- `.ai-house/skills/testing/SKILL.md`
- `.ai-house/skills/code-review/SKILL.md`
- `.ai-house/skills/ui-ux/SKILL.md`
- `.ai-house/skills/frontend/SKILL.md`
- `.ai-house/skills/backend/SKILL.md`
- `.ai-house/skills/database/SKILL.md`
- `.ai-house/skills/performance/SKILL.md`
- `.ai-house/skills/documentation/SKILL.md`


## Conflict resolution
Follow, in order: explicit user request and safety constraints; this file; relevant installed skills; existing project conventions. If two requirements conflict, explain the conflict rather than silently choosing a risky interpretation.
