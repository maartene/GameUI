# GameUI — Claude Code Guidelines

## Development Paradigm

object-oriented

Protocol-oriented value types consistent with existing Swift codebase. All new types are structs. No classes beyond what Swift 6.2 requires for `Sendable`. Crafter: @nw-software-crafter.

## Mutation Testing Strategy

per-feature

## Technology Constraints

- Swift 6.2
- No Foundation import
- `Float` geometry only (`Size`, `Rect`, `Point` are project-internal)
- Swift Testing framework (not XCTest)
- No third-party dependencies
