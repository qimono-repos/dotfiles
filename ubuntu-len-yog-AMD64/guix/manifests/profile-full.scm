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
  "git"
  "ripgrep"
  "fd"
  "fzf"
  "tree"
  "htop"
  "openjdk"

  ;; Dotfiles + Python + uv
  "stow"
  "python"
  "uv"

  ;; Locales / small libs
  "glibc-locales"
  "pkg-config"
  "openssl"
  "zlib"

  ;; Rust (quantum-host)
  "rust"
  "rust:cargo"

  ;; Phone as laptop extension
  "kdeconnect"

  ;; Browsers (Guix + nonguix; no snap Firefox)
  "epiphany"
  "firefox"                 ; needs: sudo guix archive --authorize nonguix key
                            ; and substitutes.nonguix.org (see docs/guix-browsers-foreign-distro.md)
  ;; Optional extra:
  ;; "ungoogled-chromium"

  ;; Diagrams (optional — uncomment when needed)
  ;; "graphviz"
  ;; "plantuml"
  ))
