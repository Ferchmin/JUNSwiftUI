# JUNSwiftUI + JUN — Analysis and Improvement Plan

**Date:** 2026-08-08
**Scope reviewed:** `ferchmin/JUNSwiftUI` @ `c1e4164`, `ferchmin/JUN` @ `dba5ab3`
**Method:** full source read of both repos, JSON Schema validation of every example
document in both repos, manual trace of the SwiftUI render path. No Swift toolchain was
available in the review environment, so nothing was compiled — findings below are from
static reading plus schema/JSON validation that *was* run.

---

## 1. Where the project stands

JUN is a small, coherent idea with a clean shape: a recursive `{type, properties, children}`
document, eleven component types, a universal property set, and one reference
implementation. The Swift code is tidy and idiomatic — a `ComponentProperties` enum with
per-type property structs, flattened decoding so JSON stays ergonomic, `@ViewBuilder`
dispatch, zero dependencies. The architecture is the right one and does not need rework.

What is missing is everything *around* the idea. The package cannot currently be installed
via its documented instructions, three of five shipped samples render incorrectly or not at
all, the published JSON Schema rejects the feature v1.1 was released for, and there is no CI
to have caught any of it. The gap is not design — it is release engineering, conformance,
and the feedback loop between spec and implementation.

The rest of this document is the findings, then a phased plan.

---

## 2. Findings

Severity: **P0** blocks a user, **P1** produces wrong output or blocks contributors,
**P2** is hygiene/process, **P3** is roadmap.

### 2.1 P0 — Blockers

**P0-1 · Neither repo has a git tag, so the documented install does not work.**
`README.md` tells users:

```swift
.package(url: "https://github.com/ferchmin/JUNSwiftUI.git", from: "1.0.0")
```

`git ls-remote --tags` returns nothing for either repo. SPM cannot resolve `from: "1.0.0"`
against a repo with no version tags, so the primary install path fails for every user. The
READMEs also advertise v1.0.0 and v1.1.0 as released.
*Fix:* tag `1.0.0` and `1.1.0` retroactively (or just tag `1.1.0` and correct the README),
push tags, cut GitHub Releases.

**P0-2 · The example app's Horizontal Scroll sample is invalid JSON.**
`Example/JUNSwiftUIApp/Resources/SampleJSON/horizontal-scroll.json:31` has a trailing comma
after `"clipped": false`. `jq` rejects it; `JSONDecoder` will too. The sample is listed in
the app's menu and fails at runtime with a decode error. The copy under `/Resources` does
not have this comma — the two copies have drifted (see P2-2).

**P0-3 · Every shape in every sample renders as a solid black rectangle/circle.**
`ComponentRenderer.buildShape` emits a bare `Rectangle()`/`Circle()` and then routes
`backgroundColor` through `.background(_:)`:

```swift
case .rectangle:
    Rectangle().applyCommonModifiers(properties.common)   // → .background(color)
```

An unstyled SwiftUI `Shape` fills itself with the foreground style (black in light mode), so
the shape paints over the background colour that was supposed to be its fill. All eleven
shape instances across the samples — and the `rectangle`/`circle` examples in the JUN spec
itself — specify `backgroundColor` and will render black.
*Fix:* shapes must use `.fill(parseColor(...))` for `backgroundColor` (or map
`foregroundColor` to fill and keep `backgroundColor` behind it — pick one and write it into
the spec).

**P0-4 · `imageName` is used by three shipped samples but was never implemented.**
`simple-layout`, `complex-layout` and `horizontal-scroll` use `"imageName": "star.fill"`
(and `imageWidth` / `imageHeight`). `ImageProperties` only decodes `imageURL`, and
`buildImage` returns `EmptyView()` when `imageURL` is nil — so those images silently vanish,
with no error, no placeholder, and no console warning. Neither the spec nor the schema
defines `imageName`.
*Fix:* decide the feature (see P1-3), then either implement local/SF-Symbol images or
rewrite the samples onto `imageURL`. Either way, an image component that cannot resolve a
source should render the failure placeholder rather than nothing.

