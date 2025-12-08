# ADR 0001: Use ReScript and Deno for Implementation

**Status**: Accepted (Supersedes previous TypeScript decision)

**Date**: 2025-12-01

**Decision Makers**: Project Architecture Team

## Context

We need to choose a programming language and runtime for implementing the v3-templater engine. The primary candidates are:

- TypeScript + Node.js
- JavaScript + Node.js
- ReScript + Deno
- Rust (compiled to WASM) + Deno
- Go (compiled to WASM) + Deno

## Decision

We will use **ReScript (OCaml-based) compiled to JavaScript, running on Deno runtime** for the implementation.

## Rationale

### Advantages of ReScript + Deno

1. **Sound Type System**: ReScript provides a robust, sound type system based on OCaml
   - No `null` or `undefined` runtime errors (uses `option` type)
   - Exhaustive pattern matching catches missing cases at compile-time
   - Variant types model domain perfectly (AST nodes, tokens, etc.)

2. **No Runtime Overhead**: Compiles to clean, readable JavaScript
   - No TypeScript runtime baggage
   - No type erasure issues
   - Minimal bundle size

3. **Functional Programming**: Immutable by default, encourages pure functions
   - Easier to reason about code
   - Better for parallel processing (future WASM workers)
   - Natural fit for compiler/parser implementation

4. **Deno Benefits**:
   - No `node_modules` hell
   - Built-in TypeScript support (for .js interop)
   - Security by default (explicit permissions)
   - Modern standard library
   - Native ES modules
   - Built-in test runner, formatter, linter
   - No need for separate tools (jest, eslint, prettier)

5. **Zero TypeScript**: Eliminates TypeScript complexity entirely
   - No type definitions to maintain
   - No compilation quirks
   - Simpler build pipeline

6. **WASM Ready**: Easy path to WASM for performance-critical code
   - ReScript can target WASM (via melange or direct compilation)
   - Deno has excellent WASM support
   - Can optimize hot paths incrementally

### Why Not Alternatives?

**TypeScript + Node.js** (previous choice):
- ❌ Type system has holes (any, as, non-null assertions)
- ❌ node_modules complexity
- ❌ Requires many external tools (jest, eslint, prettier)
- ❌ Runtime type errors still possible
- ✅ Larger community

**JavaScript + Node.js**:
- ❌ No compile-time type checking
- ❌ Higher risk of runtime errors
- ❌ node_modules complexity
- ✅ Would be simpler for some contributors

**Rust + WASM + Deno**:
- ❌ Much higher complexity
- ❌ Longer compile times
- ❌ Smaller contributor pool
- ❌ Overkill for this use case
- ✅ Would provide memory safety guarantees
- ✅ Best performance

**Go + WASM + Deno**:
- ❌ Larger WASM bundles
- ❌ No pattern matching
- ❌ Less mature WASM tooling
- ✅ Simple language
- ✅ Good performance

## Consequences

### Positive

- ✅ **Sound type system** - eliminates entire classes of bugs
- ✅ **No null errors** - option type forces handling of missing values
- ✅ **Pattern matching** - exhaustive, compiler-enforced
- ✅ **Clean JavaScript output** - easy to debug
- ✅ **No Node.js baggage** - fresh start with Deno
- ✅ **Built-in tooling** - no need for jest, eslint, prettier
- ✅ **Security by default** - Deno permissions model
- ✅ **Modern runtime** - native ES modules, top-level await
- ✅ **Smaller dependencies** - no `node_modules` directory
- ✅ **WASM path** - can optimize incrementally

### Negative

- ❌ **Smaller community** - fewer ReScript developers than TypeScript
- ❌ **Learning curve** - functional programming paradigm
- ❌ **Less familiar** - OCaml syntax takes time to learn
- ❌ **Fewer libraries** - smaller ReScript ecosystem
- ❌ **Documentation** - less comprehensive than TypeScript

### Neutral

- 📝 **Compilation required** - but faster than TypeScript
- 📝 **New ecosystem** - Deno vs Node.js differences
- 📝 **Migration path** - can keep .js interop layer for compatibility

## Implementation Notes

### ReScript Configuration

```json
{
  "name": "v3-templater",
  "sources": [{"dir": "src", "subdirs": true}],
  "package-specs": [{"module": "es6", "in-source": true}],
  "suffix": ".bs.js",
  "namespace": true,
  "bsc-flags": ["-bs-no-version-header", "-bs-super-errors"]
}
```

### Deno Configuration

```json
{
  "tasks": {
    "build": "rescript build",
    "test": "deno test --allow-read --allow-write tests/",
    "lint": "deno lint src/",
    "fmt": "deno fmt src/ tests/"
  },
  "importMap": "./import_map.json"
}
```

### Best Practices

1. **Use variant types** for AST nodes, tokens, expressions
2. **Leverage option type** instead of null/undefined
3. **Pattern match exhaustively** - let compiler catch missing cases
4. **Keep functions pure** - easier to test and reason about
5. **Use Belt standard library** - functional utilities
6. **Minimal JavaScript interop** - only for Deno file I/O

### Architecture

```
ReScript Core          JavaScript Layer          Deno Runtime
┌─────────────────┐   ┌────────────────┐      ┌──────────────┐
│ Types.res       │──▶│ Types.bs.js    │      │              │
│ Lexer.res       │──▶│ Lexer.bs.js    │──┐   │              │
│ Parser.res      │──▶│ Parser.bs.js   │  │   │              │
│ Compiler.res    │──▶│ Compiler.bs.js │  ├──▶│  index.js    │
│ Runtime.res     │──▶│ Runtime.bs.js  │  │   │  (interop)   │
│ Template.res    │──▶│ Template.bs.js │  │   │              │
│ Filters.res     │──▶│ Filters.bs.js  │──┘   │              │
│ Cache.res       │──▶│ Cache.bs.js    │      │              │
└─────────────────┘   └────────────────┘      └──────────────┘
     ↓ compile                                        ↓
  rescript build                              deno run/test
```

## Alternatives Considered

See "Why Not Alternatives?" section above.

## Related Decisions

- ADR 0002: Auto-escaping by default (security-first design)
- Future ADR: WASM optimization strategy
- Future ADR: Testing strategy with Deno

## References

- [ReScript Documentation](https://rescript-lang.org/docs/manual/latest/introduction)
- [Deno Manual](https://deno.land/manual)
- [ReScript by Example](https://rescript-lang.org/docs/manual/latest/overview)
- [Deno Standard Library](https://deno.land/std)
- [RSR Framework](https://github.com/Hyperpolymath/rhodium-standard-repository)

## Migration from TypeScript

This decision supersedes the previous TypeScript implementation. The migration provides:

1. **Stronger guarantees** - sound type system vs TypeScript's structural typing
2. **Simpler runtime** - Deno vs Node.js complexity
3. **Better tooling** - built-in vs external tools
4. **Future-proof** - WASM path, modern runtime

## Review Schedule

This decision should be reviewed if:
- ReScript project becomes unmaintained
- Deno adoption significantly declines
- TypeScript adds sound type system
- Better alternatives emerge (stable Rust in browser, etc.)
- Performance becomes critical bottleneck

**Next Review**: 2026-12-01 (annual)

**Last Updated**: 2025-12-01
