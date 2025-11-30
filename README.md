# JUNSwiftUI

SwiftUI implementation of the [JUN (JSON UI Notation)](https://github.com/yourusername/JUN) specification.

**Platform**: iOS 17+ / macOS 14+
**Language**: Swift 5.9+
**License**: MIT

---

## Overview

JUNSwiftUI is a Swift Package that renders [JUN](https://github.com/yourusername/JUN) JSON definitions as native SwiftUI views. It provides a type-safe, performant implementation using Swift's Codable and SwiftUI's declarative syntax.

## Features

- ✅ Full JUN v1.0 specification compliance
- ✅ Native SwiftUI rendering with @ViewBuilder
- ✅ AsyncImage for remote URLs with loading states
- ✅ Type-safe JSON parsing with Codable
- ✅ Zero external dependencies
- ✅ Comprehensive error handling
- ✅ Example app with live samples

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/JUNSwiftUI.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/yourusername/JUNSwiftUI`
3. Select version and add to target

## Quick Start

```swift
import JUNSwiftUI

struct ContentView: View {
    var body: some View {
        // Load from JSON string
        if let component = try? JSONLoader.loadFromString("""
        {
          "type": "vstack",
          "properties": {
            "spacing": 20,
            "padding": 16
          },
          "children": [
            {
              "type": "text",
              "properties": {
                "content": "Hello, JUN!",
                "fontSize": 28,
                "fontWeight": "bold"
              }
            }
          ]
        }
        """) {
            ComponentRenderer(component: component)
        }
    }
}
```

## Usage

### Loading JSON

**From String:**
```swift
let component = try JSONLoader.loadFromString(jsonString)
```

**From URL:**
```swift
let url = URL(string: "https://api.example.com/ui/home")!
let component = try JSONLoader.loadFromURL(url)
```

**From Bundle:**
```swift
let component = try JSONLoader.loadFromBundle(filename: "layout")
```

### Rendering

```swift
struct MyView: View {
    let component: UIComponent

    var body: some View {
        ComponentRenderer(component: component)
    }
}
```

### Error Handling

```swift
do {
    let component = try JSONLoader.loadFromString(jsonString)
    ComponentRenderer(component: component)
} catch {
    Text("Failed to load UI: \(error.localizedDescription)")
}
```

## Implementation Details

### Component Mapping

JUN components map to SwiftUI views:

| JUN Type | SwiftUI View |
|----------|--------------|
| `vstack` | `VStack` |
| `hstack` | `HStack` |
| `zstack` | `ZStack` |
| `scrollView` | `ScrollView` |
| `text` | `Text` |
| `image` | `AsyncImage` |
| `button` | `Button` |
| `rectangle` | `Rectangle` |
| `circle` | `Circle` |
| `spacer` | `Spacer` |
| `divider` | `Divider` |

### Property Mapping

Universal properties apply SwiftUI modifiers:

| JUN Property | SwiftUI Modifier |
|--------------|------------------|
| `padding` | `.padding(_)` |
| `width`, `height` | `.frame(width:height:)` |
| `maxWidth`, `maxHeight` | `.frame(maxWidth:maxHeight:)` |
| `foregroundColor` | `.foregroundColor(_)` |
| `backgroundColor` | `.background(_)` |
| `cornerRadius` | `.cornerRadius(_)` |
| `clipped` | `.clipped()` |
| `aspectRatio` | `.aspectRatio(_:contentMode:)` |
| `contentMode` | ContentMode parameter |

### ScrollView Clipping

The `clipped` property has special behavior on ScrollView:
- `clipped: true` or omitted → Default clipping
- `clipped: false` → Applies `.scrollClipDisabled(true)`

### Image Loading

Images use SwiftUI's `AsyncImage`:
- **Loading state**: Shows `ProgressView()`
- **Success state**: Displays image with applied modifiers
- **Failure state**: Shows placeholder icon
- **Resizable**: Applies `.resizable()` when `resizable: true`

### Color Parsing

Supports:
- **Named colors**: Maps to SwiftUI `Color` constants
- **Hex colors**: Custom parser for `#RRGGBB` and `#RRGGBBAA` formats

## Project Structure

```
JUNSwiftUI/
├── Sources/
│   └── JUNSwiftUI/
│       ├── Models/
│       │   ├── UIComponent.swift          # Component model
│       │   ├── ComponentProperties.swift  # Property definitions
│       │   └── RootDocument.swift         # Data binding (future)
│       ├── Views/
│       │   ├── ComponentRenderer.swift    # Main renderer
│       │   └── JSONToSwiftUIViewModel.swift
│       └── Utilities/
│           └── JSONLoader.swift           # JSON loading
├── Tests/
│   └── JUNSwiftUITests/
├── Example/
│   └── JUNSwiftUIApp/                     # Example iOS app
└── Package.swift
```

## Running the Example App

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/JUNSwiftUI.git
   cd JUNSwiftUI
   ```

2. Open the example app:
   ```bash
   cd Example/JUNSwiftUIApp
   open JUNSwiftUIApp.xcodeproj
   ```

3. Build and run (⌘R)

The example app includes:
- Interactive sample browser
- Live rendering of JUN definitions
- JSON paste feature for testing
- Multiple example layouts

## API Reference

### JSONLoader

```swift
// Load component
static func loadFromURL(_ url: URL) throws -> UIComponent
static func loadFromString(_ jsonString: String) throws -> UIComponent
static func loadFromBundle(filename: String, bundle: Bundle = .main) throws -> UIComponent
static func loadFromData(_ data: Data) throws -> UIComponent
```

### ComponentRenderer

```swift
public struct ComponentRenderer: View {
    public init(component: UIComponent)
    public var body: some View
}
```

### Error Types

```swift
public enum JSONLoaderError: LocalizedError {
    case fileNotFound(String)
    case invalidString
    case decodingFailed(Error)
}
```

## Requirements

- iOS 17.0+ or macOS 14.0+
- Swift 5.9+
- Xcode 15.0+

## Specification

This implementation follows the [JUN v1.0 Specification](https://github.com/yourusername/JUN/blob/main/spec/jun-spec.md).

For complete format documentation, see the [JUN repository](https://github.com/yourusername/JUN).

## Known Limitations

- Button actions only print to console (no custom handlers yet)
- No navigation support (planned for v1.1)
- No data binding or template variables (planned for v1.1)
- No form input components (TextField, Picker, etc.)

## Contributing

Contributions welcome! Please ensure:
- Code follows Swift style guidelines
- Changes maintain JUN spec compliance
- Tests pass
- Example app works

## Related Projects

- **[JUN Specification](https://github.com/yourusername/JUN)** - Main specification repo
- **JUNReact** - React implementation (coming soon)
- **JUNAndroid** - Android/Compose implementation (coming soon)

## License

MIT License - See [LICENSE](LICENSE)

## Author

Pawel Zgoda-Ferchmin

---

Part of the **JUN** ecosystem - [JUN Specification](https://github.com/yourusername/JUN)
