# GameUI

A declarative, SwiftUI-inspired UI framework for games. Provides a pure layout engine that computes frame positions from a composable view tree. It was created as a layout engine for [raylib]((https://www.raylib.com/index.html), but it has no dependency on any specific rendering library. See also the example raylib renderer.

## Why

Building game UIs typically means writing imperative, pixel-by-pixel positioning code scattered throughout game logic. GameUI brings SwiftUI's declarative style to game development:

- Describe *what* the UI looks like, not *where* to draw each pixel
- A pure, deterministic layout engine separates structure from rendering
- No Foundation, no CGFloat, no platform-specific dependencies — works on Linux too

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/maartene/GameUI.git", from: "1.0.0"),
],
targets: [
    .target(name: "YourGame", dependencies: ["GameUI"]),
]
```

## Quick Start

```swift
import GameUI

// 1. Build a view tree using the declarative DSL
let healthBar = VStack(spacing: 4) {
    Text(content: "Health", fontSize: 14, color: .white)
    HStack(spacing: 0) {
        Rectangle(color: .green).frame(width: 150, height: 20)
        Spacer()
    }.frame(width: 200, height: 20)
}

// 2. Run the layout engine
let constraints = LayoutConstraints(maxWidth: 1280, maxHeight: 800)
let tree = LayoutEngine().layout(healthBar, in: constraints)

// 3. Walk the resulting tree and draw each node with your renderer
//    Every node has a `.frame` (origin + size) you can pass to your draw calls
```

## How It Works

Layout is a three-step pipeline:

1. **Declare** a view tree using `@ViewBuilder` — the same nested syntax as SwiftUI.
2. **Layout** by passing the root view and available space to `LayoutEngine.layout(_:in:)`.
3. **Render** by walking the returned `LayoutTree` and calling your engine's draw functions with each node's `.frame`.

The engine is side-effect-free: the same view tree and constraints always produce the same output. Nothing is drawn by GameUI itself.

### Text measurement

Text sizing depends on your renderer's font metrics. Inject a measurer closure when creating the engine:

```swift
let engine = LayoutEngine { content, fontSize in
    // Ask your renderer how large this string will be
    let (w, h) = myRenderer.measureText(content, size: fontSize)
    return Size(width: w, height: h)
}
```

Without a measurer, text nodes fall back to a fixed placeholder size.

## Views

### Primitives

| View | Description |
|------|-------------|
| `Rectangle(color:)` | Solid-color rectangle |
| `Text(content:fontSize:color:alignment:)` | Text label |
| `Texture(textureName:tint:)` | Named texture / sprite |
| `Button(action:content:)` | Tappable region wrapping any view |
| `Spacer()` | Flexible gap that expands to fill available space |
| `WrappedText(content:fontSize:color:)` | Multi-line text that wraps at a constrained width |
| `Checkbox(isChecked:label:subtitle:onToggle:)` | Toggle with label |
| `Slider(value:label:onTap:)` | 0–1 range slider |

### Containers

| Container | Description |
|-----------|-------------|
| `HStack(spacing:content:)` | Lays children out horizontally |
| `VStack(spacing:content:)` | Lays children out vertically |
| `ZStack(content:)` | Stacks children at the same origin (layered) |

### Modifiers

```swift
someView.frame(width: 200, height: 100)  // Fixed size
someView.padding(8)                       // Uniform inset on all sides
```

## Geometry types

```swift
Point(x: Float, y: Float)         // 2D position
Size(width: Float, height: Float)  // Width and height
Rect(origin: Point, size: Size)    // Combined (frame)
LayoutConstraints(maxWidth:maxHeight:)
```

## Colors

```swift
Color.white  Color.black  Color.red  Color.green
Color.blue   Color.yellow Color.cyan Color.magenta
Color(r: 1.0, g: 0.5, b: 0.0, a: 1.0)  // Custom RGBA
```

## Hit Detection

Every `LayoutNode` in the output tree carries a `.frame`. Use `Rect.contains(_:)` to test whether a mouse position lands on a node:

```swift
let mouse = Point(x: mouseX, y: mouseY)
if node.frame.contains(mouse) {
    // trigger the action for this node
}
```

`GUIContext` bundles the mouse position and can be threaded through your render/event loop.

## Example: HP bar

```swift
let fill: Float = 0.6  // 60% health remaining

let hpBar = VStack(spacing: 2) {
    Text(content: "HP", fontSize: 12, color: .white)
    HStack(spacing: 0) {
        Rectangle(color: .green).frame(width: 200 * fill, height: 16)
        Spacer()
    }.frame(width: 200, height: 16)
}

let tree = LayoutEngine().layout(hpBar, in: LayoutConstraints(maxWidth: 300, maxHeight: 100))
```

## Raylib Integration Example

GameUI was originally created for DCJam2025 (private project), which uses [Raylib](https://www.raylib.com) as its renderer. Here's the full pattern for wiring GameUI into a Raylib game.

### 1. Text measurement

Use Raylib's `MeasureTextEx` to give the layout engine accurate text sizes:

```swift
func makeTextMeasurer(font: Font) -> @Sendable (String, Float) -> GameUI.Size {
    return { text, fontSize in
        let spacing: Float = 4.0 * fontSize / 64.0
        let measured = MeasureTextEx(font, text, fontSize, spacing)
        return GameUI.Size(width: measured.x, height: measured.y)
    }
}
```

### 2. Intermediate draw commands

Instead of calling Raylib directly from the renderer, collect typed draw commands first. This keeps the renderer free of side effects and makes it easy to test:

```swift
enum DrawCommand2D {
    case rectangle(position: Vector2, size: Vector2, color: raylib.Color)
    case text(position: Vector2, text: String, fontSize: Float, color: raylib.Color)
    case texture(position: Vector2, textureName: String, tint: raylib.Color)
}
```

### 3. Recursive renderer

Walk the `LayoutTree` in parallel with the view tree. Pattern-match on the view type to emit the right draw command for each node:

```swift
struct GameUIRaylibRenderer {
    func render(view: some GameUI.View, layout: LayoutTree) -> [DrawCommand2D] {
        renderNode(view: view, node: layout.root)
    }

    private func renderNode(view: any GameUI.View, node: LayoutNode) -> [DrawCommand2D] {
        if let rect = view as? GameUI.Rectangle {
            return [.rectangle(
                position: Vector2(x: node.frame.origin.x, y: node.frame.origin.y),
                size: Vector2(x: node.frame.size.width, y: node.frame.size.height),
                color: toRaylibColor(rect.color)
            )]
        }

        if let textView = view as? GameUI.Text {
            return [.text(
                position: Vector2(x: node.frame.origin.x, y: node.frame.origin.y),
                text: textView.content,
                fontSize: textView.fontSize,
                color: toRaylibColor(textView.color)
            )]
        }

        if let wt = view as? GameUI.WrappedText {
            let lines = wt.wrappedLines(measurer: textMeasurer, maxWidth: node.frame.size.width)
            return zip(lines, node.children).map { line, child in
                .text(
                    position: Vector2(x: child.frame.origin.x, y: child.frame.origin.y),
                    text: line,
                    fontSize: wt.fontSize,
                    color: toRaylibColor(wt.color)
                )
            }
        }

        if view is GameUI.Spacer { return [] }

        // Button — recurse into its content child
        if let button = view as? AnyButton {
            let childNode = node.children.first ?? node
            return renderNode(view: button.anyContent, node: childNode)
        }

        // Containers (HStack, VStack, ZStack) — zip children and recurse
        if let container = view as? ContainerView {
            return zip(container.containerChildren, node.children).flatMap {
                renderNode(view: $0, node: $1)
            }
        }

        return []
    }
}
```

### 4. Executing draw commands

Execute the collected commands inside Raylib's `BeginDrawing` / `EndDrawing` block:

```swift
func executeDrawCommand(_ cmd: DrawCommand2D) {
    switch cmd {
    case .rectangle(let pos, let size, let color):
        DrawRectangleV(pos, size, color)
    case .text(let pos, let text, let fontSize, let color):
        DrawText(text, Int32(pos.x), Int32(pos.y), Int32(fontSize), color)
    case .texture(let pos, let name, let tint):
        DrawTextureEx(getTexture(name), pos, 0, 1, tint)
    }
}
```

### 5. Render loop

Tie it together in your game loop. Cache the last view and layout tree so the same snapshot can be used for hit-testing on mouse release without re-running layout:

```swift
var lastView: (any GameUI.View)?
var lastLayout: LayoutTree?

// Inside your game loop, each frame:
func drawGUI() {
    let view = buildView()          // construct the GameUI view tree
    let constraints = LayoutConstraints(maxWidth: 1280, maxHeight: 720)
    let layout = LayoutEngine(textMeasurer: textMeasurer).layout(view, in: constraints)

    lastView = view
    lastLayout = layout

    let cmds = GameUIRaylibRenderer().render(view: view, layout: layout)
    cmds.forEach { executeDrawCommand($0) }
}

// On mouse release:
func handleClick() {
    guard let view = lastView, let layout = lastLayout else { return }
    let pos = GetMousePosition()
    hitTest(view: view, node: layout.root, at: pos)
}
```

### 6. Hit detection

Recursively walk the same view/layout pair on mouse release. When a `Button`'s frame contains the click position, fire its action:

```swift
func hitTest(view: any GameUI.View, node: LayoutNode, at pos: Vector2) {
    if let btn = view as? AnyButton {
        let pt = GameUI.Point(x: pos.x, y: pos.y)
        if node.frame.contains(pt) {
            btn.anyAction()
            return
        }
    }

    if let container = view as? ContainerView {
        for (child, childNode) in zip(container.containerChildren, node.children) {
            hitTest(view: child, node: childNode, at: pos)
        }
    }
}
```

## Limitations

- `@ViewBuilder` supports up to 4 children per container. For more, nest containers.
- No animation or state management — GameUI is purely a layout library.
- No built-in renderer. You supply the draw calls.

## Requirements

- Swift 6.2+
- macOS 15.0+ (or any platform supporting Swift 6 with the `Testing` framework)
