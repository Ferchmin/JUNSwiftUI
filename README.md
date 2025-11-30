# JSONToSwiftUI

A Swift Package for rendering SwiftUI views dynamically from JSON definitions. This demonstrates a generative UI approach similar to Flutter's GenUI SDK.

**Requirements**: iOS 17+ / macOS 14+ (uses Swift 5.9 with Observable macro)

## Overview

This POC allows you to define user interfaces in JSON format and render them as native SwiftUI views at runtime. It's useful for:

- **Server-driven UI**: Update UI layouts without app updates
- **A/B Testing**: Test different layouts dynamically
- **LLM-Generated UI**: Let AI models design interfaces using structured output
- **Rapid Prototyping**: Design UIs in JSON for quick iteration

## Features

### Supported Components

- **Layout Components**:
  - `vstack` - Vertical stack with spacing and alignment
  - `hstack` - Horizontal stack with spacing and alignment
  - `zstack` - Depth stack with alignment
  - `scrollView` - Scrollable container (vertical or horizontal)

- **Content Components**:
  - `text` - Text with font size, weight, and color
  - `image` - SF Symbols or async images from URLs
  - `button` - Interactive button with actions

- **Shape Components**:
  - `rectangle` - Rectangular shape
  - `circle` - Circular shape
  - `divider` - Horizontal/vertical divider
  - `spacer` - Flexible space

### Supported Properties

#### Layout Properties
- `spacing` - Space between children (CGFloat)
- `alignment` - Alignment of children (leading, center, trailing, top, bottom)
- `padding` - Internal padding (CGFloat)

#### Text Properties
- `content` - Text content (String)
- `fontSize` - Font size (CGFloat)
- `fontWeight` - Font weight (thin, light, regular, medium, semibold, bold, heavy, black)
- `foregroundColor` - Text/icon color

#### Image Properties
- `imageName` - SF Symbol name (String)
- `imageURL` - Remote image URL (String)
- `imageWidth`, `imageHeight` - Image dimensions (CGFloat)
- `resizable` - Whether image is resizable (Bool)
- `aspectRatio` - Aspect ratio mode (fit, fill)

#### Frame Properties
- `width`, `height` - Fixed dimensions (CGFloat)
- `maxWidth`, `maxHeight` - Maximum dimensions (CGFloat)

#### Visual Properties
- `backgroundColor` - Background color
- `cornerRadius` - Corner radius (CGFloat)

#### ScrollView Properties
- `scrollAxis` - Scroll direction (vertical, horizontal)
- `showsIndicators` - Show scroll indicators (Bool)

### Color Support

Colors can be specified as:
- **Named colors**: "red", "blue", "green", "yellow", "orange", "purple", "pink", "gray", "black", "white", "primary", "secondary"
- **Hex colors**: "#FF5733", "#00FF00AA" (with optional alpha)

## JSON Schema

### Basic Structure

```json
{
  "type": "component_type",
  "properties": {
    "property1": "value1",
    "property2": 123
  },
  "children": [
    { ... nested components ... }
  ]
}
```

### Example: Simple Layout

```json
{
  "type": "vstack",
  "properties": {
    "spacing": 20,
    "alignment": "center",
    "padding": 16
  },
  "children": [
    {
      "type": "text",
      "properties": {
        "content": "Hello, World!",
        "fontSize": 28,
        "fontWeight": "bold",
        "foregroundColor": "blue"
      }
    },
    {
      "type": "button",
      "properties": {
        "buttonLabel": "Get Started",
        "backgroundColor": "blue",
        "foregroundColor": "white",
        "padding": 15,
        "cornerRadius": 10
      }
    }
  ]
}
```

### Example: Complex Layout with Images

