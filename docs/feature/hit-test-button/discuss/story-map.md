# Story Map: hit-test-button

## User
Riku Nakamura — game screen developer consuming the GameUI library.

## Goal
I want mouse hover to highlight the button under the cursor without reimplementing frame extraction in every screen.

---

## Backbone

| Traverse view tree for buttons | Check point containment | Return traversal-order index |
|---|---|---|
| Walk `any View` + `LayoutNode` in parallel | Test `Rect.contains(point)` for each AnyButton frame | Return first match index or nil |

---

## Story Map Grid

| Backbone activity | Traverse for buttons | Check containment | Return index |
|---|---|---|---|
| **Walking Skeleton** | `hitTestButton` recurses into view + node simultaneously; AnyButton nodes collected in traversal order | Frame containment check: `frame.contains(point)` | Returns `Int?` — index of first hit, or nil |
| **Release 1** | Handle Button nested inside FrameModifier (framed buttons) | Edge: point on frame boundary counts as contained | (covered by skeleton) |
| **Release 2 (future)** | — | — | Overload accepting `LayoutTree` directly for ergonomics |

---

## Walking Skeleton

The skeleton is the complete end-to-end function. There is no partial value:
a function that traverses but does not return an index, or checks containment
but does not handle nesting, delivers zero value to Riku.

Walking skeleton = **US-01**: `hitTestButton(view:node:at:)` traverses the
view tree, finds `AnyButton` nodes, tests frame containment, returns `Int?`.

This is the only story needed to eliminate the four-piece boilerplate.

---

## Slices

### Slice 1 — Walking Skeleton (ships alone, ≤1 day)

**Stories**: US-01 only

**Outcome**: Riku replaces four pieces of boilerplate with one function call.
Mouse hover highlighting works in SpaceSim.

**Scope Assessment: PASS** — 1 story, 1 bounded context (GameUI public API),
estimated ≤1 day effort.

---

## Priority Rationale

There is only one story. It is the walking skeleton and the feature's entire
scope. Priority discussion is not applicable.

If a future ergonomics overload (`hitTestButton(view:tree:at:)` accepting
`LayoutTree`) is requested, it becomes Release 2 — a Should Have with low
effort and low urgency, deferred until a consuming screen requests it.

---

## Scope Assessment: PASS — 1 story, 1 context, estimated ≤1 day
