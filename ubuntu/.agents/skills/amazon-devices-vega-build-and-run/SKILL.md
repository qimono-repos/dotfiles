---
name: "amazon-devices-vega-build-and-run"
description: |
  Complete guide for building, deploying, and running React Native for Vega applications.
  Use when a developer needs to build, install, run, or deploy their Vega app to a device.
  
version: "1.0.0"
tags: ["vega", "build", "run", "install", "deployment", "fast-refresh"]
---

# Build and Run Vega App

## Prerequisites

This skill requires the `amazon-devices-buildertools-mcp` MCP server. Install the MCP server in your AI agent's MCP configuration. Example:

    {
      "amazon-devices-buildertools-mcp": {
        "command": "npx",
        "args": ["-y", "@amazon-devices/amazon-devices-buildertools-mcp@latest"]
      }
    }

## Overview

Covers the full build-deploy-run cycle for Vega apps: development builds, production builds, Fast Refresh for live code updates, and device deployment via the Kepler CLI.

## Core Concepts

- Development build: `npm run build:debug`, production build: `npm run build:release`
- Fast Refresh requires three components running simultaneously: Metro Bundler, port forwarding, and app launch
- Port forwarding uses `--forward false` which means reverse port forwarding (device connects to local Metro)
- Port forwarding persists until device reboot or explicit stop
- Changes to `.tsx` files hot-reload automatically on save when Fast Refresh is active

## Common Mistakes

| Problem | Fix |
|---|---|
| Fast Refresh not working | Ensure Metro is running before launching the app, check port forwarding with `kepler device is-port-forwarded --port 8081` |
| Reusing terminal window for port forwarding | Port forwarding MUST run in a separate terminal from `npm start` — never reuse the Metro terminal |
| Changes not appearing on device | Press `r` in Metro terminal to reload, or relaunch app with `kepler device launch-app --dir .` |
| Build fails with missing dependencies | Run `npm install` before building |

Use `amazon-devices-buildertools-mcp:search_documentation` to find troubleshooting guides and learn more about any topic.

## Workflow

1. Use `amazon-devices-buildertools-mcp:read_document` to read `react_native_for_vega_app_build_and_install.md` for the complete build and deployment guide
2. Use `amazon-devices-buildertools-mcp:list_documents` to discover related docs (project structure, template app setup)
3. Use `amazon-devices-buildertools-mcp:search_documentation` to find specific build or deployment topics

## Dependencies

Tools used from `amazon-devices-buildertools-mcp`:
- `amazon-devices-buildertools-mcp:read_document`
- `amazon-devices-buildertools-mcp:list_documents`
- `amazon-devices-buildertools-mcp:search_documentation`
