# Changelog

All notable changes to JUNSwiftUI are documented here.

## [1.2.0] — 2026-08-08

Implements [JUN v1.2](https://github.com/ferchmin/JUN/blob/main/spec/jun-spec.md), and is the
first tagged release. Several breaking changes land together here deliberately: with no
released version to be compatible with, they cost nothing now and would have cost a major
version a week later.

### Fixed

- **Shapes rendered solid black.** `rectangle` and `circle` routed `backgroundColor` through
  `.background()`, but a SwiftUI shape fills itself with the foreground style, so the fill
  covered the color that was meant to be it. Every shape in every shipped sample was affected,
  as were the specification's own examples. Shapes now fill with `foregroundColor`, falling
  back to `backgroundColor`.
- **`imageName` was used by three shipped samples and never implemented.** `buildImage`
  returned an empty view when `imageURL` was absent, so those images silently vanished. Local
  and system images are now supported, and an image that cannot resolve a source renders the
  failure placeholder instead of nothing.
- **A malformed child silently emptied its whole container.** `children` decoded through a
  single `try?`, so one bad grandchild anywhere in a subtree discarded every sibling. Children
  now decode independently.
- **`padding` was applied outside `width` and `height`**, so `width: 100, padding: 16` occupied
  132 points. Padding is now internal, as the specification says.
- **`width`/`height` and `maxWidth`/`maxHeight` were mutually exclusive**, because the frame
  modifiers were a single `if`/`else if` chain. They now compose.
- **Unknown component types behaved differently depending on document shape** — throwing when a
  `properties` object was present and degrading when it was absent. They now degrade
  consistently.
- **`font` on a non-text component forced 16pt.** It now anchors to the body text style and
  scales with Dynamic Type.
- **The example app's Horizontal Scroll sample contained a trailing comma** and failed to
  parse at runtime.
- **The example app's package reference** only resolved when the clone directory happened to be
  named `JUNSwiftUI`.

### Added

- **Diagnostics.** Every loader returns a `JUNDocument` carrying the tree and the problems
  found producing it, each with a document path such as `children[3].properties.imageURL`.
  Logged to `OSLog` in debug builds; available to the host in release, so a server can learn
  from the field that its documents are broken.
- **`JUNParseOptions`** for unknown-component and invalid-value policies, plus `maxDepth` (64)
  and `maxNodes` (10,000). `JUNParseOptions.strict` turns any malformed input into a thrown
  error, for tests and build pipelines.
- **Bounded parsing.** Documents from untrusted sources can no longer overflow the stack; the
  limits reject rather than degrade, since they are protection rather than preference.
- **Actions.** `JUNAction` with a name and scalar `params`, dispatched through
  `.junActionHandler { }`. Both the object form and the string shorthand are accepted, and
  reserved dotted names are forwarded to the host unchanged.
- **Image sources.** `imageName` for bundled assets and `systemImage` for SF Symbols, alongside
  `imageURL`.
- **`JSONLoader.load(from:session:options:)`**, an `async` loader with proper HTTP status
  handling.
- **CI**: build and test, example-app build, schema validation of every example against
  upstream JUN, an upstream drift check, and SwiftLint.
- **Tests** covering rendering behaviours, diagnostics, sibling isolation, resource limits,
  round-tripping, the removed aliases, and strict parsing of every canonical example.

### Changed

- **`JSONLoader` returns `JUNDocument` rather than `UIComponent`.** Use `document.root` to
  render, `document.diagnostics` to see what went wrong.
- **`loadFromURL` is now `loadFromFile`, and rejects non-file URLs.** It was
  `Data(contentsOf:)` — a synchronous network call with no timeout or cancellation, on
  whatever thread the caller was on — while the README demonstrated it against an HTTPS
  endpoint. Remote documents go through the `async` loader.
- **Examples come from the JUN repository**, synced by `Scripts/sync-examples.sh` and checked
  for drift in CI. The two divergent copies previously kept in this repository are gone.
- `UIComponent` equality ignores the generated `id`, so two decodes of the same document
  compare equal.
- `.cornerRadius` and `.foregroundColor` replaced with `.clipShape` and `.foregroundStyle`,
  both deprecated as of this package's own minimum deployment target.
- Universal properties are applied by a single `ViewModifier` rather than ten extensions on
  `View`.

### Removed

- **The undocumented legacy dialect**: `buttonLabel`, `buttonAction` and `scrollAxis`. These
  were accepted by the decoder but appeared in neither the specification nor the schema, while
  the shipped samples were written in them — so this repository's canonical examples were in a
  dialect no other implementation could read. Use `label`, `action` and `axis`.
- **`ContentView` and `JSONToSwiftUIViewModel`**, demo scaffolding that shipped inside the
  library product, including a hardcoded path to the original author's machine. The example app
  covers what they did.

### Known divergence

Children on `button` are still rendered as its label, which JUN v1.2 forbids. The behaviour is
preserved and the parser now warns about it; whether to change the specification or drop the
capability is undecided.
