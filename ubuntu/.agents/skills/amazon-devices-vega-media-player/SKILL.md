---
name: "amazon-devices-vega-media-player"
description: |
  W3C MSE/EME standard media playback with DRM support, adaptive streaming, and VideoPlayer component.
  Use when implementing media playback in a Vega application.
  
version: "1.0.0"
tags: ["vega", "media-player", "video", "drm", "playback", "w3c-media"]
---

# Media Player

## Prerequisites

This skill requires the `amazon-devices-buildertools-mcp` MCP server. Install the MCP server in your AI agent's MCP configuration. Example:

    {
      "amazon-devices-buildertools-mcp": {
        "command": "npx",
        "args": ["-y", "@amazon-devices/amazon-devices-buildertools-mcp@latest"]
      }
    }

## Overview

Vega uses the W3C MSE/EME standard for media playback — not ExoPlayer or platform-specific players. The `VideoPlayer` component from `@amazon-devices/react-native-w3cmedia` implements the W3C HTMLMediaElement interface with two playback modes:

- **URL mode** — for MP4/MP3 flat files, basic playback
- **MSE mode** — for adaptive streaming (HLS/DASH), DRM content, Shaka Player integration

## Core Concepts

- Media playback uses `VideoPlayer` and `KeplerVideoView` from `@amazon-devices/react-native-w3cmedia`
- DRM requires both `com.amazon.drm.key` and `com.amazon.drm.crypto` services in manifest.toml
- Manifest.toml must declare media services under `[wants]` — missing services cause silent playback failures
- Always handle `MEDIA_ERR_*` error codes from the HTMLMediaElement interface
- Babel config must enable automatic JSX runtime with `@babel/plugin-transform-react-jsx`

## Common Mistakes

| Problem | Fix |
|---|---|
| No video output, no errors | Missing media services in manifest.toml `[wants]` section |
| DRM content fails to play | Add both `com.amazon.drm.key` and `com.amazon.drm.crypto` services |
| Using ExoPlayer or react-native-video | Vega uses W3C standard — use `@amazon-devices/react-native-w3cmedia` |
| Video keeps playing after navigating away | Pause and reset in useEffect cleanup: `video.current.pause()` |

Use `amazon-devices-buildertools-mcp:search_documentation` to find troubleshooting guides and learn more about any topic.

## Workflow

1. Use `amazon-devices-buildertools-mcp:read_document` to read `react_native_for_vega_media_player.md` for the complete implementation guide
2. Use `amazon-devices-buildertools-mcp:list_documents` to discover related media docs (DRM setup, EME architecture, media best practices)
3. Use `amazon-devices-buildertools-mcp:search_documentation` to find specific media topics

## Dependencies

Tools used from `amazon-devices-buildertools-mcp`:
- `amazon-devices-buildertools-mcp:read_document`
- `amazon-devices-buildertools-mcp:list_documents`
- `amazon-devices-buildertools-mcp:search_documentation`
