# JUNSwiftUI Example App

This example app demonstrates the JUNSwiftUI library rendering JSON UI definitions.

## Running the App

### Option 1: Open in Xcode (Recommended)

```bash
cd /Users/pawel/Developer/JUNSwiftUI/Example
open JUNSwiftUIApp.xcodeproj
```

Then press ⌘R to build and run.

### Option 2: From Package Root

```bash
cd /Users/pawel/Developer/JUNSwiftUI
open Example/JUNSwiftUIApp.xcodeproj
```

## Available Sample Layouts

The app includes several pre-configured sample layouts:

### 1. Simple Layout
- **Description**: Basic VStack, HStack, Text, Image, Button
- **Demonstrates**: Fundamental JUN components and layout

### 2. Complex Layout
- **Description**: Product list with nested layouts and ScrollView
- **Demonstrates**: Advanced nesting, cards, shapes

### 3. Horizontal Scroll
- **Description**: Horizontal ScrollView with remote images from URLs
- **Demonstrates**: Scrolling behavior, image loading

### 4. Remote Images ✨
- **Description**: AsyncImage loading from URLs with different layouts
- **Demonstrates**:
  - Remote image loading from picsum.photos
  - Various image sizes and aspect ratios
  - Circular images with cornerRadius
  - Image gallery layouts
  - Loading states with ProgressView

### 5. Font Showcase ✨ NEW
- **Description**: Custom font examples with Helvetica, Courier, and Georgia
- **Demonstrates**:
  - Custom font support with `font` property
  - System fonts (Helvetica, Courier, Georgia, HelveticaNeue)
  - Font combinations with fontSize and fontWeight
  - Multiple fonts in a single layout

## Testing Custom Fonts

The **Font Showcase** example demonstrates custom fonts:

```json
{
  "type": "text",
  "properties": {
    "content": "Helvetica Font",
    "fontSize": 20,
    "font": "Helvetica",
    "foregroundColor": "#FF6B6B"
  }
}
```

**Available system fonts:**
- `Helvetica`
- `Courier` (monospace)
- `Georgia` (serif)
- `HelveticaNeue`
- And more system fonts available on iOS/macOS

## Testing Remote Images

The **Remote Images** example demonstrates AsyncImage:

```json
{
  "type": "image",
  "properties": {
    "imageURL": "https://picsum.photos/400/250",
    "resizable": true,
    "contentMode": "fit",
    "cornerRadius": 8,
    "maxWidth": 400
  }
}
```

**Features:**
- Asynchronous loading with ProgressView while loading
- Fallback icon on error
- Various aspect ratios and content modes
- Rounded corners and clipping

## Custom JSON Input

Use the "Paste JSON" button (document icon in toolbar) to test your own JSON definitions:

1. Tap the document icon in the top-right
2. Paste your JUN JSON
3. Tap "Render" to see the result

## Troubleshooting

### Images not loading
- Ensure you have an active internet connection
- picsum.photos may occasionally be slow - wait for the loading indicator
- Try different image URLs if needed

### Fonts not displaying correctly
- System fonts (Helvetica, Courier, Georgia) should work out of the box
- Custom app fonts require registration in Info.plist
- Check font name spelling (case-sensitive)

### App not building
- Make sure you're using Xcode 15.0 or later
- Clean build folder: Product → Clean Build Folder (⇧⌘K)
- Close and reopen Xcode if needed

## Requirements

- iOS 17.0+ or macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## Features Demonstrated

- ✅ All JUN v1.0 component types
- ✅ Universal properties (padding, colors, sizing, etc.)
- ✅ AsyncImage with remote URLs
- ✅ Custom fonts (NEW in v1.1)
- ✅ Nested layouts
- ✅ ScrollViews (vertical and horizontal)
- ✅ Shapes with styling
- ✅ Interactive buttons
- ✅ Dynamic JSON loading

## Sample JSON Files

All sample JSON files are located in:
```
Example/JUNSwiftUIApp/Resources/SampleJSON/
```

You can edit these files directly to experiment with different layouts.
