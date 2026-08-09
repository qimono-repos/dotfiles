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

  ;; Dotfiles + Python + uv + Jupyter Notebook (UI; quantum libs stay in uv)
  "stow"
  "python"
  "uv"
  "jupyter"

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

  ;; Browsers — FIRST TRY use scripts/setup-guix-browsers-first-try.sh
  ;; Prerequisites (once per machine):
  ;;   1. guix pull with nonguix (channels.scm)
  ;;   2. PATH → ~/.config/guix/current/bin/guix  (not /usr/local/bin/guix)
  ;;   3. ./scripts/setup-guix-browser-prereqs.sh  (userns=0 + nonguix key)
  ;;   4. Always pass: --substitute-urls='https://substitutes.nonguix.org …'
  ;;   5. Never source-build Firefox on low disk/RAM (see docs/LESSONS-guix-browsers.md)
  "epiphany"
  "firefox"
  ;; Optional extra:
  ;; "ungoogled-chromium"

  ;; Diagrams (optional — uncomment when needed)
  ;; "graphviz"
  ;; "plantuml"
  ))
