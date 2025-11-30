# Quick Start Guide

## Prerequisites

- Xcode 15.0 or later
- macOS 14.0 or later (for development)
- iOS 17.0 or later (for deployment)
- Swift 5.9+

## Opening the Project

### Option 1: Open in Xcode (Recommended)

```bash
cd /Users/pawel/JSONToSwiftUIPOC
open Package.swift
```

Xcode will automatically resolve dependencies and prepare the project.

### Option 2: Command Line

```bash
cd /Users/pawel/JSONToSwiftUIPOC

# Build the project
swift build

# Run tests
swift test

# Run the app (macOS only via command line)
swift run JSONToSwiftUIApp
```

## Running the App

### On iOS Simulator

1. Open `Package.swift` in Xcode
2. Select `JSONToSwiftUIApp` scheme
3. Choose an iOS simulator (iPhone 15 or later recommended)
4. Press ⌘R to build and run

### On macOS

1. Open `Package.swift` in Xcode
2. Select `JSONToSwiftUIApp` scheme
3. Choose "My Mac" as the destination
4. Press ⌘R to build and run

## Exploring Sample Layouts

The app comes with three pre-built samples:

1. **Simple Layout** - Basic components: VStack, HStack, Text, Image, Button
2. **Complex Layout** - Product list with nested layouts, ZStack, ScrollView
3. **Horizontal Scroll** - Horizontal scrolling gallery with shapes

### Viewing a Sample

1. Launch the app
2. The first sample loads automatically
3. Tap "Back" to return to sample selection
4. Tap any sample to view it

### Loading Custom JSON

1. Tap the menu icon (⋯) in the top-right
2. Select "Paste JSON"
3. Paste your JSON definition
4. Tap "Render"

## Testing Custom JSON

### Example: Create a Simple Card

```json
{
  "type": "vstack",
  "properties": {
    "spacing": 12,
    "padding": 16,
    "backgroundColor": "#F0F0F0",
    "cornerRadius": 12
  },
  "children": [
    {
      "type": "text",
      "properties": {
        "content": "Hello, SwiftUI!",
        "fontSize": 24,
        "fontWeight": "bold"
      }
    },
    {
      "type": "text",
      "properties": {
        "content": "This card was generated from JSON",
        "fontSize": 14,
        "foregroundColor": "gray"
      }
    },
    {
      "type": "button",
      "properties": {
        "buttonLabel": "Tap Me",
        "backgroundColor": "blue",
        "foregroundColor": "white",
        "padding": 12,
        "cornerRadius": 8
      }
    }
  ]
}
```

1. Copy the JSON above
2. In the app, tap menu (⋯) → "Paste JSON"
3. Paste and tap "Render"

## Modifying Sample JSON

Sample JSON files are located in:
```
Resources/SampleJSON/
├── simple-layout.json
├── complex-layout.json
└── horizontal-scroll.json
```

Edit these files to experiment with different layouts:

```bash
# Open a sample in your editor
open Resources/SampleJSON/simple-layout.json

# Edit the JSON
# Save the file
# Rebuild and run the app to see changes
```

## Running Tests

### In Xcode

1. Press ⌘U to run all tests
2. View results in the Test Navigator (⌘6)

### Command Line

```bash
swift test
```

Expected output:
```
Test Suite 'All tests' passed
Test run with 3 tests in 1 suite passed
```

## Common JSON Patterns

### VStack with Multiple Children

```json
{
  "type": "vstack",
  "properties": {
    "spacing": 10,
    "alignment": "center"
  },
  "children": [
    { "type": "text", "properties": { "content": "Item 1" } },
    { "type": "text", "properties": { "content": "Item 2" } },
    { "type": "text", "properties": { "content": "Item 3" } }
  ]
}
```

### HStack with Images and Text

```json
{
  "type": "hstack",
  "properties": {
    "spacing": 12
  },
  "children": [
    {
      "type": "image",
      "properties": {
        "imageName": "star.fill",
        "foregroundColor": "yellow"
      }
    },
    {
      "type": "text",
      "properties": {
        "content": "Featured",
        "fontWeight": "semibold"
      }
    }
  ]
}
```

### ScrollView with Vertical Content

```json
{
  "type": "scrollView",
  "properties": {
    "scrollAxis": "vertical"
  },
  "children": [
    {
      "type": "vstack",
      "properties": {
        "spacing": 20
      },
      "children": [
        // Add many items here for scrolling
      ]
    }
  ]
}
```

## Troubleshooting

### Build Errors

**Error**: `'Observable()' is only available in macOS 14.0 or newer`
- **Solution**: Update your macOS to 14.0+ or change deployment target

**Error**: Module 'JSONToSwiftUIPOCLib' not found
- **Solution**: Clean build folder (⌘⇧K) and rebuild (⌘B)

### Runtime Issues

**JSON doesn't render**
- Check Xcode console for error messages
- Verify JSON syntax is valid (use a JSON validator)
- Ensure all required properties are present

**Colors not showing**
- Verify color names are correct (red, blue, green, etc.)
- For hex colors, include the `#` prefix: "#FF5733"

**Images not appearing**
- For SF Symbols, verify the symbol name is correct
- For remote images, check the URL is valid and accessible

## Next Steps

1. **Read the full README.md** for complete documentation
2. **Experiment with JSON** - Create your own layouts
3. **Add new components** - Extend ComponentRenderer.swift
4. **Integrate with LLM** - Use with Claude or GPT to generate UIs

## Getting Help

- Check `README.md` for full documentation
- Review sample JSON in `Resources/SampleJSON/`
- Examine `ComponentRenderer.swift` to see available properties
- Run tests to verify functionality: `swift test`
