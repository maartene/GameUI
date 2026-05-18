# DISCUSS Decisions — padding-directional

## Key Decisions

- **[D1] New `AnyDirectionalPaddingModifier` protocol (not reusing `AnyPaddingModifier`)**: x/y semantics are not reducible to a single `paddingAmount`. Reusing `AnyPaddingModifier` would require a lossy projection (e.g., mapping x or y to `paddingAmount` and discarding the other). A dedicated protocol keeps semantics precise and prevents accidental dispatch to `layoutPaddingNode` with wrong data. See: user-stories.md US-PDR-01 Technical Notes.

- **[D2] Return type is `DirectionalPaddingModifier<Self>`**: consistent with `PaddingModifier<Self>` and `FrameModifier<Self>` patterns already in the codebase. Returning `any View` would erase the concrete type and break modifier chaining. No debate required.

- **[D3] `hitTestButton` must be updated in the same slice as layout**: shipping layout without the hit-test update would leave directional-padded buttons unreachable in interactive UIs. A game developer calling `.padding(x:y:)` on a button expects both layout and pointer input to work. The two dispatch sites share the same protocol — they are two halves of one contract. See: prioritization.md for coupling rationale, slice-01 for risk table.

- **[D4] Single slice — no split**: the feature has two stories, one protocol, and four implementation tasks. There is no sub-slice that delivers independently verifiable user value without leaving the codebase in a broken state between slices. Single-slice delivery is the correct unit.

- **[D5] `layoutDirectionalPaddingNode` does NOT reuse `outerSizeForPaddedContent`**: that helper takes a single `amount: Float` and applies it uniformly. Forcing x/y through it would require two calls or a refactor. Implementing the size calculation inline in `layoutDirectionalPaddingNode` is simpler, clearer, and lower risk. DESIGN wave may refactor later if a general pattern emerges.

- **[D6] Dispatch order — `AnyDirectionalPaddingModifier` before `AnyPaddingModifier`**: in both `layoutNode` and `hitTestNode`. If `AnyPaddingModifier` were checked first and `DirectionalPaddingModifier` happened to conform to it in the future (it must not), directional padding would be silently mis-routed. Checking more-specific protocol first is the correct pattern. Noted as a risk in slice-01 risk table.

---

## Requirements Summary

- **Primary user need**: apply asymmetric horizontal/vertical padding to any `View` without nesting two modifiers or writing a custom type
- **Feature type**: user-facing library API — game developer is the direct user; GameUI library is the product
- **Walking skeleton**: not applicable (brownfield feature; existing modifier pattern is the scaffold)
- **Slice count**: 1 (see D4)

---

## Constraints Established

- No Foundation import — `Float`-based `Size`, `Rect`, `Point` throughout
- Swift 6.2 strict concurrency — all new functions non-isolated, operating on value types
- Negative padding values treated as 0: `max(0, paddingX)`, `max(0, paddingY)` — consistent with `layoutPaddingNode`
- Return type must be generic (`DirectionalPaddingModifier<Self>`) — not `any View` — to preserve modifier chaining

---

## Risk Register

| Risk | Likelihood | Impact | Status |
|------|-----------|--------|--------|
| Dispatch order: `AnyDirectionalPaddingModifier` shadowed by `AnyPaddingModifier` | Low | High | Mitigated — documented in slice-01; verified by layout dispatch test |
| `hitTestNode` update missed | Medium | High | Mitigated — US-PDR-02 AC-1 test must be written RED before implementation |
| `outerSizeForPaddedContent` not adaptable for x/y asymmetry | Low | Medium | Mitigated — D5 above; `layoutDirectionalPaddingNode` implements its own calculation |
| Axis transposition (paddingX / paddingY swapped) | Low | High | Mitigated — AC tests both zero-x and zero-y scenarios independently |

---

## Upstream Changes

- No prior DISCOVER or DIVERGE wave for this feature
- Risk noted: absence of DIVERGE means no validated ODI outcome or job statement. The job is explicit from the feature request ("apply different horizontal and vertical insets with a single call"), so this is treated as acceptable risk for a small brownfield API extension.
- No assumptions to back-propagate to DISCOVER wave.
