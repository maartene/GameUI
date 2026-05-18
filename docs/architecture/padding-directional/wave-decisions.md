# DESIGN Decisions — padding-directional

## Key Decisions

- **[D1] Unify at protocol level (Option B):** `AnyDirectionalPaddingModifier` replaces `AnyPaddingModifier`. `PaddingModifier` conforms to the new protocol by projecting its `amount` onto both `paddingX` and `paddingY`. Rationale: uniform padding is a special case of directional padding — in an immutable value-type system the "square-rectangle" unification is semantically correct and carries no Liskov Substitution risk. Unification halves the dispatch complexity in both `layoutNode` and `hitTestNode` and permanently closes the dispatch-order fragility identified in DISCUSS D6. See: adr-003.

- **[D2] `PaddingModifier` concrete type preserved:** `padding(_ amount:)` continues to return `PaddingModifier<Self>`. The concrete return type, the call-site syntax, and the stored `amount: Float` property are all unchanged. `PaddingModifier` gains two new computed properties (`paddingX`, `paddingY`) and loses `AnyPaddingModifier` conformance (protocol retired). The breaking change is limited to the `AnyPaddingModifier` protocol and the `paddingAmount` property — not the concrete type. See: adr-003.

- **[D3] `layoutDirectionalPaddingNode` replaces `layoutPaddingNode`:** A single private function handles both uniform (paddingX == paddingY) and asymmetric cases. It accepts `any AnyDirectionalPaddingModifier`, reads `paddingX` and `paddingY` from the protocol, and computes child constraints independently per axis. The DISCUSS D5 decision ("do not reuse `outerSizeForPaddedContent`") is superseded — instead, `outerSizeForPaddedContent` is replaced by `outerSizeForDirectionalPaddedContent(paddingX:paddingY:)`, which generalises the existing helper rather than duplicating it.

- **[D5] Deprecate `AnyPaddingModifier` and `paddingAmount`, not remove:** `@available(*, deprecated, renamed: "AnyDirectionalPaddingModifier")` on the protocol and `@available(*, deprecated, message: "Use paddingX or paddingY")` on `paddingAmount`. This gives external callers a compiler-warning migration window rather than a hard break. `PaddingModifier` itself is NOT deprecated — it is still the return type of `padding(_ amount:)` and deprecating it now would warn on every `.padding(8)` call. The path to Option C (remove `PaddingModifier` entirely) requires a future PR that deprecates `PaddingModifier` and changes `padding(_ amount:)` to return `DirectionalPaddingModifier<Self>`.

- **[D4] Single dispatch branch in both `layoutNode` and `hitTestNode`:** The `AnyDirectionalPaddingModifier` check replaces the `AnyPaddingModifier` check at the same position in the dispatch chain. Dispatch order in `layoutNode`: `Text` → `HasFrameSize` → `AnyButton` → `ZStackView` → `WrappedText` → `ContainerView` → `AnyDirectionalPaddingModifier` → default. Dispatch order in `hitTestNode`: `AnyButton` → `ContainerView` → `ZStackView` → `HasFrameSize` → `AnyDirectionalPaddingModifier` → leaf. There is no longer any order-sensitivity between two padding protocols.

---

## Architecture Summary

- **Pattern:** additive extension plus targeted replacement of internal plumbing — no new architectural layer, no new file beyond `View.swift` changes
- **Paradigm:** OOP (protocol-oriented value types) — consistent with CLAUDE.md
- **Key components:** `AnyDirectionalPaddingModifier` (new protocol), `DirectionalPaddingModifier<Content>` (new struct), `PaddingModifier` (extended with new conformance), `layoutDirectionalPaddingNode` (replaces `layoutPaddingNode`), `outerSizeForDirectionalPaddedContent` (replaces `outerSizeForPaddedContent`)

---

## Reuse Analysis

| Existing Component | File | Overlap | Decision | Justification |
|---|---|---|---|---|
| `PaddingModifier` | `Sources/GameUI/View.swift` | Uniform padding — a degenerate case of directional padding where paddingX == paddingY | EXTEND (add conformance to `AnyDirectionalPaddingModifier`) | The type is correct. Its stored `amount: Float` projects onto `paddingX` and `paddingY` without loss. No new type needed for the uniform case. |
| `AnyPaddingModifier` | `Sources/GameUI/View.swift` | Protocol for uniform padding dispatch | RETIRE (remove after conformance migration) | `AnyDirectionalPaddingModifier` subsumes all responsibilities. No callers outside the library. |
| `layoutPaddingNode` | `Sources/GameUI/LayoutEngine.swift` | Layout logic for uniform padding | REPLACE with `layoutDirectionalPaddingNode` | The replacement handles both uniform and asymmetric cases. No parallel implementation. |
| `outerSizeForPaddedContent` | `Sources/GameUI/LayoutEngine.swift` | Outer size computation for padded framed content | REPLACE with `outerSizeForDirectionalPaddedContent(paddingX:paddingY:)` | Signature must change; replacement is a strict generalisation. |
| `AnyPaddingModifier` branch in `layoutNode` | `Sources/GameUI/LayoutEngine.swift` | Dispatch to `layoutPaddingNode` | REPLACE (single `AnyDirectionalPaddingModifier` branch) | Eliminates dispatch-order sensitivity permanently. |
| `AnyPaddingModifier` branch in `hitTestNode` | `Sources/GameUI/HitTest.swift` | Traversal through padding to child view | REPLACE (single `AnyDirectionalPaddingModifier` branch) | Same reasoning as `layoutNode`. Traversal logic is identical. |

---

## Technology Stack

| Choice | Detail | Change |
|---|---|---|
| Swift 6.2 | Existing project language | No change |
| Float geometry | Existing `Size`, `Rect`, `Point` | No change |
| No Foundation | Project constraint | No change — `paddingX`/`paddingY` are `Float`; no stdlib math beyond the existing `max(0, ...)` guards |
| No third-party dependencies | Project constraint | No change |

---

## Constraints Established

- `AnyPaddingModifier` is a `public` protocol — its removal is a source-breaking change. Assessed as low-risk: not used as a return type, parameter type, or stored property type in any public API surface. External callers that reference it are implementing custom layout engines (a narrow use case).
- `paddingX` and `paddingY` replace `paddingAmount` in the protocol surface. The concrete `padding(_ amount:)` return type (`PaddingModifier<Self>`) is unchanged — no call-site migration needed for existing game-developer code.
- Negative padding values are clamped to zero via `max(0, ...)` guards in `layoutDirectionalPaddingNode`, consistent with the existing `layoutPaddingNode` behavior.

---

## Upstream Changes

DISCUSS D5 ("do not reuse `outerSizeForPaddedContent`") is superseded by this design decision. Rather than implementing the size calculation inline in `layoutDirectionalPaddingNode`, the helper is replaced by a generalised version (`outerSizeForDirectionalPaddedContent`). This is strictly better than the inline approach: it keeps `layoutDirectionalPaddingNode` readable and testable as a unit.

DISCUSS D6 ("dispatch order — `AnyDirectionalPaddingModifier` before `AnyPaddingModifier`") is resolved by elimination: with a single protocol, there is no order to manage.

All DISCUSS user stories and acceptance criteria are unaffected. They describe observable behavior (layout metrics, hit-test results), not protocol topology. The implementation path to satisfy them is cleaner under this design, not different.