**P0-5 · The shipped library contains POC demo code with a hardcoded path to the author's
laptop.**
`Sources/JUNSwiftUI/Views/JSONToSwiftUIViewModel.swift:51`:

```swift
let resourcePath: String = "/Users/pawel/JSONToSwiftUIPOC/Resources/SampleJSON/\(sampleName).json"
```

This file and `Sources/JUNSwiftUI/Views/ContentView.swift` (a `public` sample browser, 284
lines) are demo scaffolding that ships inside the library product. The Example app has its
own, better copy and does not use them. They add public API surface, a `@MainActor`
`@Observable` view model, and a dead absolute path to every consumer's binary.
*Fix:* delete both from `Sources/`; the Example app already covers the use case.

### 2.2 P1 — Spec conformance and correctness

**P1-1 · The v1.1 JSON Schema rejects the v1.1 feature.**
`schemas/jun.schema.json` sets `"additionalProperties": false` on the properties object and
never lists `font`. Validating the repo's own `font-showcase.json` against it yields
`Additional properties are not allowed ('font' was unexpected)` — 11 errors. The schema's
`$id` also still reads `.../v1.0/jun.schema.json` while the spec is 1.1.0.
This is the clearest symptom of the process gap in P2-6: the v1.1 spec prose was written in
*JUNSwiftUI* (`spec/jun-v1.1-font-support.md`), and the JUN repo's schema never caught up.

**P1-2 · An undocumented legacy dialect is accepted by the decoder.**
`ButtonProperties` accepts `buttonLabel`/`buttonAction`, `ScrollViewProperties` accepts
`scrollAxis`. None of these appear in the spec or the schema, but the shipped samples and
`QUICKSTART.md` use them — so the canonical examples of the format are written in a dialect
no other implementation will understand. This directly undermines the cross-platform premise.
*Fix:* migrate all samples and docs to `label`/`action`/`axis`; keep the aliases in the
decoder for one minor version, marked deprecated in code, and either document them in the
spec as deprecated aliases or drop them at 2.0.

**P1-3 · Spec/implementation disagreements to resolve explicitly.**

| Topic | Spec / schema says | JUNSwiftUI does |
|---|---|---|
| Children on `button` | Forbidden (schema `not: {required: [children]}`) | Supported — children become the button label |
| `imageName` / local images | Undefined | Undefined, but used by samples |
| Unknown component type | "MUST NOT break on future spec additions" | Throws if `properties` present; renders a `Text("Unknown type: …")` if absent |
| Button `action` | "Action identifier" | `print()` to console |

The unknown-type inconsistency is the sharpest: the same unknown component either kills the
whole document or degrades gracefully depending on whether it happens to carry a
`properties` object. Pick graceful degradation (spec-mandated) and apply it uniformly.

**P1-4 · `padding` does not behave as "internal padding".**
`applyCommonModifiers` orders modifiers `frame → aspectRatio → padding → colors →
cornerRadius → clipped`. Because `.frame` is applied *before* `.padding`, a component with
`width: 100, padding: 16` occupies 132pt, not 100pt — padding is added outside the declared
size. The spec calls `padding` "internal padding", which implies the opposite. Background
colour does correctly extend under the padding.
*Fix:* apply padding before frame, and add a test asserting the resulting geometry.

**P1-5 · `width`/`height` and `maxWidth`/`maxHeight` are mutually exclusive.**
`applyFrame` is a single `if/else-if` chain, so `{width: 100, maxHeight: 300}` silently
drops `maxHeight`. There is no reason for these to be exclusive — a single
`.frame(width:height:)` plus a separate `.frame(maxWidth:maxHeight:)` handles all
combinations.

**P1-6 · Decoding failures are silent, everywhere.**
Every property is decoded with `try?`, so `"fontSize": "20"` (a string) becomes `nil` and
falls back to the default with no diagnostic. Worse, children use it too:

```swift
self.children = try? container.decode([UIComponent].self, forKey: .children)
```

One malformed grandchild anywhere in a subtree silently empties the entire container. For a
server-driven UI system this is the difference between "a debuggable error" and "the screen
is mysteriously blank in production". The spec asks implementations to "provide helpful
error messages for invalid JSON".
*Fix:* keep lenient decoding as the default behaviour, but collect diagnostics into the
decoded tree (e.g. a `[JUNDiagnostic]` on the root) and expose a strict mode that throws.
Log to `OSLog` in debug builds.

