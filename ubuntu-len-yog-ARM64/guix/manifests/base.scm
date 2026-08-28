;; Guix user profile: core tools for ubuntu-len-yog-ARM64 (aarch64-linux)
;; Apply:  guix package -m guix/manifests/base.scm
;;
;; Ranking is aspirational (see docs/package-managers.md).
;; Browsers (firefox, epiphany, ungoogled-chromium) often need nonguix /
;; community channels — install only after guix pull with channels.scm.
;;
;; NOTE (aarch64): the monolithic `jupyter` Guix package does NOT support
;; aarch64-linux. JupyterLab is instead provided via `uv` in the quantum
;; workspace (`QIMONO_QUANTUM_HOME`). See docs/jupyter-arm64.md.

(specifications->manifest
 (list
  ;; Dotfiles + Python toolchain  (JupyterLab via uv, not Guix jupyter)
  "stow"
  "python"
  "uv"

  ;; Editors (shared configs via stow-source later)
  "emacs"
  "neovim"

  ;; Everyday CLI
  "git"
  "curl"
  "wget"
  "ripgrep"
  "fd"
  "fzf"
  "tree"
  "htop"

  ;; Locales (Guix on foreign distro)
  "glibc-locales"

  ;; zlib — compiled wheels (scipy-openblas/numpy) dlopen libz.so.1 at runtime.
  ;; On a foreign distro running the Guix python the host /lib/aarch64-linux-gnu
  ;; must NOT be added to LD_LIBRARY_PATH (segfaults the Guix python). Instead
  ;; we expose the Guix zlib lib dir via the profile: see shell/20-uv-python.zsh.
  "zlib"

  ;; Phone as laptop extension (Ying-Yang 2026+)
  "kdeconnect"

  ;; Browser NOTE (aarch64): Guix `firefox` has NO aarch64 substitute and would
  ;; be a multi-hour source build (see LESSONS-guix-browsers.md — never
  ;; source-build Firefox). This pack therefore installs Firefox via snap
  ;; (native ARM) — see scripts/install-browser.sh. It is never autostarted;
  ;; only Ghostty launches at login. Firefox is NOT a Guix profile package here.

  ;; Terminal — native Guix Ghostty via the saayix external channel. This is
  ;; the machine's console app; macOS/GNOME-autostarted (see startup-login.sh).
  "ghostty"

  ;; Caskaydia Cove Nerd Font (saayix) — GUI (Ghostty) + app font. TTY console
  ;; fonts are separate (Terminus Bold via apt /etc/vconsole.conf).
  "font-nerd-caskaydia"

  ;; Preserved manual install — keep in the single authoritative manifest so a
  ;; `-m` re-apply does not drop it (per repo "full manifest" policy).
  "blender"
  ))
