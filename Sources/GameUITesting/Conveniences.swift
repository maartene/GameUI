// Conveniences.swift — intent-naming wrappers over `collect(_:from:)`.
//
// These are test-shaped: `collectTextColors(from:)` is a sentence a test says and a game
// screen never says. That is why they live here rather than on `GameUI`, whose audience is
// game developers (ADR-006 Alternative F). None of them contains traversal logic; each is a
// single call to `collect`.
//
// `collectPlayerStatus` and friends are downstream domain vocabulary and deliberately do not
// travel — downstream expresses them as `collect(PlayerStatusView.self, from: view).first`.

import GameUI

/// The content of every `Text` **and** every `WrappedText` in the tree, in declaration order.
///
/// - Note: the asymmetry with `collectTextColors`, which covers `Text` only, is deliberate
///   and inherited verbatim from the field helper this target replaces. `WrappedText` carries
///   one `color` for all of its lines, so merging the two colour lists would produce a result
///   that cannot be zipped against this one. Documented rather than silently smoothed over.
public func collectTexts(from view: some View) -> [String] {
    // __SCAFFOLD__ — DISTILL RED scaffold.
    _ = view
    return []
}

/// Every button in the tree, as `any AnyButton`, in declaration order.
public func collectButtons(from view: some View) -> [any AnyButton] {
    // __SCAFFOLD__ — DISTILL RED scaffold.
    _ = view
    return []
}

/// The colour of every `Text` in the tree, in declaration order.
///
/// `WrappedText` is **not** included — see the note on `collectTexts`.
public func collectTextColors(from view: some View) -> [Color] {
    // __SCAFFOLD__ — DISTILL RED scaffold.
    _ = view
    return []
}

/// Every `ProgressBar` in the tree, in declaration order.
public func collectProgressBars(from view: some View) -> [ProgressBar] {
    // __SCAFFOLD__ — DISTILL RED scaffold.
    _ = view
    return []
}

/// Every `Texture` in the tree, in declaration order.
public func collectTextures(from view: some View) -> [Texture] {
    // __SCAFFOLD__ — DISTILL RED scaffold.
    _ = view
    return []
}
