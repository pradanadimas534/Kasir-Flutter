# Database Engineering

- Inspect the current schema, models, migrations, indexes, and data volume assumptions before changing storage.
- Use reversible migrations when the framework supports them; explain irreversible operations.
- Preserve referential integrity, nullability, uniqueness, and existing data.
- Avoid destructive resets or dropping/renaming production columns without explicit approval and a migration plan.
- Consider indexes and query plans for relevant high-volume paths; do not add indexes without a reason.
- Use transactions for related writes and parameterized query mechanisms.
- Test migration behavior and edge cases when possible. Never expose database credentials.
