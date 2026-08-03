;; Guix user profile: core tools for ubuntu-len-yog-AMD64
;; Apply:  guix package -m guix/manifests/base.scm
;;
;; Ranking is aspirational (see docs/package-managers.md).
;; Browsers (firefox, epiphany, ungoogled-chromium) often need
;; nonguix / community channels — install only after guix pull with channels.scm.
;; Keep this list lean (~6.5GiB RAM host).

(specifications->manifest
 (list
  ;; Dotfiles + Python toolchain
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

  ;; Phone as laptop extension (Ying-Yang 2026+)
  "kdeconnect"

  ;; Browsers — prefer Guix over snap when substitutes work.
  ;; Uncomment after channels provide them on this pull:
  ;; "firefox"
  ;; "epiphany"           ; GNOME Web
  ;; "ungoogled-chromium" ; or chromium via nonguix
  ))
