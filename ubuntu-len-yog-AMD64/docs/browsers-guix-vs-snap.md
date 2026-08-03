# Browsers: Guix vs snap (P4.1–P4.3)

## Discovery (this channel set, 2026-08)

| Package | Guix name | Notes |
|---------|-----------|-------|
| Firefox | **not found** as `firefox` without extra channels / pull | Often **nonguix** or specialized channel |
| GNOME Web | **`epiphany`** | In Guix |
| Chromium | **`ungoogled-chromium`** (not `chromium`) | Large download |
| Snap Firefox | present on host | Ubuntu default path |
| Snap Epiphany / Vivaldi | present | Experiment candidates |

## Policy

1. Prefer Guix when substitutes exist and RAM allows.  
2. Install **one** Guix browser and smoke-test before removing snaps.  
3. Never remove all browsers in one step.  
4. Keep at least one working browser (Chrome `.deb` / Vivaldi / etc.) as safety net.

## Install attempts (record results in JOURNAL)

```bash
# lighter first
guix install epiphany
# heavy
guix install ungoogled-chromium
# firefox: guix pull with nonguix, then search again
guix search firefox | head
```

## Snap removal (only after Guix browser works)

**2026-08-03 (updated):** User removed snap **epiphany** and **vivaldi**.  
Guix **epiphany** (Web 48.0) remains the primary GNOME Web.

| Browser | Status now |
|---------|------------|
| Epiphany / GNOME Web | **Guix only** (snap gone) |
| Vivaldi | **removed** (snap) |
| Firefox | still **snap** (`firefox` 153) — safety net |
| Chromium | not installed (optional Guix `ungoogled-chromium`) |

```bash
snap list | grep -iE 'firefox|epiphany|vivaldi'
# only firefox should remain among those three
```

Do **not** remove snapd itself. Keep snap **firefox** until Guix Firefox or Chromium is verified.

### Verify Guix browser

```bash
source ~/.guix-profile/etc/profile
epiphany --version    # Web 48.0
epiphany &            # GUI smoke
```

### Do you need `guix pull`?

| Goal | Need pull? |
|------|------------|
| Keep using current epiphany / rust / uv | **No** (works now) |
| Security + newer package versions | **Yes**, occasionally |
| Install **Firefox** from Guix / nonguix | **Yes** — pull so channels.scm (nonguix) is active, then `guix search firefox` |
| `ungoogled-chromium` already found without pull | Optional; pull still refreshes hashes |

```bash
# when you choose to pull (network + time; low-RAM: close browsers)
guix pull
hash guix
guix describe
guix search firefox | head
```
