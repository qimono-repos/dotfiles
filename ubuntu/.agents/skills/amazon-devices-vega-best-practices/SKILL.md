---
name: "amazon-devices-vega-best-practices"
description: |
  Performance guidelines, development workflow, and architecture recommendations for Vega apps.
  Use when a developer needs guidance on Vega development best practices and common pitfalls.
  
version: "1.0.0"
tags: ["vega", "best-practices", "performance", "guidelines"]
---

# Development Best Practices

## Prerequisites

This skill requires the `amazon-devices-buildertools-mcp` MCP server. Install the MCP server in your AI agent's MCP configuration. Example:

    {
      "amazon-devices-buildertools-mcp": {
        "command": "npx",
        "args": ["-y", "@amazon-devices/amazon-devices-buildertools-mcp@latest"]
      }
    }

## Overview

Vega app development has platform-specific constraints and patterns that differ from standard React Native development. Following these practices prevents critical failures and ensures apps meet platform requirements.

## Core Concepts

- Never bundle React or React Native in your app — these are system-provided by Vega OS
- Cold start target: < 3 seconds to first frame — defer non-critical initialization, use lazy loading
- Use `@amazon-devices/react-navigation` for navigation — not standard `@react-navigation/` packages
- All UI must be reachable via D-Pad — implement proper focus states on every interactive element
- Minimum touch target: 48x48dp for accessibility compliance
- Use Vega Studio VS Code extension and Vega Virtual Device for development and testing

## Common Mistakes

| Problem | Fix |
|---|---|
| React/React Native bundled in app | Check package.json for accidental inclusion, use `--exclude react,react-native` in build |
| No focus states on UI elements | Implement `onFocus`/`onBlur` handlers with visual feedback on every interactive component |
| Missing headless service implementation | Required for content personalization and background data sync — system rejects apps without proper services |
| Hardcoded device dimensions | Use `Dimensions.get('window')` instead of hardcoded values like `1920` |
| Not profiling performance | Use React DevTools Profiler, `kepler device performance`, and test on actual Fire TV devices |

Use `amazon-devices-buildertools-mcp:search_documentation` to find troubleshooting guides and learn more about any topic.

## Workflow

1. Use `amazon-devices-buildertools-mcp:read_document` to read `react_native_for_vega_development_best_practices.md` for the complete best practices guide
2. Use `amazon-devices-buildertools-mcp:list_documents` to discover related docs (performance optimization, focus management, architecture)
3. Use `amazon-devices-buildertools-mcp:search_documentation` to find specific best practice topics

## Dependencies

Tools used from `amazon-devices-buildertools-mcp`:
- `amazon-devices-buildertools-mcp:read_document`
- `amazon-devices-buildertools-mcp:list_documents`
- `amazon-devices-buildertools-mcp:search_documentation`
