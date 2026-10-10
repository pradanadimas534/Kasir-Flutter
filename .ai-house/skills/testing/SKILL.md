# Testing & QA

- Select checks based on risk and changed behavior; prioritize a focused regression test.
- Cover success paths, validation failures, authorization boundaries, empty values, and relevant edge cases.
- Prefer deterministic tests; avoid real external services unless explicitly configured for integration testing.
- Use existing test tooling and conventions. Do not introduce a large testing dependency for a tiny change without justification.
- Run tests and report the exact commands and outcomes. Distinguish failures from tests that were not run.
- A passing test suite does not prove untested behavior; disclose important gaps.
