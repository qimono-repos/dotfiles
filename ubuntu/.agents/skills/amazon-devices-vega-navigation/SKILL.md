---
name: "amazon-devices-vega-navigation"
description: |
  Stack, tab, and drawer navigation using Amazon-specific react-navigation packages.
  Use when a developer needs to implement screen navigation in a Vega app.
  
version: "1.0.0"
tags: ["vega", "navigation", "routing", "stack", "tab"]
---

# Navigation

## Prerequisites

This skill requires the `amazon-devices-buildertools-mcp` MCP server. Install the MCP server in your AI agent's MCP configuration. Example:

    {
      "amazon-devices-buildertools-mcp": {
        "command": "npx",
        "args": ["-y", "@amazon-devices/amazon-devices-buildertools-mcp@latest"]
      }
    }

## Overview

Vega uses Amazon-specific navigation packages — not the standard `@react-navigation/` packages from npm. The packages provide TV-optimized focus management and screen transitions.

## Core Concepts

- Use `@amazon-devices/react-navigation__native` and `@amazon-devices/react-navigation__stack` — NOT `@react-navigation/native` or `@react-navigation/stack`
- Package names use double underscores: `react-navigation__native` (not single underscore or slash)
- Version ~7.0.0 for navigation packages, ~2.0.0 for screens
- Call `enableScreens()` and `enableFreeze()` from `@amazon-devices/react-native-screens` at app entry point for performance
- `NavigationContainer` comes from `@amazon-devices/react-navigation__native`
- Use `createStackNavigator` from `@amazon-devices/react-navigation__stack` — this is the JS-based stack navigator and works with the minimal dependency set

Required packages:

```json
"dependencies": {
    "@amazon-devices/react-navigation__stack": "~7.0.0",
    "@amazon-devices/react-navigation__native": "~7.0.0",
    "@amazon-devices/react-native-screens": "~2.0.0"
}
```

Correct imports:

```typescript
import {enableFreeze, enableScreens} from '@amazon-devices/react-native-screens';
import {createStackNavigator} from '@amazon-devices/react-navigation__stack';
import {NavigationContainer} from '@amazon-devices/react-navigation__native';
```

## Common Mistakes

| Problem | Fix |
|---|---|
| Using `@react-navigation/` packages | Replace with `@amazon-devices/react-navigation__` packages — standard React Navigation packages don't work on Vega |
| Using `createNativeStackNavigator` without extra deps | Use `createStackNavigator` from `@amazon-devices/react-navigation__stack` instead — it works with the minimal 3-package dependency set. Native stack requires additional packages (`native-stack`, `safe-area-context`). |
| Single underscore in package name | Use double underscores: `react-navigation__native` not `react-navigation_native` |
| Missing `enableScreens()` call | Add `enableScreens()` and `enableFreeze()` at app entry point for performance |
| Navigation not responding to D-Pad | Ensure `@amazon-devices/react-native-screens` is installed — it provides TV-optimized screen management |

Use `amazon-devices-buildertools-mcp:search_documentation` to find troubleshooting guides and learn more about any topic.

## Workflow

1. Use `amazon-devices-buildertools-mcp:read_document` to read `react_native_for_vega_navigation.md` for the complete navigation guide
2. Use `amazon-devices-buildertools-mcp:list_documents` to discover related docs (focus management, deep linking)
3. Use `amazon-devices-buildertools-mcp:search_documentation` to find specific navigation topics

## Dependencies

Tools used from `amazon-devices-buildertools-mcp`:
- `amazon-devices-buildertools-mcp:read_document`
- `amazon-devices-buildertools-mcp:list_documents`
- `amazon-devices-buildertools-mcp:search_documentation`
