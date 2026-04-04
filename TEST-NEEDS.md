# TEST-NEEDS.md — v3-templater

## CRG Grade: C — ACHIEVED 2026-04-04

## Current Test State

| Category | Count | Notes |
|----------|-------|-------|
| JavaScript tests | 5 | `tests/{compiler,filters,integration,lexer,parser}_test.js` |
| Zig FFI tests | 1 | `ffi/zig/test/integration_test.zig` |

## What's Covered

- [x] Compiler integration tests
- [x] Filter function tests
- [x] End-to-end template tests
- [x] Lexer tokenization tests
- [x] Parser AST tests
- [x] Zig FFI integration

## Still Missing (for CRG B+)

- [ ] Property-based template generation
- [ ] Fuzzing for template edge cases
- [ ] Performance benchmarks
- [ ] Memory leak detection
- [ ] Cross-version compatibility tests

## Run Tests

```bash
cd /var/mnt/eclipse/repos/v3-templater && npm test
```
