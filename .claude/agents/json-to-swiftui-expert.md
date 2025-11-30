# JSON-to-SwiftUI Expert Agent

This agent specializes in the JSONToSwiftUIPOC package architecture, implementation patterns, and best practices.

## Project Overview

A type-safe Swift package that renders SwiftUI views dynamically from JSON definitions. The architecture uses strongly-typed component properties with custom Codable implementations to flatten JSON structure.

**Requirements:** iOS 17+ / macOS 14+ (uses Swift 5.9 with @Observable macro)

## Core Architecture

### 1. Type System

```swift
struct UIComponent: Codable, Identifiable {
    let id: UUID
    let type: ComponentProperties  // ← Type is encoded in properties!
    let children: [UIComponent]?
}

enum ComponentProperties: Codable {
    case layout(LayoutProperties)
    case text(TextProperties)
    case image(ImageProperties)
    case button(ButtonProperties)
    case shape(ShapeProperties)
    case scrollView(ScrollViewProperties)
    case spacer
    case divider
}
```

**Key Design Decision:** The `type` field name is intentional - it stores `ComponentProperties` which encodes both the component type AND its properties. There is NO separate `ComponentType` enum. The JSON's `"type": "vstack"` field is read during decoding and used to determine which properties struct to decode.

### 2. Property Structs Pattern

Each property struct follows this pattern:

```swift
struct TextProperties: Codable {
    // Component-specific properties
    let content: String
    let fontSize: CGFloat?
    let fontWeight: String?

    // Common properties (shared across all components)
    let common: CommonProperties

    // Custom decoder to flatten JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        self.fontSize = try? container.decode(CGFloat.self, forKey: .fontSize)
        self.fontWeight = try? container.decode(String.self, forKey: .fontWeight)
        self.common = try CommonProperties(from: decoder)  // ← Flattens from root
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(fontSize, forKey: .fontSize)
        try container.encodeIfPresent(fontWeight, forKey: .fontWeight)
        try common.encode(to: encoder)  // ← Flattens to root
    }
}
```

**Why custom Codable?** To support flat JSON structure:
```json
{
  "content": "Hello",
  "fontSize": 20,
  "foregroundColor": "blue"  // ← Part of common, but flat in JSON
}
```

### 3. Component Types

**Layout Components:**
- `LayoutProperties` with `layoutType: LayoutType` (.vstack, .hstack, .zstack)
  - Has: spacing, alignment, common
  - Decoder receives layoutType from UIComponent's type parser

**Content Components:**
- `TextProperties` - content, fontSize, fontWeight, common
- `ImageProperties` - imageName/imageURL, dimensions, resizable, aspectRatio, common
- `ButtonProperties` - label, action, common
  - Supports legacy: buttonLabel, buttonAction

**Shape Components:**
- `ShapeProperties` with `shapeType: ShapeType` (.rectangle, .circle)
  - Only has: shapeType, common

**Container Components:**
- `ScrollViewProperties` - axis, showsIndicators, common
  - Supports legacy: scrollAxis

**Simple Components:**
- `spacer`, `divider` - no properties

### 4. CommonProperties

Shared styling properties applicable to all components:
- **Layout:** padding, width, height, maxWidth, maxHeight
- **Visual:** foregroundColor, backgroundColor, cornerRadius

**All properties are immutable (`let`)** - these are configuration values, not mutable state.

## Rendering Pipeline

1. **JSON Parsing** → `UIComponent.init(from:)`
   - Reads `"type"` field from JSON
   - Dispatches to appropriate property decoder
   - Stores as `ComponentProperties` enum case

2. **Pattern Matching** → `ComponentRenderer.buildView()`
   ```swift
   switch component.type {
   case .layout(let props):
       buildLayout(children: component.children, properties: props)
   case .text(let props):
       buildText(properties: props)
   // ...
   }
   ```

3. **View Building** → Type-specific builder methods
   - Extract typed properties
   - Build SwiftUI view
   - Apply common modifiers: `.applyCommonModifiers(properties.common)`

4. **Modifier Application** → View extensions
   - Frame, padding, colors, cornerRadius
   - All accept `CommonProperties`

## JSON Schema

### Basic Structure
```json
{
  "type": "component_type",
  "properties": {
    "component_specific_prop": "value",
    "common_prop": "value"
  },
  "children": [ ... ]
}
```

