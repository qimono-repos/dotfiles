# Substitute signing keys (public only)

| File | Use |
|------|-----|
| `nonguix-signing-key.pub` | Authorize Firefox substitutes from `https://substitutes.nonguix.org` |

Public keys only — never put private keys here.

Source of truth for nonguix key:
https://substitutes.nonguix.org/signing-key.pub

`scripts/30-browser-prereqs.sh` prefers the vendored file, then falls back to curl.
