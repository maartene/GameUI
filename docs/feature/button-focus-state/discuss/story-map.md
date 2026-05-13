# Story Map — button-focus-state

## Backbone (User Activities)

| Activity 1                  | Activity 2                     | Activity 3                     |
|-----------------------------|--------------------------------|--------------------------------|
| Declare focused button      | Evaluate view tree             | Render focused button          |

---

## Walking Skeleton

Not applicable. `Button` already exists with a full end-to-end path (declaration → layout → rendering). This feature adds one stored property — no new plumbing.

---

## Story Map

| Backbone →                  | Declare focused button          | Evaluate view tree              | Render focused button           |
|-----------------------------|---------------------------------|---------------------------------|---------------------------------|
| **Release 1 (single slice)**| Construct `Button(isFocused:)`  | LayoutEngine is unchanged       | Renderer reads `isFocused` flag |

### Stories in Slice 1

| Story ID | Story                                                                 | AC count |
|----------|-----------------------------------------------------------------------|----------|
| S-01     | Button carries isFocused flag (default false, settable to true)       | 5        |

---

## Elephant Carpaccio Slices

Only one slice is justified. The feature is atomically a Bool property addition:

| Slice | Name                   | Stories | Effort  | Learning Hypothesis                                                                 |
|-------|------------------------|---------|---------|-------------------------------------------------------------------------------------|
| 01    | button-focus-flag      | S-01    | ≤ 2h    | Disproves that isFocused needs a new type or GUIContext change to be inspectable     |

### Carpaccio Taste Tests

- **4+ new components?** No — one property, one initialiser parameter. PASS.
- **Every slice depends on a new abstraction?** N/A — single slice. PASS.
- **No slice disproves a pre-commitment?** Slice 01 disproves "isFocused requires GUIContext or a new FocusableButton type." PASS.
- **Synthetic data only?** Tests use direct struct instantiation — that IS production use for a library. PASS.
- **2+ slices identical except for scale?** N/A — single slice. PASS.