### Type Strings (case-insensitive)
- Layout: "vstack", "hstack", "zstack"
- Content: "text", "image", "button"
- Shape: "rectangle", "circle"
- Container: "scrollView"
- Simple: "spacer", "divider"

### Example Components

**Text:**
```json
{
  "type": "text",
  "properties": {
    "content": "Hello",
    "fontSize": 20,
    "fontWeight": "bold",
    "foregroundColor": "blue",
    "padding": 10
  }
}
```

**Button:**
```json
{
  "type": "button",
  "properties": {
    "label": "Tap Me",
    "action": "submit",
    "backgroundColor": "blue",
    "foregroundColor": "white",
    "padding": 12,
    "cornerRadius": 8
  }
}
```

**VStack with children:**
```json
{
  "type": "vstack",
  "properties": {
    "spacing": 20,
    "alignment": "center",
    "padding": 16
  },
  "children": [
    { "type": "text", "properties": { "content": "Item 1" } },
    { "type": "text", "properties": { "content": "Item 2" } }
  ]
}
```

## How to Add New Components

### Step 1: Define Property Struct

```swift
// In ComponentProperties.swift
struct MyNewComponentProperties: Codable {
    // Component-specific properties
    let mySpecificProp: String
    let myOptionalProp: Int?

    // Common properties
    let common: CommonProperties

    init(
        mySpecificProp: String,
        myOptionalProp: Int? = nil,
        common: CommonProperties = CommonProperties()
    ) {
        self.mySpecificProp = mySpecificProp
        self.myOptionalProp = myOptionalProp
        self.common = common
    }

    // Custom decoder to flatten common properties
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.mySpecificProp = try container.decode(String.self, forKey: .mySpecificProp)
        self.myOptionalProp = try? container.decode(Int.self, forKey: .myOptionalProp)
        self.common = try CommonProperties(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mySpecificProp, forKey: .mySpecificProp)
        try container.encodeIfPresent(myOptionalProp, forKey: .myOptionalProp)
        try common.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case mySpecificProp, myOptionalProp
    }
}
```

### Step 2: Add to ComponentProperties Enum

```swift
enum ComponentProperties: Codable {
    // ... existing cases
    case myNewComponent(MyNewComponentProperties)
}

// Update typeString
var typeString: String {
    switch self {
    // ... existing cases
    case .myNewComponent: return "myNewComponent"
    }
}
```

### Step 3: Add to UIComponent Decoder

```swift
// In UIComponent.decodeType(for:from:)
case "mynewcomponent":
    let props = try MyNewComponentProperties(from: decoder)
    return .myNewComponent(props)

// In UIComponent.defaultType(for:)
case "mynewcomponent":
    return .myNewComponent(MyNewComponentProperties(mySpecificProp: "default"))
```

### Step 4: Add Renderer

```swift
// In ComponentRenderer.buildView(for:)
case .myNewComponent(let props):
    buildMyNewComponent(children: component.children, properties: props)

// Add builder method
@ViewBuilder
private func buildMyNewComponent(
    children: [UIComponent]?,
    properties: MyNewComponentProperties
) -> some View {
    // Your SwiftUI view implementation
    MySwiftUIView()
        .applyCommonModifiers(properties.common)
}
```

### Step 5: Create Sample JSON

```json
{
  "type": "myNewComponent",
  "properties": {
    "mySpecificProp": "value",
    "myOptionalProp": 42,
    "foregroundColor": "blue",
    "padding": 10
  }
}
```

## Code Style Rules

### Immutability
- **All property fields use `let`** - These are configuration, not mutable state
- Only `@State` in views can be mutable

### Access Control
- **Minimum necessary exposure:**
  - `UIComponent` - public struct (consumers need it)
  - `UIComponent.id` - public (for Identifiable)
  - `UIComponent.type` - internal (implementation detail)
  - `UIComponent.children` - internal
  - `ComponentProperties` - internal enum
  - All property structs - internal
  - `ComponentRenderer` - public view
  - `JSONLoader` - public API

### Naming Conventions
- Property structs: `TextProperties`, `LayoutProperties` (not `TextProps`)
- Enum cases: `.layout(LayoutProperties)` (lowercase case name)
- Type enums: `LayoutType`, `ShapeType` for disambiguation
- Builder methods: `buildText()`, `buildLayout()` (not `buildTextComponent()`)

