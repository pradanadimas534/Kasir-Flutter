# Code Review & Security

Review the final diff as if it was written by someone else. Look for:

- Incorrect behavior, missed requirements, race conditions, boundary cases, and regressions.
- Authentication/authorization gaps, unsafe input handling, injection, secret leakage, and excessive data exposure.
- Broken error handling, resource leaks, and unhandled asynchronous failures.
- Accessibility issues and missing UI states where relevant.
- Tests that do not actually assert the intended behavior.
- Unnecessary complexity, duplicate code, dead code, broad formatting, and unrelated file changes.

Prioritize findings by severity and cite affected files/lines when possible. Fix safe, in-scope issues; disclose unresolved findings. Never report a review as passed without examining the diff.
