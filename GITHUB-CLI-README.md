# GitHub CLI (gh) Auth Maintenance

Quick reference for keeping `gh` authenticated on this machine.

## Symptoms

`gh` or `git` operations fail with:

```
HTTP 401: Bad credentials (https://api.github.com/graphql)
Try authenticating with: gh auth refresh -h github.com
```

## Diagnosis

```bash
gh auth status
```

Look for: `The token in keyring is invalid.`

## Fix

### Quick refresh (if token is still valid)

```bash
gh auth refresh -h github.com
```

### Re-auth via device flow (when browser can't open from the terminal)

```bash
# 1. Get a one-time code
curl -s -X POST https://github.com/login/device/code \
  -H "Accept: application/json" \
  -d "client_id=178c6fc778ccc68e1d6a" \
  -d "scope=repo%20read:org%20workflow%20gist"

# 2. Open https://github.com/login/device in a browser and enter the code

# 3. When authorized, exchange the device_code for a token
curl -s -X POST https://github.com/login/oauth/access_token \
  -H "Accept: application/json" \
  -d "client_id=178c6fc778ccc68e1d6a" \
  -d "device_code=YOUR_DEVICE_CODE" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:device_code"

# 4. Feed the returned token to gh
echo "gho_YOUR_TOKEN" | gh auth login --hostname github.com --with-token
```

## Verify

```bash
gh auth status
# Look for: ✓ Logged in to github.com account <user> (keyring)
```

## Notes

- `gh` OAuth tokens do **not** expire on a timer. The 401 usually means the
  token was revoked on github.com or the macOS keyring entry went stale.
- The browser device flow works even when the shell can't open a browser;
  the verification URL can be opened on any device.