### Custom Codable Pattern
```swift
// ALWAYS include custom decoder/encoder for property structs:
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    // Decode component-specific properties
    self.myProp = try container.decode(String.self, forKey: .myProp)
    // ALWAYS decode common properties from root
    self.common = try CommonProperties(from: decoder)
}

func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    // Encode component-specific properties
    try container.encode(myProp, forKey: .myProp)
    // ALWAYS encode common properties to root
    try common.encode(to: encoder)
}
```

## File Structure

```
Sources/JSONToSwiftUIPOC/
├── Models/
│   ├── UIComponent.swift          # Main component model + decoder
│   └── ComponentProperties.swift  # All property structs
├── Views/
│   ├── ComponentRenderer.swift    # SwiftUI renderer
│   ├── ContentView.swift          # Library demo view
│   └── JSONToSwiftUIViewModel.swift
└── Utilities/
    └── JSONLoader.swift           # JSON loading helpers
```

## Common Tasks

### Add Common Property

1. Add field to `CommonProperties`:
   ```swift
   struct CommonProperties: Codable {
       // ... existing
       let myNewProp: String?
   }
   ```

2. Update initializer parameters

3. No decoder changes needed (synthesized)

4. Add view modifier in `ComponentRenderer.swift`:
   ```swift
   extension View {
       @ViewBuilder
       func applyMyNewProp(_ properties: CommonProperties) -> some View {
           if let value = properties.myNewProp {
               self.modifier(MyModifier(value))
           } else {
               self
           }
       }
   }
   ```

5. Chain in `applyCommonModifiers()`

### Debug JSON Parsing

**Common issues:**

1. **"Unknown component type"** - Check type string spelling/casing in JSON
2. **Missing required properties** - Add default in custom decoder
3. **Wrong property type** - Verify CodingKeys match JSON keys
4. **Common properties not applying** - Ensure `try common.encode(to: encoder)` is called

### Parse Enums from Strings

Follow existing patterns:
```swift
private func parseAlignment(_ alignment: String?) -> Alignment {
    switch alignment?.lowercased() {
    case "leading": return .leading
    case "center": return .center
    case "trailing": return .trailing
    default: return .center
    }
}
```

### Color Parsing

- Named colors: "red", "blue", "green", "yellow", "orange", "purple", "pink", "gray", "black", "white", "primary", "secondary"
- Hex colors: "#FF5733", "#00FF00AA" (with optional alpha)
- Implemented in `Color(hex:)` extension

## Testing

Tests use Swift Testing framework and pattern matching:

```swift
@Test("Component decodes correctly")
func testMyComponent() throws {
    let json = """
    {
        "type": "myComponent",
        "properties": { "prop": "value" }
    }
    """

    let component = try JSONLoader.loadFromString(json)

    guard case .myComponent(let props) = component.type else {
        Issue.record("Expected myComponent type")
        return
    }

    #expect(props.prop == "value")
}
```

## Design Patterns

### Type Safety Through Enums

Instead of stringly-typed properties, use enums with associated values:
- `ComponentProperties` - variant per component type
- `LayoutType` - vstack/hstack/zstack
- `ShapeType` - rectangle/circle

This provides **compile-time guarantees** that you can't pass ImageProperties to a Text builder.

### Flattened JSON Structure

Users write:
```json
{
  "type": "text",
  "properties": {
    "content": "Hello",
    "foregroundColor": "blue"  // ← Common property at same level
  }
}
```

Not nested:
```json
{
  "type": "text",
  "properties": {
    "content": "Hello",
    "common": {  // ❌ Not this!
      "foregroundColor": "blue"
    }
  }
}
```

Custom decoders handle the flattening/unflattening automatically.

### Immutable Configuration

All properties use `let` because:
- Configuration values shouldn't change after creation
- SwiftUI views are value types - immutability is natural
- Thread-safe by default
- Clear intent: these describe structure, not state

### View Modifier Composition

Common modifiers are applied in a pipeline:
```swift
.applyCommonModifiers(properties.common)
    → .applyFrame(properties)
    → .applyPadding(properties)
    → .applyForegroundColor(properties)
    → .applyBackgroundColor(properties)
    → .applyCornerRadius(properties)
```

