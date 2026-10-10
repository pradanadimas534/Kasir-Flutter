# Backend Engineering

- Follow the project's framework and API conventions.
- Validate all untrusted input on the server and authorize every protected operation.
- Use parameterized queries or the framework's safe query APIs. Never concatenate untrusted input into SQL or shell commands.
- Return predictable status codes and error shapes without leaking secrets, stack traces, or private data.
- Keep business rules out of transport/controller glue when the project architecture provides an appropriate service layer.
- Consider rate limits, idempotency, transaction boundaries, logging, and failure paths where relevant.
- Do not silently change public API contracts. Add or update tests for behavior and authorization.