**P1-7 · `applyFont` hardcodes 16pt for non-text components.**
`self.font(.custom(fontName, size: 16))` — putting `font` on a `vstack` therefore also
forces a 16pt size on it. `fontSize` is text-only in the property model, so the size cannot
be honoured here. Either make `fontSize` universal alongside `font`, or use
`.custom(name, size: …, relativeTo:)` against the inherited size.

**P1-8 · Unbounded recursion on untrusted input.**
`ComponentRenderer` recurses per child with no depth or node-count limit, and the decoder
has none either. The spec explicitly lists "circular references" under error handling. A
server-driven UI library will be fed remote documents; a deeply nested payload is a trivial
stack overflow.
*Fix:* enforce a max depth (say 64) and max node count at decode time, surfaced as a typed
error.

**P1-9 · Invalid values silently become defaults.**
An unrecognised colour becomes `.primary`, an unrecognised `alignment`/`fontWeight`/`axis`
becomes the default. Same reasoning as P1-6 — fine as behaviour, not fine as *silent*
behaviour.

### 2.3 P1/P2 — API design

**A-1 · The public surface is too small to build on.**
Only `UIComponent` (with `id` public but `type` and `children` internal), `ComponentRenderer`,
`JSONLoader` and `JSONLoaderError` are public. `ComponentProperties` and every property
struct are internal, and `UIComponent.init` is internal. A consumer therefore cannot inspect
a decoded tree, cannot construct one in Swift, cannot transform or filter one before
rendering, and cannot write a unit test that builds a fixture without going through JSON.
*Fix:* make the model public with public initialisers, and add a lightweight result-builder
DSL for constructing documents in Swift (which also makes the encode path testable).

**A-2 · There is no async loading — the "server-driven UI" path blocks the caller.**
`JSONLoader.loadFromURL` is `Data(contentsOf:)`. The README demonstrates it with
`https://api.example.com/ui/home`. That is a synchronous network call with no timeout, no
`URLSession` configuration, no cancellation, no caching, no retry, and no ETag support —
on whatever thread the caller is on, typically the main one.
*Fix:* add `static func load(from: URL, session: URLSession = .shared) async throws ->
UIComponent`, keep the sync variant for `file://` only, and add a `JUNView(url:)` convenience
view that handles loading/error/retry states.

**A-3 · Buttons cannot do anything.**
`print("Button tapped: …")` is the entire action implementation, so the one interactive
component in the format is inert. This is the single biggest functional gap for real use.
*Fix:* an action-dispatch closure injected through the SwiftUI environment —
`.junActionHandler { action in … }` — receiving the action identifier and the component. Then
specify the semantics in JUN (is `action` an opaque string? does it carry a payload
object?), because this is where implementations will diverge most.

**A-4 · Image rendering is not configurable.** No caching (every `AsyncImage` refetches), a
fixed `ProgressView` placeholder, a fixed `photo` failure icon, no local assets, no SF
Symbols, no `Image` accessibility label. `contentMode` only takes effect when `aspectRatio`
is also present, which is surprising.

**A-5 · Deprecated APIs.** `.cornerRadius(_:)` is deprecated as of iOS 17 (the package's own
minimum) in favour of `.clipShape(.rect(cornerRadius:))`, and `.foregroundColor(_:)` in
favour of `.foregroundStyle(_:)`. Both will start warning and eventually break.

**A-6 · `Equatable` compares randomly-generated UUIDs.** `UIComponent` synthesises
`Equatable` over all stored properties including `id`, which is a fresh `UUID()` whenever
the JSON omits one. Two decodes of the same document are therefore never `==`, which makes
the conformance useless for exactly the case tests want it for. (`Hashable` hashes only `id`,
which is at least consistent with that `==`, but the pair is confusing.)
*Fix:* exclude `id` from `==`, or add a separate `isStructurallyEqual(to:)`.

