;; Guix user profile: core dev tools for ubuntu-len-yog-AMD64
;; Apply:
;;   guix package -m guix/manifests/base.scm
;;
;; Keep this list lean (host has ~6.5GiB RAM). Heavy native build
;; deps live in quantum-host.scm.
;; Ranking: Guix is package manager #1 for userland.

(specifications->manifest
 (list
  ;; Dotfiles + Python toolchain (required for this pack)
  "stow"
  "python"
  "uv"

  ;; Everyday CLI (safe to re-declare if already installed)
  "git"
  "curl"
  "wget"
  "ripgrep"
  "fd"
  "fzf"
  "tree"
  "htop"
  "neovim"

  ;; Locales (Guix on foreign distro)
  "glibc-locales"))
