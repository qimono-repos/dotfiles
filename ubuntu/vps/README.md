# ubuntu/vps — preferred VPS providers (Qimono)

This folder is for **VPS-oriented** Ubuntu notes (not the Lenovo Yoga laptop pack).  
Parent `dotfiles/ubuntu/` remains a **recopilation** of many old machines/VPS; this subfolder is the intentional VPS product surface for Ying-Yang infrastructure.

## Preferred providers (stage 1 shopping list)

| Provider | Why it is on the list | Typical use |
|----------|----------------------|-------------|
| **Hostinger** | Cost-effective VPS, simple UX | Small public endpoints, experiments |
| **AWS** | Breadth (EC2, IAM, global regions) | Production-shaped workloads, compliance paths |
| **Linode** (Akamai) | Transparent pricing, solid Linux docs; already in Qimono history | General VPS, Sydney/other regions |
| **Hetzner** | Strong EU price/perf, clean servers | Heavier backends, build agents |

Order is **not** a ranking of quality — pick by region, budget, and compliance.

## What belongs here later

- Provider-specific install scripts (apt minimal + podman)
- Firewall / SSH baselines
- Pointers to Guix-on-VPS experiments
- **Not** full Guix System yet (stage 1)

## Portable services note

Ubuntu VPS = **systemd**. Guix System later = **Shepherd** (Scheme).  
Design services as Podman (or documented intent) so they can move — see  
`ubuntu-len-yog-AMD64/docs/teach-inits-shepherd.md`.

## Related locations

| Path | Role |
|------|------|
| `dotfiles/ubuntu/` | Archive / multi-machine notes |
| `dotfiles/ubuntu-len-yog-AMD64/` | This entrepreneur’s AMD Yoga laptop pack |
| `dotfiles/ubuntu-mini-pc/` | Planned mini-PC pack (same Ying-Yang project) |
