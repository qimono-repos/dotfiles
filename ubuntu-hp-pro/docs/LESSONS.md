# Lessons (shared with Yoga pack)

Full write-up lives in the proven pack:

**`../ubuntu-len-yog-AMD64/docs/LESSONS-guix-browsers.md`**

Critical five:

1. Post-pull guix: `~/.config/guix/current/bin/guix` ≠ `/usr/local/bin/guix`  
2. Epiphany needs `kernel.apparmor_restrict_unprivileged_userns=0`  
3. Firefox via **nonguix substitutes** + `guix archive --authorize`  
4. Prefer `guix install epiphany firefox` first try  
5. Never compile Firefox from source on a laptop if substitutes exist  