**A-7 · Module-wide `View` extension pollution.** `applyFrame`, `applyPadding`,
`applyClipped`, `parseColor`, `Color.init?(hex:)` and friends are declared as extensions on
`View`/`Color` at module scope. They are internal, so nothing leaks to consumers, but every
view in the module gets ten extra completions and `Color(hex:)` will collide with the
extension most host apps already have if it is ever made public.
*Fix:* fold them into a single `CommonModifiers: ViewModifier`, and namespace the colour
parser (`JUNColor.parse(_:)`).

**A-8 · No theming.** Colour names map to hardcoded SwiftUI constants; there is no way for a
host app to supply a palette, a design-token set, or dark-mode-aware custom colours. For the
A/B-testing and server-driven use cases in the JUN README, a theme injection point is close
to mandatory.

### 2.4 P2 — Repo hygiene and process

**P2-1 · No CI at all.** `.github/` contains only `FUNDING.yml`. Every P0 above would have
been caught by a five-minute workflow. Minimum viable pipeline: `swift build` + `swift test`
on macOS; `xcodebuild` the Example app for an iOS simulator; validate every `*.json` in the
repo against the JUN schema; SwiftLint.

**P2-2 · Sample JSON is duplicated and has already drifted.** `Resources/SampleJSON/` (5
files, not referenced by `Package.swift`, not used by anything) and
`Example/JUNSwiftUIApp/Resources/SampleJSON/` (5 files, bundled by the app). Two of the five
pairs already differ, and the drift is where P0-2 lives.
*Fix:* one source of truth. Best option: delete both copies and pull the canonical examples
from the JUN repo (git submodule, or a small `make sync-examples` script), so the reference
implementation is provably rendering the spec's own documents.

**P2-3 · `Resources/SampleJSON` is not declared in `Package.swift`.** No `resources:` entry
on the target, so those files are not in the bundle and `JSONLoader.loadFromBundle` cannot
reach them from tests.

**P2-4 · Tests cover decoding only.** Six tests, all "decode this JSON and check a property".
Nothing covers: rendering, encoding, round-tripping, malformed input, unknown types, missing
required properties, the legacy aliases, the shipped sample files, or any of the P0/P1 bugs
above. Notably, the font work added five decode tests and zero render tests, so P0-3-class
bugs are invisible to the suite.
*Fix:* add (a) a fixture-driven test that decodes every sample in the repo, (b) round-trip
encode/decode equality tests, (c) negative tests for each error path, (d) snapshot tests for
the render layer (`swift-snapshot-testing` or `ImageRenderer` + reference PNGs).

**P2-5 · Documentation is stale in ways that will actively mislead.**
- `QUICKSTART.md`: `cd /Users/pawel/JSONToSwiftUIPOC`, `swift run JSONToSwiftUIApp` (no such
  executable target), "three pre-built samples", the removed menu-based UI flow, and code
  samples using `imageName`, `scrollAxis` and `buttonLabel`.
- `README.md`: claims "Full JUN v1.0 specification compliance" (repo targets 1.1), lists
  `Models/RootDocument.swift` which does not exist, documents `JSONLoader.loadFromURL` for
  HTTPS without noting it is synchronous, and says "Comprehensive error handling".
- `Example/README.md`: `cd /Users/pawel/Developer/JUNSwiftUI`.
- `spec/jun-v1.1-font-support.md:268`: links to `github.com/yourusername/JUNSwiftUI`.
- `.claude/README.md` and `.claude/agents/json-to-swiftui-expert.md`: describe the
  pre-rename "JSONToSwiftUIPOC" package, a `Sources/JSONToSwiftUIPOC/` layout, and a demo app
  at `/Users/pawel/Developer/JSONToSwiftUIApp`. The `json-to-swiftui-expert` agent is
  superseded by `jun-swiftui-expert` and should be deleted rather than left to contradict it.

**P2-6 · Spec authorship lives in the wrong repo.** `JUNSwiftUI/spec/jun-v1.1-font-support.md`
is a *specification* document sitting in an *implementation* repo. That is how the schema
came to be out of sync (P1-1) and how the legacy dialect (P1-2) went undocumented.
*Fix:* move it to `JUN/spec/`, and adopt a rule: spec changes land in JUN (prose + schema +
conformance fixtures, in one PR) before any implementation ships them.

