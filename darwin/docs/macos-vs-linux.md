# macOS vs Linux — the honest one-to-one (for the darwin pack)

You said it feels "uncanny similar." It is — ~90% of shell/scripts/perms/repos
transfer directly. This doc pins the 10% that differs, so you stop guessing.

## The file permissions question (you asked)

**chmod works identically.** macOS is BSD Unix; `chmod +x`, `755`, `a+rx`,
file mode bits, and the "a script must be executable to run" rule are exactly
Linux. Only cosmetic difference: `ls -G` (BSD color) vs `ls --color` (GNU) —
already OS-guarded in the darwin `.zshrc`.

## Side-by-side

| Concept | Linux (Ubuntu) | macOS | Same? |
|---------|---------------|-------|-------|
| Shell | bash/zsh | zsh (login) | ✔ yes |
| coreutils | GNU | BSD | ⚠ mostly (flags differ) |
| Package mgr | apt (system) | **Homebrew** (user) | yes-ish |
| Init / services | **systemd** | **launchd** | ✖ no |
| Users | `/etc/passwd`, uid 1000 | `/etc/passwd`, unique uid | ✔ yes |
| Home | `/home/qi` | `/Users/qi` | ✔ yes |
| Desktop | GNOME/Wayland | Aqua/WindowServer | ✖ no |
| App bundle | split bins/libs | `/Applications/X.app` | ✖ no |
| Data dirs | XDG `~/.cache` `~/.config` | **`~/Library/{Caches,Application Support,Preferences}`** | ✖ no |
| FS | ext4 (case-sensitive) | **APFS (case-insensitive)** | ⚠ mostly |

## Notes on the ⚠/✖ rows

- **BSD vs GNU coreutils** — the flags you use daily mostly match, but these
  differ and WILL bite: `sed -i` needs `sed -i ''` on macOS; `ls -G`; `du`/`find`
  args; `readlink` (`readlink -f` missing — use `greadlink` from coreutils, or
  python). `brew install coreutils` gives you the GNU tools prefixed `g` (`gsed`,
  `gfind`, ...) if you want exact Linux behavior.
- **launchd vs systemd** — see `launchd.md`. Same job, different tool.
- **~/Library replaces XDG** — this is the "no real one-to-one." Apps put state
  in `~/Library/{Caches,Application Support,Preferences}`; `/Library` = system;
  caches are the #1 disk-reclaim target (see `disk-audit.sh`).
- **App bundles** — one `.app` folder per application (binary + libs + plist);
  vs Linux's scattered bin/lib/share.
- **Homebrew is the deliberate bridge** — because a system package manager in
  the traditional sense doesn't exist on macOS, Homebrew gives you the
  user-level, git-reviewable install that apt gives you system-wide on Ubuntu.
  That's why it's rank #1 in the darwin pack.

## The habit that transfers best

Your Linux shell habits (aliases, zshrc, stow, tmux, git, SSH) are 100%
portable — that's the whole why-behind the darwin `stow-source/shell`. The
things to unlearn are only: services (launchd), data locations (`~/Library`),
and GNU-vs-BSD flags.