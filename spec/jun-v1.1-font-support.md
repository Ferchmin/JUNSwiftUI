# JUN Specification v1.1 - Font Support

**Version:** 1.1
**Date:** 2025-12-03
**Status:** Draft

## Overview

This document describes the font support feature added to the JUN (JSON UI Notation) specification v1.1. The `font` property allows developers to specify custom font faces for text rendering across all JUN implementations.

## Universal Properties Extension

The following property is added to the Universal Properties set, making it available for all component types:

### font

**Type:** `String` (optional)
**Description:** Specifies a custom font family or typeface name for text rendering.
**Default:** Platform-specific system font
**Applies to:** All components (primarily affects text-rendering components)

## Property Definition

```typescript
interface UniversalProperties {
  // ... existing properties
  font?: string;
}
```

## Behavior

### Priority

When `font` is specified:
1. The `font` property takes precedence over default system fonts
2. Platform-specific font rendering applies the named font
3. If the font name is not available, implementations should gracefully fall back to system font
4. Font size and weight properties (where applicable) should be respected alongside the custom font

### Font Name Resolution

Implementations should support:
- **System fonts**: Platform-standard fonts (e.g., "Helvetica", "Arial", "Courier", "Georgia")
- **Custom fonts**: Application-bundled fonts referenced by PostScript name or family name
- **Platform fonts**: Platform-specific fonts (e.g., "San Francisco" on Apple platforms, "Roboto" on Android)

### Cross-Platform Considerations

Font availability varies by platform. Implementations should:
1. Accept any font name string without validation at parse time
2. Attempt to resolve the font at render time
3. Fall back gracefully to system font if resolution fails
4. Optionally log warnings for unavailable fonts in debug builds

## JSON Schema

```json
{
  "type": "object",
  "properties": {
    "font": {
      "type": "string",
      "description": "Custom font family or typeface name"
    }
  }
}
```

## Examples

### Basic Text with Custom Font

```json
{
  "type": "text",
  "properties": {
    "content": "Hello, World!",
    "fontSize": 24,
    "font": "Helvetica",
    "foregroundColor": "blue"
  }
}
```

### Button with Custom Font

```json
{
  "type": "button",
  "properties": {
    "label": "Click Me",
    "font": "Georgia",
    "backgroundColor": "blue",
    "foregroundColor": "white",
    "padding": 15,
    "cornerRadius": 8
  }
}
```

### Combining Font with FontWeight (SwiftUI)

```json
{
  "type": "text",
  "properties": {
    "content": "Bold Custom Font",
    "fontSize": 20,
    "fontWeight": "bold",
    "font": "Helvetica",
    "foregroundColor": "black"
  }
}
```

In this example, the SwiftUI implementation will:
1. Use "Helvetica" as the font family
2. Apply the specified fontSize (20)
3. Apply the bold weight

### Complex Layout with Multiple Fonts

```json
{
  "type": "vstack",
  "properties": {
    "spacing": 16,
    "padding": 20
  },
  "children": [
    {
      "type": "text",
      "properties": {
        "content": "Title",
        "fontSize": 32,
        "fontWeight": "bold",
        "font": "Georgia"
      }
    },
    {
      "type": "text",
      "properties": {
        "content": "Body text in Helvetica",
        "fontSize": 16,
        "font": "Helvetica"
      }
    },
    {
      "type": "text",
      "properties": {
        "content": "Code in monospace",
        "fontSize": 14,
        "font": "Courier"
      }
    }
  ]
}
```

## Implementation Notes

### SwiftUI (JUNSwiftUI)

The SwiftUI implementation uses `.font(.custom())` modifier:

```swift
if let fontName = properties.common.font {
    Text(content)
        .font(.custom(fontName, size: fontSize))
        .fontWeight(fontWeight)
} else {
    Text(content)
        .font(.system(size: fontSize, weight: fontWeight))
}
```

**Custom Fonts:** Must be registered in app's Info.plist under `UIAppFonts` (iOS) or included in the app bundle (macOS).

### React (Future Implementation)

React implementations should use CSS font-family:

```jsx
style={{ fontFamily: properties.font || 'system-ui' }}
```

### Android/Compose (Future Implementation)

Compose implementations should use FontFamily:

```kotlin
fontFamily = properties.font?.let {
    FontFamily(Font(it))
} ?: FontFamily.Default
```

## Validation

### Valid Font Names

Any non-empty string is valid for the `font` property. Implementations should not validate font availability at parse time.

### Error Handling

- **Missing font**: Fall back to system font, optionally log warning
- **Empty string**: Treat as if property was not specified
- **null/undefined**: Use system font (default behavior)

## Compatibility

### Backward Compatibility

The `font` property is optional. Existing JUN v1.0 documents remain fully compatible:
- Documents without `font` property render with system fonts
- No breaking changes to existing properties

### Forward Compatibility

JUN v1.0 parsers encountering the `font` property should:
- Ignore the property if not supported (graceful degradation)
- Continue rendering with default system font

## Platform Support Matrix

| Platform | Status | Notes |
|----------|--------|-------|
| SwiftUI (iOS 17+) | ✅ Implemented | Supports system and custom fonts |
| SwiftUI (macOS 14+) | ✅ Implemented | Supports system and custom fonts |
| React | 🔄 Planned | CSS font-family support |
| React Native | 🔄 Planned | Platform-specific font loading |
| Android/Compose | 🔄 Planned | FontFamily API |
| Flutter | 🔄 Planned | TextStyle fontFamily |

## Testing

Implementations should include tests for:

1. ✅ Font property decodes correctly from JSON
2. ✅ Font property applies to text components
3. ✅ Font property works with other components (buttons, etc.)
4. ✅ Font property is optional (graceful degradation)
5. ✅ Font combines correctly with fontSize and fontWeight
6. Font fallback when font is unavailable (integration test)
7. Empty string handling
8. Unicode font names (internationalization)

## Migration Guide

### From JUN v1.0 to v1.1

No changes required. Add `font` property where custom fonts are desired:

```diff
{
  "type": "text",
  "properties": {
    "content": "Hello",
    "fontSize": 20,
+   "font": "Helvetica"
  }
}
```

## References

- [JUN Core Specification](https://github.com/ferchmin/JUN)
- [JUNSwiftUI Implementation](https://github.com/yourusername/JUNSwiftUI)
- [SwiftUI Font Documentation](https://developer.apple.com/documentation/swiftui/font)
- [CSS font-family Property](https://developer.mozilla.org/en-US/docs/Web/CSS/font-family)

## Changelog

### v1.1 (2025-12-03)
- Added `font` property to Universal Properties
- Documented cross-platform behavior
- Added implementation examples for SwiftUI
- Added comprehensive test coverage

## Authors

- Pawel Zgoda-Ferchmin (@ferchmin)

## License

This specification is part of the JUN project and is available under the MIT License.