**P2-7 · Fragile Xcode local package reference.**
`Example/JUNSwiftUIApp.xcodeproj` declares `XCLocalSwiftPackageReference relativePath =
"../../JUNSwiftUI"`, which resolves only if the clone directory is named exactly
`JUNSwiftUI`. `git clone <url> junswiftui` breaks the Example app. Should be `..`.

**P2-8 · Missing project furniture.** No `CHANGELOG.md`, no `CONTRIBUTING.md`, no issue/PR
templates, no `.swiftlint.yml` or `.swift-format`, no DocC catalogue, no `CODEOWNERS`.

**P2-9 · JUN repo, smaller items.**
- README links `examples/counter/` — the directory does not exist.
- README "Version History" lists only v1.0.0 while the header says 1.1.0.
- Schema `$id` still points at `v1.0`.
- Schema colour `pattern` forbids shorthand `#RGB` (matching the spec) but the Swift parser
  silently returns `.primary` for it rather than erroring — worth stating the expected
  behaviour for invalid colours in the spec.
- The three JUN examples do validate cleanly against the schema, which is good and worth
  locking in with CI.

### 2.5 P3 — Product direction

The JUN roadmap (navigation, `{{var}}` data binding, `forEach`, conditionals, form
components, state) is the right list, but none of it should start before §2.1–§2.3 are done:
adding `forEach` on top of silent decode failures and an untested renderer will compound the
problem. The one roadmap item worth pulling forward is **action semantics** (A-3), because
buttons already exist in v1.1 and currently do nothing, so the format ships an interactive
component with undefined behaviour.

One structural recommendation for the ecosystem: before JUNReact or JUNAndroid exist, add a
**conformance suite** to the JUN repo — a `conformance/` directory of input documents paired
with expected-outcome descriptions (and, where feasible, reference renderings). Two
implementations that both "follow the spec" will otherwise disagree on exactly the questions
this review surfaced: does `padding` sit inside or outside `width`, what fills a shape,
what happens on an unknown type. Writing those answers down as executable fixtures is the
cheapest way to make "write once, render anywhere" true.

---

## 3. Plan

Phases are ordered by dependency. Estimates assume one developer familiar with the code.

### Phase 0 — Unblock (½–1 day) · repo: JUNSwiftUI + JUN

Goal: the documented install works and the shipped samples render correctly.

1. Fix the trailing comma in `Example/.../horizontal-scroll.json` (P0-2).
2. Fix shape fill — `.fill()` instead of `.background()` for shapes (P0-3).
3. Delete `Sources/JUNSwiftUI/Views/ContentView.swift` and `JSONToSwiftUIViewModel.swift`
   (P0-5). Confirm the Example app still builds.
4. Add `font` to `schemas/jun.schema.json`, bump `$id` to v1.1 (P1-1, JUN repo).
5. Tag and release `1.1.0` on both repos; correct the README install snippet (P0-1).

### Phase 1 — Conformance and correctness (2–3 days) · JUNSwiftUI

Goal: what the docs say is what the code does.

6. Migrate all samples and docs off `imageName`/`scrollAxis`/`buttonLabel`; mark the decoder
   aliases `@available(*, deprecated)` (P1-2, P0-4).
7. Decide `imageName` (recommend: add `systemImage` and `imageName` to JUN v1.2 as
   alternatives to `imageURL`, exactly one required) and make an unresolvable image render
   the failure placeholder (P0-4).
8. Fix modifier ordering so `padding` is internal to `width`/`height` (P1-4), and make
   frame properties composable (P1-5).
9. Make unknown-type handling uniform and graceful (P1-3).
10. Add decode diagnostics + a strict mode; stop swallowing child-decode failures (P1-6, P1-9).
11. Add depth and node-count limits (P1-8).
12. Fix `applyFont`'s hardcoded 16pt (P1-7).

### Phase 2 — Infrastructure (2–3 days) · JUNSwiftUI + JUN

Goal: none of the above can regress.

13. GitHub Actions on both repos: build, test, Example-app build, schema-validate every JSON,
    SwiftLint (P2-1).
