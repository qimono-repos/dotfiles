;; Full user profile for this laptop — PREFERRED install path.
;;
;;   guix package -m guix/manifests/profile-full.scm
;;
;; CRITICAL:
;;   `guix package -m FILE` installs *exactly* these packages (replaces the
;;   previous profile generation's package set). Keep this list complete.
;;   Do NOT run a partial manifest (e.g. rust-only) unless you mean to slim down.
;;
;; Hierarchy:
;;   1. PREFERRED  → this file (profile-full.scm)
;;   2. LAST RESORT → scripts/installing-daily-use-apps.sh  (guix install …)
;;
;; Edit this list when you permanently want a new daily app, then re-apply -m.
;; Optional / heavy packages stay commented; enable deliberately.

(specifications->manifest
 (list
  ;; Editors & core CLI
  "neovim"
  "emacs"
  "vscodium"
  "git"
  "ripgrep"
  "fd"
  "fzf"
  "tree"
  "htop"
  "openjdk"

  ;; Dotfiles + Python + uv (quantum libs + JupyterLab stay in the uv workspace:
  ;; the monolithic Guix `jupyter` package does NOT support aarch64-linux).
  "stow"
  "python"
  "uv"

   ;; Locales / small libs
   "glibc-locales"
   "pkg-config"
   "openssl"
   "zlib"
   "tree-sitter"

  ;; Rust (quantum-host)
  "rust"
  "rust:cargo"

  ;; Phone as laptop extension
  "kdeconnect"

  ;; Terminal — Ghostty installed via the saayix external channel (guix
  ;; upstream & nonguix do NOT carry it). See guix/channels.scm.
  "ghostty"

  ;; Caskaydia Cove Nerd Font (saayix) — console/app font; autostarted Ghostty.
  ;; Bare TTY fonts are managed separately via /etc/vconsole.conf (Terminus).
  "font-nerd-caskaydia"

  ;; Desktop escape hatch — Guix-owned *client* only; apps from Flathub
  ;; user remotes. See ubuntu-mini-pc/docs/flatpak-guix.md.
  "flatpak"

  ;; Desktop GUI apps — discoverable in the GNOME overview / Super search
  ;; once the session XDG_DATA_DIRS carries ${HOME}/.guix-profile/share
  ;; (see stow-source/shell/.config/environment.d/10-qimono-flatpak.conf).
  "gimp"

  ;; Browsers — ARM64 policy: Guix `firefox` has NO aarch64 substitute; NEVER
  ;; source-build it here (many hours, fails on default toolchain). Firefox
  ;; comes from snap: scripts/install-browser.sh. Epiphany IS
  ;; substitute-served on aarch64 and stays in the profile.
  ;; Prereqs for epiphany: post-pull guix with nonguix (channels.scm) +
  ;; kernel.apparmor_restrict_unprivileged_userns=0 (see docs/LESSONS-guix-browsers.md).
  "epiphany"
  ;; Optional browser (nonguix, substitute-served on x86_64):
  ;; "ungoogled-chromium"

  ;; Diagrams (optional — uncomment when needed)
  ;; "graphviz"
  ;; "plantuml"
  ))
