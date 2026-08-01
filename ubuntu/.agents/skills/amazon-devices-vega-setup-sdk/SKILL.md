---
name: "amazon-devices-vega-setup-sdk"
description: |
  Installs and configures the Vega SDK with prerequisite checks and verification.
  Use when a developer needs to install the Vega SDK or when vega/kepler CLI commands are not found.
  
version: "1.0.0"
tags: ["vega", "sdk", "installation", "setup", "cli"]
---

# Setup Vega SDK

## Prerequisites

This skill requires the `amazon-devices-buildertools-mcp` MCP server. Install the MCP server in your AI agent's MCP configuration. Example:

    {
      "amazon-devices-buildertools-mcp": {
        "command": "npx",
        "args": ["-y", "@amazon-devices/amazon-devices-buildertools-mcp@latest"]
      }
    }

## Overview

Installs Vega SDK (CLI tools, libraries, components) for Vega OS app development. Automatically detects existing installations, fixes PATH configuration if needed, or runs a fresh installation.

## Core Concepts

- Vega SDK requires macOS 10.15+ or Ubuntu 20.04+, Node.js 16+, and Homebrew system packages (binutils, coreutils, gawk, findutils, grep, jq, lz4, gnu-sed, watchman)
- The SDK detection flow checks: `vega` command → `kepler` command → `~/vega/sdk/` directory → `~/kepler/sdk/` directory → fresh install
- If the CLI command exists but isn't in PATH, the fix is adding `source $HOME/vega/env` to shell config — not reinstalling
- ARM64 Macs require Rosetta to be installed before the SDK

## Common Mistakes

| Problem | Fix |
|---|---|
| `vega` command not found after install | Run `source ~/vega/env` or open a new terminal |
| Running install script directly from agent | The install script is interactive — instruct the user to run it manually and wait for confirmation |
| Missing system dependencies | Check and install Homebrew packages before SDK install |
| Skipping Node.js version check | SDK requires Node.js 16+ — verify with `node --version` first |

Use `amazon-devices-buildertools-mcp:search_documentation` to find troubleshooting guides and learn more about any topic.

## Workflow

1. Use `amazon-devices-buildertools-mcp:read_document` to read `vega_sdk_installation.md` for the complete installation workflow
2. Use `amazon-devices-buildertools-mcp:search_documentation` to find SDK troubleshooting guides

## Dependencies

Tools used from `amazon-devices-buildertools-mcp`:
- `amazon-devices-buildertools-mcp:read_document`
- `amazon-devices-buildertools-mcp:list_documents`
- `amazon-devices-buildertools-mcp:search_documentation`