```json
{
  "type": "hstack",
  "properties": {
    "spacing": 12,
    "padding": 12,
    "backgroundColor": "#F5F5F5",
    "cornerRadius": 12
  },
  "children": [
    {
      "type": "image",
      "properties": {
        "imageName": "star.fill",
        "foregroundColor": "yellow",
        "imageWidth": 40,
        "imageHeight": 40
      }
    },
    {
      "type": "vstack",
      "properties": {
        "spacing": 4,
        "alignment": "leading"
      },
      "children": [
        {
          "type": "text",
          "properties": {
            "content": "Featured Item",
            "fontSize": 18,
            "fontWeight": "semibold"
          }
        },
        {
          "type": "text",
          "properties": {
            "content": "Special offer",
            "fontSize": 14,
            "foregroundColor": "gray"
          }
        }
      ]
    }
  ]
}
```

### Example: Horizontal ScrollView

```json
{
  "type": "scrollView",
  "properties": {
    "scrollAxis": "horizontal",
    "showsIndicators": false
  },
  "children": [
    {
      "type": "hstack",
      "properties": {
        "spacing": 12
      },
      "children": [
        {
          "type": "rectangle",
          "properties": {
            "width": 150,
            "height": 200,
            "backgroundColor": "red",
            "cornerRadius": 12
          }
        },
        {
          "type": "rectangle",
          "properties": {
            "width": 150,
            "height": 200,
            "backgroundColor": "blue",
            "cornerRadius": 12
          }
        }
      ]
    }
  ]
}
```

## Project Structure

```
JSONToSwiftUI/
├── Sources/
│   └── JSONToSwiftUI/              # Swift Package source code
│       ├── Models/
│       │   ├── UIComponent.swift          # Component model
│       │   └── ComponentProperties.swift  # Component properties
│       ├── Views/
│       │   ├── ComponentRenderer.swift    # SwiftUI renderer
│       │   └── JSONToSwiftUIViewModel.swift
│       └── Utilities/
│           └── JSONLoader.swift           # JSON loading utilities
├── Tests/
│   └── JSONToSwiftUITests/         # Unit tests
├── Example/
│   └── JSONToSwiftUIApp/           # Example iOS app
│       ├── JSONToSwiftUIApp.xcodeproj
│       └── JSONToSwiftUIApp/
│           ├── ContentView.swift          # Example app UI
│           ├── JSONToSwiftUIAppApp.swift
│           └── Resources/
│               └── SampleJSON/            # Sample JSON files
│                   ├── simple-layout.json
│                   ├── complex-layout.json
│                   └── horizontal-scroll.json
├── Package.swift
├── README.md
└── .gitignore
```

## Installation

### Swift Package Manager

Add this package to your project:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/JSONToSwiftUI.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select the version

## Running the Example App

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/JSONToSwiftUI.git
   cd JSONToSwiftUI
   ```

2. Open the example app:
   ```bash
   cd Example/JSONToSwiftUIApp
   open JSONToSwiftUIApp.xcodeproj
   ```

3. Select a simulator or device from the target menu
4. Press ⌘R to build and run

The example app includes sample JSON layouts demonstrating the library's capabilities.

## Usage

### In the App

1. **Browse Samples**: The app loads with sample JSON layouts
2. **Select a Sample**: Tap a sample to render it
3. **Paste Custom JSON**: Tap the menu (•••) and select "Paste JSON" to render your own
4. **Clear**: Return to sample selection

### Programmatic Usage

```swift
import JSONToSwiftUI

// Load from JSON string
let component = try JSONLoader.loadFromString(jsonString)

// Load from file
let component = try JSONLoader.loadFromURL(fileURL)

// Render in SwiftUI
struct MyView: View {
    let component: UIComponent

