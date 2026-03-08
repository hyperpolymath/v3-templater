<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# v3-templater — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              APPLICATION / USER         │
                        │        (Template Rendering / API)       │
                        └───────────────────┬─────────────────────┘
                                            │ Render / Compile
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           TEMPLATING ENGINE             │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ Parser    │  │  Compilation      │  │
                        │  │ (Lexer)   │──►  Core (WASM)      │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        │        │                 │              │
                        │  ┌─────▼─────┐  ┌────────▼──────────┐  │
                        │  │ Cache     │  │  Filter / Helper  │  │
                        │  │ (LRU)     │  │  Registry         │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │                 │
                                 ▼                 ▼
                        ┌─────────────────────────────────────────┐
                        │           OUTPUT DOCUMENTS              │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ HTML      │  │  JSON             │  │
                        │  │ (Escaped) │  │  (Structured)     │  │
                        │  └───────────┘  └───────────────────┘  │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  RSR PLATINUM         0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE ENGINE (RESCRIPT)
  Template Parser                   ██████████ 100%    Variables/Loops/Inherit stable
  Compilation Core                  ██████████ 100%    No-eval generation verified
  LRU Caching                       ██████████ 100%    Smart caching active
  Built-in Filters (30+)            ██████████ 100%    String/Array/Number verified

INTERFACES & TOOLS
  Deno API (mod.ts)                 ██████████ 100%    Production export stable
  CLI Tool (v3t)                    ██████████ 100%    Full command set active
  Plugin System                     ██████████ 100%    Extensibility verified

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build/bench tasks
  .machine_readable/                ██████████ 100%    STATE tracking active
  RSR PLATINUM Compliance           ██████████ 100%    All 42 requirements met

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ██████████ 100%    Production-ready Platinum Repo
```

## Key Dependencies

```
Template Source ──► Parser / Lexer ────► Compilation ──────► Rendered HTML
     │                 │                   │                    │
     ▼                 ▼                   ▼                    ▼
 Data Context ──► Filter Registry ───► LRU Cache ────────► Output
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
