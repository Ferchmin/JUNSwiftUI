# Claude Code Configuration

This directory contains specialized agents for working with the JSONToSwiftUIPOC package.

## Available Agents

### `json-to-swiftui-expert`

Expert agent for the JSON-to-SwiftUI POC architecture.

**Use when:**
- Adding new component types (List, Form, TextField, etc.)
- Modifying component properties or rendering logic
- Debugging JSON parsing or Codable issues
- Understanding the type-safe architecture
- Creating sample JSON files
- Writing tests for components

**Examples:**

```
User: "I want to add a TextField component"
→ Use json-to-swiftui-expert agent to implement TextField with proper properties
```

```
User: "Why isn't my button's backgroundColor working?"
→ Use json-to-swiftui-expert agent to debug button rendering
```

```
User: "How do I add a new common property for all components?"
→ Use json-to-swiftui-expert agent to guide adding properties to CommonProperties
```

## Agent Knowledge

The agent has deep knowledge of:

- **Architecture:** ComponentProperties enum, type-safe property structs, custom Codable
- **Patterns:** Flattened JSON structure, immutable configuration, view modifier composition
- **Components:** All 10+ built-in components and how to extend
- **Rendering:** ComponentRenderer switch patterns, builder methods
- **Testing:** Swift Testing framework patterns for property matching

## Invoking Agents

In Claude Code, agents are automatically suggested based on your task, or you can manually invoke:

```
Use the json-to-swiftui-expert agent to help me add a new component
```

The agent will have access to all tools and the full codebase context, plus specialized knowledge about this project's patterns and best practices.
