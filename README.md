# JUNSwiftUI

SwiftUI implementation of the [JUN (JSON UI Notation)](https://github.com/ferchmin/JUN) specification.

**Platform**: iOS 17+ / macOS 14+
**Language**: Swift 5.9+
**Implements**: JUN v1.2
**License**: MIT

---

## Overview

JUNSwiftUI renders [JUN](https://github.com/ferchmin/JUN) documents as native SwiftUI views. It
is the reference implementation of the specification, and it is tested against the
specification's own example documents on every commit.

## Features

- Complete JUN v1.2 support
- Native SwiftUI rendering with `@ViewBuilder`
- Remote, bundled and system images
- Host-mediated actions with parameters
- Diagnostics that say *where* a document is wrong, not just that it is
- Bounded parsing for documents from untrusted sources
- Zero external dependencies

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ferchmin/JUNSwiftUI.git", from: "1.2.0")
]
```

Or in Xcode: **File → Add Package Dependencies**, then enter
`https://github.com/ferchmin/JUNSwiftUI`.

## Quick Start

```swift
import JUNSwiftUI

struct HomeView: View {
    @State private var document: JUNDocument?

    var body: some View {
        Group {
            if let document {
                ComponentRenderer(document: document)
                    .junActionHandler { action in
                        print("The document asked for \(action.name)")
                    }
            } else {
                ProgressView()
            }
        }
        .task {
            document = try? await JSONLoader.load(
                from: URL(string: "https://api.example.com/ui/home")!
            )
        }
    }
}
```

## Loading

| Source | API |
|--------|-----|
| Network | `try await JSONLoader.load(from: url)` |
| String | `try JSONLoader.loadFromString(json)` |
| Data | `try JSONLoader.loadFromData(data)` |
| Bundle | `try JSONLoader.loadFromBundle(filename: "home")` |
| Local file | `try JSONLoader.loadFromFile(fileURL)` |

Every loader returns a ``JUNDocument``: the component tree plus the diagnostics collected while
parsing it.

`loadFromFile` rejects non-file URLs on purpose. Reading a remote URL synchronously blocks the
calling thread — usually the main one — with no timeout and no cancellation, so remote
documents go through the `async` loader instead.

## Actions

A JUN document can only *name* an intent. Nothing happens unless the host application installs
a handler and implements that name, which is what stops a document fetched from a server from
being able to act on its own.

```json
{
  "type": "button",
  "properties": {
    "label": "Add to cart",
    "action": { "name": "addToCart", "params": { "productId": "SKU-42", "quantity": 1 } }
  }
}
```

```swift
ComponentRenderer(document: document)
    .junActionHandler { action in
        switch action.name {
        case "addToCart":
            cart.add(action.params["productId"]?.stringValue, quantity: action.params["quantity"]?.intValue ?? 1)
        default:
            break
        }
    }
```

`"action": "checkout"` is shorthand for `{"name": "checkout", "params": {}}`. Parameter values
are JSON scalars: string, number, boolean or null.

Action names containing a dot are reserved by the specification for future standard actions.
None are defined yet; they are delivered to your handler unchanged, and `JUNAction.isReserved`
tells you when you have one.

## Diagnostics and strictness

Parsing is lenient about anything that looks like a *newer* document and loud about anything
that looks like a *broken* one. Those two cases pull in opposite directions, so they are
handled separately:

- **Unknown component types, unknown properties, unrecognised enum values** — degraded, with a
  warning. A renderer that rejected a document for containing one unfamiliar component would
  force every server-side addition to wait for an app release.
- **Wrong value types, missing required properties** — the component still renders with
  defaults, but an error diagnostic records what went wrong and where. A malformed component
  never takes out its siblings.

```swift
let document = try JSONLoader.loadFromString(json)

for diagnostic in document.diagnostics {
    // error at children[3].properties.imageURL: expected String
    analytics.record(diagnostic.description)
}
```

Diagnostics are logged to `OSLog` automatically in debug builds. In release they travel on the
document, so you can forward them to your telemetry — which is how the server that produced a
broken document finds out, from the field, that it is broken.

Use `JUNParseOptions.strict` in tests and build pipelines to turn any of it into a thrown
error:

```swift
let document = try JSONLoader.loadFromData(data, options: .strict)
```

Parsing is bounded regardless of the policies: `maxDepth` (64) and `maxNodes` (10,000) reject a
document outright, since those exist to protect against untrusted input.

## Component mapping

| JUN | SwiftUI |
|-----|---------|
| `vstack` / `hstack` / `zstack` | `VStack` / `HStack` / `ZStack` |
| `scrollView` | `ScrollView` |
| `text` | `Text` |
| `image` | `AsyncImage`, `Image(_:)` or `Image(systemName:)` |
| `button` | `Button` |
| `rectangle` / `circle` | `Rectangle` / `Circle` |
| `spacer` / `divider` | `Spacer` / `Divider` |

### Property mapping

| JUN | SwiftUI |
|-----|---------|
| `padding` | `.padding(_)`, applied inside `width`/`height` |
| `width`, `height` | `.frame(width:height:)` |
| `maxWidth`, `maxHeight` | `.frame(maxWidth:maxHeight:)`, composable with the above |
| `foregroundColor` | `.foregroundStyle(_)`, or a shape's fill |
| `backgroundColor` | `.background(_)`, or a shape's fill when no `foregroundColor` is given |
| `cornerRadius` | `.clipShape(RoundedRectangle(...))` |
| `clipped` | `.clipped()`, or `.scrollClipDisabled` on a ScrollView |
| `aspectRatio`, `contentMode` | `.aspectRatio(_:contentMode:)` |
| `font` | `.font(.custom(_:size:))` |

Notes:

- **Padding is internal.** `width: 100, padding: 16` occupies 100 points in total.
- **Shapes are filled by `foregroundColor`**, falling back to `backgroundColor`. A shape given
  only a background would otherwise paint it behind an opaque default fill and render black.
- **`clipped: false` on a ScrollView** applies `.scrollClipDisabled(true)`.

## Images

Exactly one source is required:

| Property | Resolves against | Rendered with |
|----------|------------------|---------------|
| `imageURL` | The document | `AsyncImage`, with loading and failure states |
| `imageName` | Your asset catalogue | `Image(_:)` |
| `systemImage` | The platform (SF Symbols) | `Image(systemName:)` |

`imageName` and `systemImage` resolve against assets the document cannot ship, so a document
that must render identically everywhere should prefer `imageURL`.

## Fonts

`font` names a family; unavailable names fall back to the system font. System faces such as
Helvetica, Courier and Georgia work out of the box. Application-bundled fonts must be
registered by the host — on iOS, under `UIAppFonts` in `Info.plist`.

## Examples

The example documents in this repository are the JUN repository's own, synced by
`Scripts/sync-examples.sh` and checked for drift in CI. The test suite parses every one of them
in strict mode, so "reference implementation" means something checkable.

```bash
./Scripts/sync-examples.sh          # refresh from upstream
./Scripts/sync-examples.sh --check  # fail if they have drifted
```

## Running the example app

```bash
git clone https://github.com/ferchmin/JUNSwiftUI.git
open JUNSwiftUI/Example/JUNSwiftUIApp.xcodeproj
```

Build and run (⌘R). The app browses the canonical examples, renders pasted JSON, shows any
diagnostics a document produced, and handles the actions the counter example names.

## Project structure

```
Sources/JUNSwiftUI/
├── Models/
│   ├── UIComponent.swift          # Component tree and its decoding
│   ├── ComponentProperties.swift  # Per-type property structs
│   ├── JUNAction.swift            # Action model
│   └── JUNValue.swift             # Action parameter values
├── Parsing/
│   ├── JSONLoader.swift           # Entry points
│   ├── JUNDocument.swift          # Tree + diagnostics
│   ├── JUNDiagnostic.swift        # Problems, with locations
│   ├── JUNParseOptions.swift      # Leniency policies and limits
│   ├── JUNParseError.swift        # Whole-document failures
│   └── JUNDecodingContext.swift   # Diagnostic collection during decode
└── Views/
    ├── ComponentRenderer.swift    # The renderer
    ├── CommonModifiers.swift      # Universal properties
    ├── JUNActionHandler.swift     # Host action dispatch
    └── JUNColor.swift             # Color parsing
```

## Requirements

- iOS 17.0+ or macOS 14.0+
- Swift 5.9+, Xcode 15.0+

## Known limitations

- No navigation, data binding, `forEach`, or form components. These are JUN roadmap items; see
  the [specification](https://github.com/ferchmin/JUN/blob/main/spec/jun-spec.md).
- No image caching beyond what `AsyncImage` provides, and placeholder views are not yet
  configurable.
- No theming: color names map to fixed SwiftUI colors.
- Children on `button` are rendered as its label. This is an extension, not part of JUN v1.2 —
  the parser emits a warning, and whether to change the specification or drop the capability is
  undecided.

## Contributing

Specification changes belong in the [JUN repository](https://github.com/ferchmin/JUN) first —
prose, schema and examples in one change — and land here afterwards. That ordering is not
bureaucracy: the v1.1 schema shipped without the property v1.1 was released for, precisely
because it was written the other way round.

For changes here: keep the tests passing, keep `swiftlint --strict` clean, and add coverage for
what you changed.

## Related projects

- **[JUN Specification](https://github.com/ferchmin/JUN)** — the format
- **JUNReact**, **JUNAndroid** — not yet written

## License

MIT — see [LICENSE](LICENSE)

## Author

Pawel Zgoda-Ferchmin