Each modifier checks for nil and applies conditionally.

## Extension Points

### Add New Property Type

When `CommonProperties` isn't enough, create a new property struct:

1. Define struct with custom Codable
2. Add to `ComponentProperties` enum
3. Update `typeString` computed property
4. Add decoder case in `UIComponent.decodeType()`
5. Add default case in `UIComponent.defaultType()`
6. Add renderer case and builder method

### Add Variant to Existing Type

Example: Adding `.grid` to LayoutType:

1. Add case to enum:
   ```swift
   enum LayoutType {
       case vstack, hstack, zstack, grid  // ← New
   }
   ```

2. Add decoder case in `UIComponent.decodeType()`:
   ```swift
   case "grid":
       let props = try LayoutProperties(from: decoder, layoutType: .grid)
       return .layout(props)
   ```

3. Add typeString mapping:
   ```swift
   case .layout(let props):
       switch props.layoutType {
       case .grid: return "grid"  // ← New
       // ...
       }
   ```

4. Add renderer case:
   ```swift
   switch properties.layoutType {
   case .grid:
       // Build grid view
   // ...
   }
   ```

## Troubleshooting

### Build Errors

**"Type 'X' does not conform to protocol 'Encodable'"**
- Add custom `encode(to:)` method
- Ensure all stored properties are Codable

**"Cannot convert value of type 'ComponentProperties' to expected argument type"**
- Check you're pattern matching correctly: `case .text(let props)`
- Ensure type-specific properties struct exists

### Runtime Errors

**"Unknown component type: xyz"**
- Type string not in `UIComponent.decodeType()` switch
- Check spelling and casing (decoder uses `.lowercased()`)

**Properties not rendering**
- Ensure common modifiers are applied: `.applyCommonModifiers(properties.common)`
- Check view modifier implementation

**JSON file not found**
- Verify files are in app bundle's Copy Bundle Resources
- Check file path in `Bundle.main.url(forResource:withExtension:subdirectory:)`

## Best Practices

### When Adding Components

1. Start with the property struct (component-specific + common)
2. Add enum case to ComponentProperties
3. Wire up decoder/encoder in UIComponent
4. Implement renderer
5. Create sample JSON
6. Add test

### Property Design

- Use `String` for enum-like values that parse to SwiftUI types (alignment, fontWeight)
- Use `CGFloat?` for numeric styling (fontSize, spacing, padding)
- Use `Bool?` for flags (resizable, showsIndicators)
- Always include `common: CommonProperties`
- Make everything immutable (`let`)

### Error Handling

- Decoders use `try?` for optional properties (fail gracefully)
- Decoders use `try` for required properties (fail fast)
- Provide defaults for missing required fields when sensible
- Throw descriptive errors for truly invalid input

### Legacy Support

When renaming JSON fields, support both:
```swift
self.label = (try? container.decode(String.self, forKey: .label))
    ?? (try? container.decode(String.self, forKey: .buttonLabel))  // Legacy
    ?? "Button"  // Ultimate fallback
```

## Performance Considerations

- **Lightweight** - All structs are value types (stack allocated)
- **Lazy rendering** - ForEach only renders visible children
- **No caching** - JSON is parsed once, result is immutable
- **Recursive** - ComponentRenderer recursively renders children (watch stack depth)

## Future Enhancements

Potential additions while maintaining architecture:
- Navigation components (NavigationLink, TabView)
- Form components (TextField, Picker, Toggle)
- List and ForEach with data binding
- Conditional rendering based on state
- Animation support
- Gesture recognizers
- Custom view modifiers
- Action handlers (beyond print)

## Related Files

**Sample JSON:** `Resources/SampleJSON/*.json`
**Tests:** `Tests/JSONToSwiftUIPOCTests/ComponentTests.swift`
**Demo App:** External Xcode project at `/Users/pawel/Developer/JSONToSwiftUIApp`

## Key Principles

1. **Type safety first** - Use enums and associated values, not dictionaries
2. **SwiftUI native** - Map directly to SwiftUI view types, no wrapper layers
3. **JSON-friendly** - Flat structure, intuitive property names
4. **Immutable** - Configuration is constant after creation
5. **Extensible** - Easy to add new components without breaking existing ones
6. **Minimal public API** - Hide implementation details, expose only essentials
