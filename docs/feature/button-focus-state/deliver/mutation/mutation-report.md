# Mutation Report — button-focus-state

**Date**: 2026-05-13  
**Strategy**: per-feature  
**Status**: SKIPPED

## Skip Justification

Automated mutation testing skipped per user instruction. `muter` (the primary Swift mutation testing tool) is not working reliably in this environment.

## Manual Mutation Analysis

The feature adds 3 production-code lines with 3 distinct mutation targets:

| # | Mutation | Target line | Killing test(s) |
|---|----------|-------------|-----------------|
| M1 | `isFocused: Bool = false` → `isFocused: Bool = true` | Default parameter value | AC2: "Button without isFocused defaults to false" |
| M2 | `self.isFocused = isFocused` → `self.isFocused = !isFocused` | Init assignment | AC1: "Button with true carries true", AC5: multi-button |
| M3 | `self.isFocused = isFocused` → `self.isFocused = false` | Init assignment (always false) | AC1: "Button with true carries true" |

All 3 mutations would be killed by existing tests. Estimated kill rate: **100%** (3/3 mutations killed).

## Recommendation

Run automated mutation testing when `muter` is available and stable.
