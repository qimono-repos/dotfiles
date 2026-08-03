# stow-source/vega/mcp — Amazon Vega MCP server files

**Status:** pointer package (feedback F10).

## Official docs

Amazon Vega MCP Server (SDK 0.23 docs):

https://developer.amazon.com/docs/vega/0.23/mcp-server.html

## Intent

Keep Model Context Protocol config for Vega/Kepler agents next to this machine pack so Grok/Cursor/VS Code MCP clients can point at a stable path under `$HOME` after stow.

## Suggested layout (when implemented)

```text
stow-source/vega/mcp/
  README.md                 # this file
  # after stow, e.g.:
  # ~/.config/vega/mcp/… or ~/.vega/mcp/…
```

Local SDK on this host already lives under `~/vega` (not stowed). MCP JSON/command entries should reference that SDK without hardcoding other users’ homes when possible (`$HOME/vega/...`).

## Next steps

1. Read Amazon MCP server doc; note required Node/CLI versions.  
2. Add a sample `mcp.json` fragment for VS Code / Grok-compatible clients.  
3. Wire stow target path once the Amazon layout is confirmed.
