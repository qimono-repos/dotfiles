---
name: "amazon-devices-vega-focus-management"
description: |
  Cartesian focus management for D-Pad navigation with TVFocusGuideView and FocusManager.
  Use when a developer needs to implement D-Pad navigation or focus management in a Vega app.
  
version: "1.0.0"
tags: ["vega", "focus", "dpad", "navigation", "tv"]
---

# Focus Management

## Prerequisites

This skill requires the `amazon-devices-buildertools-mcp` MCP server. Install the MCP server in your AI agent's MCP configuration. Example:

    {
      "amazon-devices-buildertools-mcp": {
        "command": "npx",
        "args": ["-y", "@amazon-devices/amazon-devices-buildertools-mcp@latest"]
      }
    }

## Overview

TV apps require proper focus management for D-Pad navigation — fundamentally different from touch-based mobile apps. Vega uses Cartesian focus management where focus moves to the closest item in the direction of a D-Pad key press.

## Core Concepts

- Vega uses Cartesian focus management — focus moves based on weighted distance calculations, not a linear list
- `Button`, `Pressable`, `TouchableOpacity`, `TouchableHighlight` are focusable by default
- `View`, `Text`, `Image` are NOT focusable by default — set `focusable={true}` to enable
- Focus indicators MUST include physical changes (borders, size) not just color/opacity changes — required for accessibility compliance
- Ensure enough margin between elements to accommodate scale transforms on focus

## Common Mistakes

| Problem | Fix |
|---|---|
| UI elements unreachable via D-Pad | Ensure all interactive elements are focusable and positioned so the Cartesian algorithm can reach them |
| Focus indicator only changes color | Add physical changes (border, scale) — color-only indicators fail accessibility |
| Focus jumps unexpectedly | Check component positioning and edge overlap — Cartesian distance affects navigation paths |
| No visual feedback on focus | Add `onFocus`/`onBlur` handlers with style changes to every focusable component |

Use `amazon-devices-buildertools-mcp:search_documentation` to find troubleshooting guides and learn more about any topic.

## Workflow

1. Use `amazon-devices-buildertools-mcp:read_document` to read `react_native_for_vega_tv_app_focus_management.md` for the complete focus management guide
2. Use `amazon-devices-buildertools-mcp:list_documents` to discover related docs (navigation, UI components)
3. Use `amazon-devices-buildertools-mcp:search_documentation` to find specific focus management topics

## Dependencies

Tools used from `amazon-devices-buildertools-mcp`:
- `amazon-devices-buildertools-mcp:read_document`
- `amazon-devices-buildertools-mcp:list_documents`
- `amazon-devices-buildertools-mcp:search_documentation`
