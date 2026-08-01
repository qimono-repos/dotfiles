---
name: "amazon-devices-vega-ui-components"
description: |
  High performance Vega UI Components with native bindings such as Carousel.
  Use when a developer needs to use or customize Vega-specific UI components.
  
version: "1.0.0"
tags: ["vega", "ui", "components", "carousel"]
---

# Vega UI Components

## Prerequisites

This skill requires the `amazon-devices-buildertools-mcp` MCP server. Install the MCP server in your AI agent's MCP configuration. Example:

    {
      "amazon-devices-buildertools-mcp": {
        "command": "npx",
        "args": ["-y", "@amazon-devices/amazon-devices-buildertools-mcp@latest"]
      }
    }

## Overview

Vega provides TV-optimized UI components through `@amazon-devices/kepler-ui-components`. The primary component is the Carousel — a high-performance list component for horizontal or vertical scrolling content with built-in focus management.

## Core Concepts

- Carousel from `@amazon-devices/kepler-ui-components` is the recommended list component for TV — not FlatList
- Carousel vs FlatList: Carousel has TV-optimized performance, built-in focus management, multiple item type support, and built-in focus indicators
- Carousel requires `itemDimensions` (array of `ItemInfo` objects), `getItemForIndex`, and `keyProvider` props
- Supports `orientation`: `'horizontal'` (default) or `'vertical'`
- Focus indicator types: `'fixed'` (default) or `'floating'`

## Common Mistakes

| Problem | Fix |
|---|---|
| Using FlatList for TV content lists | Use Carousel from `@amazon-devices/kepler-ui-components` — it's TV-optimized with built-in focus management |
| Missing `itemDimensions` prop | Carousel requires `itemDimensions` array defining dimensions for each item type |
| Focus not working in Carousel | Carousel has built-in focus management — don't add manual focus handlers that conflict |
| Poor scroll performance | Ensure `keyProvider` returns stable unique keys — unstable keys cause unnecessary re-renders |

Use `amazon-devices-buildertools-mcp:search_documentation` to find troubleshooting guides and learn more about any topic.

## Workflow

1. Use `amazon-devices-buildertools-mcp:read_document` to read `react_native_for_vega_ui_components.md` for the complete UI components guide
2. Use `amazon-devices-buildertools-mcp:list_documents` to discover related docs (focus management, navigation)
3. Use `amazon-devices-buildertools-mcp:search_documentation` to find specific UI component topics

## Dependencies

Tools used from `amazon-devices-buildertools-mcp`:
- `amazon-devices-buildertools-mcp:read_document`
- `amazon-devices-buildertools-mcp:list_documents`
- `amazon-devices-buildertools-mcp:search_documentation`
