# Performance Engineering

- Measure or identify a credible bottleneck before optimizing.
- Consider network requests, payload size, rendering, database query count, caching, and resource lifecycle as appropriate to the stack.
- Prefer simple changes with a clear expected impact; avoid speculative micro-optimizations.
- Preserve correctness, accessibility, and maintainability.
- Use existing profiling or measurement tools where available and report baseline/after measurements only when actually collected.