    var body: some View {
        ComponentRenderer(component: component)
    }
}
```

## Architecture

### Component Model (`UIComponent`)

Codable struct representing a UI component with:
- `type`: Component type (enum)
- `properties`: Dictionary of component properties
- `children`: Optional array of child components (recursive)

### Renderer (`ComponentRenderer`)

SwiftUI view that:
1. Recursively traverses the component tree
2. Builds native SwiftUI views based on component types
3. Applies properties as view modifiers

### View Modifiers

Extension on `View` that applies common modifiers:
- Frame (width, height, maxWidth, maxHeight)
- Padding
- Colors (foreground, background)
- Corner radius
- Image-specific modifiers

## Extending the POC

### Adding New Component Types

1. Add case to `ComponentType` enum in `UIComponent.swift`:
   ```swift
   enum ComponentType: String, Codable {
       // ... existing cases
       case customComponent
   }
   ```

2. Add properties to `ComponentProperties` struct if needed

3. Implement renderer in `ComponentRenderer.swift`:
   ```swift
   case .customComponent:
       buildCustomComponent(component)
   ```

4. Create builder method:
   ```swift
   @ViewBuilder
   private func buildCustomComponent(_ component: UIComponent) -> some View {
       // Your SwiftUI view implementation
   }
   ```

### Adding New Properties

1. Add property to `ComponentProperties`:
   ```swift
   var myNewProperty: String?
   ```

2. Use in renderer or create new modifier

## LLM Integration Example

This POC is designed to work with LLM-generated JSON. Here's how to use it with an LLM:

### Prompt Template

```
Generate a JSON representation of a UI layout for [description].

Use the following component types:
- vstack, hstack, zstack (spacing, alignment, padding)
- scrollView (scrollAxis: "horizontal" or "vertical")
- text (content, fontSize, fontWeight, foregroundColor)
- image (imageName for SF Symbols, imageURL for remote images)
- button (buttonLabel, backgroundColor, foregroundColor)
- rectangle, circle (width, height, backgroundColor, cornerRadius)
- spacer, divider

Output only valid JSON matching this schema:
{
  "type": "component_type",
  "properties": { ... },
  "children": [ ... ]
}
```

### Using with Apple's FoundationModels

```swift
import FoundationModels

@Generable
struct GeneratedUI {
    var component: UIComponent
}

let model = LanguageModel.anthropic.claude
let result = try await model.generate(
    prompt: "Create a login form with username and password fields",
    guidedBy: GeneratedUI.self
)

// Render the generated component
ComponentRenderer(component: result.component)
```

## Comparison to Flutter GenUI

| Feature | Flutter GenUI | This POC |
|---------|---------------|----------|
| **Component Catalog** | Dart widget schemas | Swift Codable types |
| **Schema Definition** | json_schema_builder | Swift type system |
| **Data Binding** | Path-based reactive binding | SwiftUI @State/@Binding |
| **Rendering** | Flutter widget tree | SwiftUI view hierarchy |
| **LLM Integration** | Firebase AI / Gemini | Compatible with any LLM |

## Sample JSON Files

Three sample JSON files are included:

1. **simple-layout.json** - Basic components showcase
2. **complex-layout.json** - Product list with nested layouts
3. **horizontal-scroll.json** - Horizontal scrolling gallery

## Limitations

This is a proof-of-concept with the following limitations:

- ⚠️ No runtime validation of JSON schema
- ⚠️ Button actions are print statements only
- ⚠️ No support for animations or gestures
- ⚠️ Limited error handling for malformed JSON
- ⚠️ No state management between renders
- ⚠️ AsyncImage requires internet for remote URLs

## Future Enhancements

Potential improvements:

- [ ] Add more SwiftUI components (List, Form, Picker, etc.)
- [ ] Support for navigation and routing
- [ ] State management and data binding
- [ ] Action handlers with callback system
- [ ] Animation support
- [ ] Gesture recognizers
- [ ] Custom component registration
- [ ] JSON schema validation
- [ ] Real-time JSON editing with live preview
- [ ] Export SwiftUI code from JSON

## Related Technologies

- **Flutter GenUI**: https://pub.dev/packages/genui
- **Apple FoundationModels**: Swift framework for LLM structured output
- **LLM.swift**: https://github.com/eastriverlee/LLM.swift
- **Vercel AI SDK**: https://ai-sdk.dev/docs/ai-sdk-ui/generative-user-interfaces

## License

This is a proof-of-concept for demonstration purposes.

## Author

Created as a POC for exploring generative UI patterns in SwiftUI.
