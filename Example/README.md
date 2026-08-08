# JUNSwiftUI Example App

Demonstrates JUNSwiftUI rendering JUN documents.

## Running

```bash
open Example/JUNSwiftUIApp.xcodeproj
```

Select the `JUNSwiftUIApp` scheme and press ⌘R. The project references the package by relative
path, so it builds against your working copy with no extra setup.

## What it shows

- **Sample browser** — the canonical JUN examples, rendered
- **Paste JSON** — render your own document from the toolbar
- **Diagnostics banner** — what parsing found wrong, and where
- **Action handling** — the counter example's actions, interpreted by the app

## Samples

These come from the [JUN repository](https://github.com/ferchmin/JUN) and are synced by
`Scripts/sync-examples.sh` into `JUNSwiftUIApp/Resources/Examples/`. Edit them upstream, not
here — CI fails if the copies drift.

| Sample | Demonstrates |
|--------|--------------|
| Simple Layout | VStack, HStack, Text, shapes, a button |
| Product List | Nested cards inside a scroll view |
| Horizontal Scroll | Horizontal gallery with remote images |
| Remote Images | AsyncImage sizing, clipping and loading states |
| Font Showcase | The `font` property across several typefaces |
| Counter | Actions with parameters, handled by this app |

## Actions

The counter example is the one that does something. Its buttons name an intent —
`adjustCount` with a `by` parameter, and `resetCount` — and `DocumentDetailView` decides what
those mean:

```swift
ComponentRenderer(document: document)
    .junActionHandler { action in
        switch action.name {
        case "adjustCount": count += action.params["by"]?.intValue ?? 0
        case "resetCount":  count = 0
        default: break
        }
    }
```

Remove the handler and the buttons do nothing at all. That is the design: a document names an
intent, the app decides whether it means anything.

The banner along the bottom reports the last action received, so you can see the parameters
arriving.

## Diagnostics

Paste something malformed — a `fontSize` in quotes, an image with no source, a component type
that does not exist — and the banner above the render shows what was found and where. The
document still renders whatever it could parse.

## Troubleshooting

**Images do not load.** The remote samples use `picsum.photos` and need network access.
Offline, they render the failure placeholder, which is the intended behaviour rather than a
bug.

**Fonts look wrong.** System faces (Helvetica, Courier, Georgia) resolve out of the box.
Application-bundled fonts must be registered under `UIAppFonts` in `Info.plist`, and names are
case-sensitive.

**A sample is missing from the list.** Run `./Scripts/sync-examples.sh` from the repository
root.

## Requirements

iOS 17.0+, Xcode 15.0+
