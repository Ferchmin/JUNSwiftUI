# Claude Code Configuration

Specialized agents for working on the JUNSwiftUI package.

## Available agents

### `jun-swiftui-expert`

Knows this package's architecture and the JUN specification it implements.

**Use when:**

- Adding or changing component types and their properties
- Working on decoding, diagnostics, or the parse policies
- Debugging why a document renders the way it does
- Writing tests for components or parse behaviour

## Working on this repository

Two things are easy to get wrong here, both of which have caused real defects:

1. **Specification changes belong in the [JUN repository](https://github.com/ferchmin/JUN)
   first** — prose, JSON Schema and examples in one change — and land here afterwards. The v1.1
   schema shipped without the property v1.1 was released for because it was written the other
   way round.

2. **Example documents come from upstream.** They are synced into
   `Example/JUNSwiftUIApp/Resources/Examples/` by `Scripts/sync-examples.sh`, and CI fails if
   the committed copies drift. Edit them in the JUN repository, then re-sync.

## Architecture in brief

- `Models/` — the component tree and its per-type property structs. Decoding is hand-written
  because the JSON is flat while the model is not.
- `Parsing/` — loaders, options, and the diagnostic collection threaded through decoding via
  `JSONDecoder.userInfo`.
- `Views/` — the renderer, the universal-property modifier, action dispatch, color parsing.

Two invariants worth keeping in mind when changing the parser:

- **Unknown things degrade; malformed things are reported.** These pull in opposite directions
  and must not be collapsed into one policy.
- **A malformed component must never take out its siblings.** Children decode one element at a
  time for this reason.

## Invoking agents

Agents are suggested automatically, or ask for one by name:

```
Use the jun-swiftui-expert agent to add a new component type
```
