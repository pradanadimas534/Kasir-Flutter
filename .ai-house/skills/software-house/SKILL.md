# Software House Workflow

Use this skill for any task spanning more than one small, obvious edit. Execute in sequence; this skill does not imply separate AI agents.

1. **Understand:** inspect repository conventions, relevant files, scripts, tests, and Git status.
2. **Plan:** state the goal, assumptions, acceptance criteria, affected areas, and risks.
3. **Design:** define data flow, interfaces, UI states, and failure behavior before implementation.
4. **Implement:** make a minimal coherent change, preserving existing patterns and unrelated work.
5. **Verify:** run targeted tests and then broader checks when justified.
6. **Review:** inspect the diff for correctness, security, regressions, and accidental scope.
7. **Report:** describe changes, checks actually run, outcomes, and limitations.

Do not claim to have delegated work to specialist agents unless the host explicitly supports and you actually used subagents. Treat the role names as review lenses otherwise.