14. Collapse the duplicated sample sets to one source, sourced from the JUN repo (P2-2), and
    declare it as a package resource so tests can load it (P2-3).
15. Expand the test suite: fixture decode, round-trip, negative paths, render snapshots (P2-4).
16. Fix the Xcode local package path (P2-7). Add SwiftLint config, CHANGELOG, CONTRIBUTING
    (P2-8).

### Phase 3 — API maturity (3–5 days) · JUNSwiftUI

Goal: usable as a real server-driven-UI dependency.

17. Public model + public initialisers + a Swift result-builder DSL (A-1).
18. Async `URLSession`-based loading with timeouts, cancellation and caching; a `JUNView(url:)`
    with loading/error/retry states (A-2).
19. Environment-injected action handler, with the semantics written into JUN first (A-3).
20. Configurable image pipeline: cache, custom placeholder/failure views, accessibility
    labels, local + SF Symbol sources (A-4).
21. Replace deprecated modifiers (A-5); fix `Equatable` (A-6); consolidate the `View`
    extensions into one `ViewModifier` (A-7).
22. Theme/palette injection point (A-8).

### Phase 4 — Documentation (1 day) · both repos

23. Rewrite `QUICKSTART.md` against the current app and API; correct `README.md`'s
    compliance claim, file listing and loader caveats; strip absolute paths from
    `Example/README.md` (P2-5).
24. Move `spec/jun-v1.1-font-support.md` into the JUN repo and fix its placeholder link
    (P2-6). Fix the JUN README's dead `examples/counter/` link and version history (P2-9).
25. Delete the superseded `.claude/agents/json-to-swiftui-expert.*` and refresh
    `.claude/README.md` (P2-5).
26. Add a DocC catalogue so the public API is browsable.

### Phase 5 — Spec v1.2 (ongoing) · JUN

27. Publish the conformance fixture suite (§2.5) — do this *before* a second implementation
    exists, not after.
28. Specify action semantics, then navigation, then `forEach` + `{{var}}` binding, then form
    components — each landing as prose + schema + fixtures in one PR, implementation after.

---

## 4. Suggested first pull request

Phase 0 is five small, independent changes with visible user impact and no design decisions
attached. Landing it as one PR — plus item 13 (CI) pulled forward so the PR itself is
verified — gets the project from "cannot be installed and renders three samples wrong" to
"works as advertised", which is the precondition for everything else.

## 5. Decisions — resolved 2026-08-08

| # | Decision | Resolution | Consequence |
|---|---|---|---|
| 1 | Local images | **Implement** | New JUN property; spec + schema change lands in JUN first |
| 2 | Button children | **Deferred** | Stays a known divergence; documented, not resolved |
| 3 | Legacy aliases | **Remove now**, no deprecation cycle | Must land *before* the first tag — see §5.1 |
| 4 | Action model | See **Appendix A** — proposal awaiting ratification | Spec change; gates Phase 3 item 19 |
| 5 | Example sharing | **Share** | JUN becomes upstream for all examples — see §5.2 |
| 6 | Strictness | See **Appendix B** — proposal awaiting ratification | Changes the loader's return type; must precede the first tag |

### 5.1 Sequencing consequence of decisions 3 and 6

Both are breaking changes, and Phase 0 item 5 tags `1.1.0`. Tagging first would make each of
them a breaking change against a released version — which is precisely the situation the
"no 2.0 needed" decision is trying to avoid. **Move the legacy-alias removal (and, if
Appendix B is accepted, the loader signature change) into Phase 0, ahead of the tag.** With
no tags in existence today, both are free right now and expensive in a week.

Revised Phase 0 ordering:

1. Fix the invalid JSON (P0-2), shape fill (P0-3), POC deletion (P0-5), schema `font` (P1-1).
2. Remove `buttonLabel` / `buttonAction` / `scrollAxis` from the decoder; migrate every
   sample and doc snippet onto `label` / `action` / `axis`, and `imageWidth` / `imageHeight`
   onto `width` / `height` (P1-2).
3. Land the loader/diagnostics shape if Appendix B is accepted.
4. *Then* tag `1.1.0` and fix the README install snippet (P0-1).

