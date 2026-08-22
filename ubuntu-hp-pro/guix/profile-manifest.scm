;; Persisted Guix profile manifest — SINGLE SOURCE OF TRUTH for ~/.guix-profile.
;;
;; IMPORTANT: `guix package --manifest` makes the profile match this file
;; EXACTLY (it removes anything not listed). Keep every Guix-installed package
;; here — never apply a partial manifest (Yoga lesson 2026-08-03: a rust-only
;; -m wiped the whole profile; recovery = reapply the full manifest).
;;
;; Fleet parity with ubuntu-len-yog-AMD64/guix/manifests/profile-full.scm
;; (ported 2026-08-22) PLUS hp-pro specifics:
;;   * vscodium-fixed (this pack's IDE; NOT in the Yoga manifest — do not lose it)
;;
;; vscodium notes: nonguix marks it #:substitutable? #f (never on
;; substitutes.nonguix.org), and its `install-license-files` phase crashes on
;; the release tarball (match-error in guix/build/gnu-build-system.scm). The
;; phase only copies a license into share/doc; VSCodium ships its LICENSE
;; inside the app. So we inherit vscodium and delete that phase. The build is
;; fast: it repackages the prebuilt GitHub release tarball (~90 MB).
;;
;; Wired into scripts/20-guix-pull-channels.sh (idempotent).
(use-modules (guix packages)
             (guix profiles)
             (guix utils)
             (gnu packages)
             (nongnu packages editors))

(define vscodium-fixed
  (package
    (inherit vscodium)
    (arguments
     (substitute-keyword-arguments (package-arguments vscodium)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'install-license-files)))))))

(define (pkg spec) (specification->package spec))

(packages->manifest
 (append
  ;; hp-pro specific (custom build) — keep first
  (list vscodium-fixed)

  ;; rust with the cargo output (packages->manifest accepts pkg+output tuples)
  (list (list (pkg "rust") "cargo"))

  ;; Editors & core CLI (Yoga parity)
  (map pkg
       (list "neovim"
             "emacs"
             "git"
             "ripgrep"
             "fd"
             "fzf"
             "tree"
             "htop"
             "openjdk"

             ;; Dotfiles + Python + uv + Jupyter Notebook
             ;; (quantum libs stay in the uv workspace, not here)
             "stow"
             "python"
             "uv"
             "jupyter"

             ;; Locales / small libs (foreign-distro must-haves)
             "glibc-locales"
             "pkg-config"
             "openssl"
             "zlib"
             "tree-sitter"

             ;; Phone as laptop extension (KDE Connect)
             "kdeconnect"

             ;; Desktop escape hatch — Guix-owned CLIENT only;
             ;; apps from user remotes (ghostty via adonm repo). See
             ;; ../ubuntu-mini-pc/docs/flatpak-guix.md for the pattern.
             "flatpak"

             ;; Browsers (nonguix substitutes; never source-build Firefox)
             "epiphany"
             "firefox"

             ;; Optional extras — enable deliberately:
             ;; "ungoogled-chromium"
             ;; "graphviz"
             ;; "plantuml"
             ))))
