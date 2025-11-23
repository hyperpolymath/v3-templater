# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records for the v3-templater project.

## What is an ADR?

An Architecture Decision Record (ADR) captures an important architectural decision made along with its context and consequences.

## Format

Each ADR follows this structure:

- **Title**: Numbered and descriptive
- **Status**: Proposed, Accepted, Deprecated, Superseded
- **Date**: When the decision was made
- **Decision Makers**: Who was involved
- **Context**: What is the issue that we're seeing that is motivating this decision
- **Decision**: What is the change that we're actually proposing or doing
- **Rationale**: Why this decision over alternatives
- **Consequences**: What becomes easier or more difficult to do
- **Alternatives Considered**: What other options were evaluated

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-use-typescript-for-implementation.md) | Use TypeScript for Implementation | Accepted | 2024-01-15 |
| [0002](0002-auto-escaping-by-default.md) | Auto-Escaping by Default | Accepted | 2024-01-15 |

## Creating a New ADR

1. Copy the template: `cp template.md NNNN-title-with-dashes.md`
2. Fill in the sections
3. Update this index
4. Submit for review

## ADR Lifecycle

```
Proposed → Accepted → [Deprecated or Superseded]
```

- **Proposed**: Under discussion
- **Accepted**: Decision made and implemented
- **Deprecated**: No longer recommended but still valid
- **Superseded**: Replaced by a newer ADR

## References

- [ADR GitHub Organization](https://adr.github.io/)
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [ADR Tools](https://github.com/npryce/adr-tools)

## RSR Compliance

ADRs are part of achieving **PLATINUM level** RSR compliance by:
- Documenting architectural decisions
- Providing context for future maintainers
- Creating an audit trail for choices
- Improving project transparency