### 5.2 What "share the examples" actually means

The two example sets are not siblings — they are the same documents at different ages:

| JUN | JUNSwiftUI | Status |
|---|---|---|
| `examples/simple-layout` | `simple-layout` | Same doc; JUN's is clean, JUNSwiftUI's uses the legacy dialect and older copy |
| `examples/product-list` | `complex-layout` | **Same document under two names**; JUN's is clean |
| `examples/horizontal-scroll` | `horizontal-scroll` | Same doc; JUNSwiftUI's is the broken copy (P0-2) |
| — | `remote-images` | Only in JUNSwiftUI; needs contributing upstream |
| — | `font-showcase` | Only in JUNSwiftUI; needs contributing upstream |
| `examples/counter` (README link) | — | Referenced but never written |

All three JUN examples validate cleanly against the schema; three of five JUNSwiftUI samples
do not. So the sync direction is not a coin flip — **JUN is already the corrected upstream**,
and adopting it deletes three of the four sample defects as a side effect.

Work involved:

1. Contribute `remote-images` and `font-showcase` to `JUN/examples/` in the repo's
   `<name>/screen.json` + `README.md` convention.
2. Rename JUNSwiftUI's `complex-layout` to `product-list` to match upstream.
3. Delete both JUNSwiftUI sample directories; replace with a synced copy.
4. Either write `examples/counter` or drop the dead README link (P2-9).

**Mechanism: a sync script plus a committed copy plus a CI drift check — not a submodule.**
A submodule inside the package repo gets fetched by every SPM consumer, and test resources
need the files physically present anyway. `Scripts/sync-examples.sh` pulls from a pinned JUN
tag into `Examples/`, and CI fails if the working copy differs from a fresh sync. Same
guarantee, none of the submodule cost, and the package stays self-contained.

---

## Appendix A — Action model (proposal)

**Question:** is `action` an opaque identifier string, or a structured object?

### The three real options

**A · Opaque string.** `"action": "checkout"`. What the spec says today. Simplest possible
thing, and fully host-mediated — a document can only *name* an intent the app already
implements. But it carries no data, so a product list cannot express "add item 42 to cart"
without encoding parameters into the string (`"addToCart:42"`), which is a private dialect
waiting to happen — the exact failure mode as `buttonLabel`. Server-driven UI is precisely
the case that needs parameters.

**B · Structured object.** `{"name": "addToCart", "params": {"productId": "42"}}`. Carries a
payload, still fully host-mediated, JSON-native. Costs a decision about what `params` values
may be, and a small value type in Swift.

**C · Spec-defined verbs.** The spec defines standard actions with mandated cross-platform
semantics — `openURL`, `navigate`, `dismiss` — plus a custom escape hatch. The only option
that makes *interaction* portable rather than just layout, and it is where the v1.2
navigation roadmap item inevitably leads.

### Recommendation: B now, shaped so C is additive later

```json
"action": "checkout"
"action": { "name": "addToCart", "params": { "productId": "42", "qty": 1 } }
```

Both forms canonical. The string is defined *in the spec* as sugar for
`{name: …, params: {}}` — which is not a repeat of the legacy-alias mistake, because the
mistake there was that the alias existed only in one decoder and in no document anyone else
could read.

Four rulings that come with it:

1. **`params` values are JSON scalars only** at v1.2 — string, number, boolean, null. No
   nested objects or arrays. This keeps the Swift type to a four-case enum with no
   dependency and makes binding trivial on every platform. It can be widened later; it
   cannot be narrowed.
2. **Dotted names are reserved.** `jun.*` is reserved for future spec-defined verbs;
   unprefixed names are app-defined. Implementations MUST forward an unrecognised `jun.*`
   action to the host rather than erroring. This is what makes C additive rather than
   breaking — reserving the namespace now costs one sentence.
3. **`action` stays button-only.** A universal `onTap` is a separate interaction-model
   question (hit testing, nested tappables, accessibility traits) and buttons cover the case.
4. **The handler is synchronous.** `(JUNAction) -> Void`; a host that needs to await
   something spawns its own `Task`. Specifying an async result model before we know what the
   UI does with the result is premature.

