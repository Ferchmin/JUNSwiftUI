# Quick Start

## Prerequisites

- Xcode 15.0+
- macOS 14.0+ to develop, iOS 17.0+ or macOS 14.0+ to deploy
- Swift 5.9+

## Get the code

```bash
git clone https://github.com/ferchmin/JUNSwiftUI.git
cd JUNSwiftUI
```

## Build and test the package

```bash
swift build
swift test
```

Or open `Package.swift` in Xcode and press ⌘U.

## Run the example app

```bash
open Example/JUNSwiftUIApp.xcodeproj
```

Select the `JUNSwiftUIApp` scheme and press ⌘R. The app:

- browses the canonical JUN examples
- renders JSON you paste into it
- shows any diagnostics a document produced
- handles the actions the counter example names

There is no `swift run` target — the package is a library, and the example is an Xcode app.

## Render your first document

```swift
import SwiftUI
import JUNSwiftUI

struct DemoView: View {
    private static let json: String = """
    {
      "type": "vstack",
      "properties": { "spacing": 12, "padding": 16 },
      "children": [
        { "type": "text", "properties": { "content": "Hello, JUN!", "fontSize": 28, "fontWeight": "bold" } },
        { "type": "text", "properties": { "content": "Rendered from JSON", "fontSize": 14, "foregroundColor": "gray" } },
        { "type": "button", "properties": {
            "label": "Tap me",
            "action": "sayHello",
            "backgroundColor": "blue",
            "foregroundColor": "white",
            "padding": 12,
            "cornerRadius": 8
        }}
      ]
    }
    """

    var body: some View {
        if let document = try? JSONLoader.loadFromString(Self.json) {
            ComponentRenderer(document: document)
                .junActionHandler { action in
                    print("Document asked for: \(action.name)")
                }
        }
    }
}
```

Paste the same JSON into the example app's **Paste JSON** sheet to see it without writing any
Swift.

## Common patterns

### A stack of text

```json
{
  "type": "vstack",
  "properties": { "spacing": 10, "alignment": "leading" },
  "children": [
    { "type": "text", "properties": { "content": "Item 1" } },
    { "type": "text", "properties": { "content": "Item 2" } }
  ]
}
```

### An icon beside a label

```json
{
  "type": "hstack",
  "properties": { "spacing": 8 },
  "children": [
    { "type": "image", "properties": { "systemImage": "star.fill", "foregroundColor": "yellow", "width": 20, "height": 20 } },
    { "type": "text", "properties": { "content": "Featured", "fontWeight": "semibold" } }
  ]
}
```

### A remote image

```json
{
  "type": "image",
  "properties": {
    "imageURL": "https://picsum.photos/400/250",
    "resizable": true,
    "contentMode": "fill",
    "width": 400,
    "height": 250,
    "cornerRadius": 12,
    "clipped": true
  }
}
```

### A horizontal scroller

```json
{
  "type": "scrollView",
  "properties": { "axis": "horizontal", "showsIndicators": false },
  "children": [
    { "type": "hstack", "properties": { "spacing": 12 }, "children": [] }
  ]
}
```

## Loading from a server

```swift
let document = try await JSONLoader.load(from: URL(string: "https://api.example.com/ui/home")!)
```

Use the `async` loader for anything remote. `loadFromFile` refuses non-file URLs, because
reading one synchronously blocks the calling thread with no timeout and no cancellation.

## When a document does not render

Every loader returns a `JUNDocument` carrying the problems found while parsing it:

```swift
let document = try JSONLoader.loadFromString(json)

for diagnostic in document.diagnostics {
    print(diagnostic)   // error at children[3].properties.imageURL: expected String
}
```

Diagnostics also go to `OSLog` in debug builds — filter the console on the `com.jun.swiftui`
subsystem. The example app displays them above the rendered document.

| Symptom | Likely cause |
|---------|--------------|
| A component is missing entirely | An unknown `type`. Look for a warning diagnostic naming it |
| A property seems ignored | Wrong JSON type. Look for an error diagnostic naming the property |
| A shape is the wrong color | `foregroundColor` is the fill; `backgroundColor` is only a fallback |
| A sized component is too big | `padding` is inside `width`/`height`, so check both |
| An image shows a placeholder | Exactly one of `imageURL`, `imageName`, `systemImage` is required |
| A button does nothing | No `junActionHandler` is installed, or none of its cases match the name |
| Loading throws immediately | `maxDepth` or `maxNodes` exceeded — see `JUNParseOptions` |

To turn any of these into a thrown error rather than a diagnostic, parse with
`options: .strict`.

## Editing the examples

The example documents come from the [JUN repository](https://github.com/ferchmin/JUN) and are
synced into `Example/JUNSwiftUIApp/Resources/Examples/`:

```bash
./Scripts/sync-examples.sh          # refresh from upstream
./Scripts/sync-examples.sh --check  # fail if they have drifted
```

Edit them upstream rather than here — CI fails on drift, which is what stops the copies from
diverging.

## Next steps

- [README.md](README.md) for the full API
- [JUN specification](https://github.com/ferchmin/JUN/blob/main/spec/jun-spec.md) for the format
- `Sources/JUNSwiftUI/Views/ComponentRenderer.swift` to see how components map to SwiftUI