### Why not C yet — the argument that actually decides it

A and B are safe by construction: the document names an intent, and nothing happens unless
the host app implements it. The moment the spec defines `jun.openURL` with mandated
behaviour, a remote document gains the power to make the app act *without any app code*.
That is a phishing surface, and every future implementation would have to get the host-veto
story right independently. That is a real design job, not a schema addition — and the
reserved namespace means deferring it costs nothing.

### Swift shape

```swift
public struct JUNAction: Hashable, Sendable {
    public let name: String
    public let params: [String: JUNValue]
}

public enum JUNValue: Hashable, Sendable, Codable {
    case string(String), number(Double), bool(Bool), null
}

// Injected through the environment, not per-view:
ComponentRenderer(component: document.root)
    .junActionHandler { action in
        switch action.name {
        case "addToCart": cart.add(action.params["productId"]?.stringValue)
        default: break
        }
    }
```

Default handler: no-op, with an `OSLog` line in debug builds. Never an unconditional
`print`, which is what ships today.

---

## Appendix B — Strictness (proposal)

**Question:** lenient-with-diagnostics, or strict-by-default with an opt-out?

### The framing is the answer

"Strictness" conflates three separate axes — what happens to a bad node, whether anyone is
told, and who chooses. Today the answer to all three is the same: drop it, tell nobody, no
choice. Splitting them shows that the two classes of failure have *opposite* correct
answers:

| | Forward-compatibility failure | Malformed input |
|---|---|---|
| Example | Unknown component type; a v1.3 property arriving at a v1.2 client | `"fontSize": "20"`; missing required `content`; trailing comma |
| Cause | The producer is ahead of the client | The producer has a bug |
| Correct behaviour | **Degrade.** The spec mandates it — a client that throws here means the server can never ship a new component without a coordinated app release, which destroys the point of server-driven UI | **Be loud.** Silently dropping it means the bug ships and nobody ever learns |

So the question is not which one to pick. It is: **lenient rendering, strict reporting,
caller-chosen policy.**

### Recommendation

```swift
public struct JUNDocument {
    public let root: UIComponent
    public let diagnostics: [JUNDiagnostic]   // always populated, never discarded
}

public struct JUNDiagnostic: Sendable {
    public enum Severity { case error, warning }
    public let severity: Severity
    public let path: String      // "children[0].children[2].properties.fontSize"
    public let message: String
}

public struct JUNParseOptions {
    public var unknownComponents: UnknownPolicy = .skip     // .skip | .placeholder | .fail
    public var invalidValues: InvalidPolicy   = .useDefault // .useDefault | .fail
    public var maxDepth: Int  = 64
    public var maxNodes: Int  = 10_000
}
```

Five rulings:

1. **`path` is the deliverable.** More than any policy knob, a JSON-pointer trail is what
   turns "the screen is blank" into "`children[3].properties.imageURL` was not a string".
   If only one thing from this appendix ships, ship this.
2. **A malformed child must not take out its siblings.** Today `try?` on the whole
   `[UIComponent]` array means one bad grandchild silently empties an entire container.
   Decode children element-by-element; drop only the bad one; record a diagnostic. This is
   the single highest-value change in the area.
3. **Debug builds are loud for free.** Diagnostics at `.error` go to `OSLog` automatically,
   so a developer sees them without opting in to anything.
4. **Release builds hand diagnostics to the caller**, who can forward them to telemetry.
   For server-driven UI this is the payoff: your *server* finds out its own documents are
   broken, from the field, without anyone filing a bug.
5. **Resource limits always throw.** Depth and node caps are protection against untrusted
   input, not a style preference, so they are not part of the lenient path.

Plus `JSONLoader.strict(_:) throws` — fails on the first `.error` — for use in tests and CI.

### Two things this unlocks

Combined with decision 5, CI gets a conformance check nearly free: run the strict loader
over every canonical JUN example on every commit, and any divergence between the spec's
documents and the reference implementation fails the build.

And it changes the loader's return type from `UIComponent` to `JUNDocument`, which is a
breaking change — free today, expensive after the first tag. Hence §5.1.
