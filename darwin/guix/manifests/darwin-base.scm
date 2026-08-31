;; Guix user profile for the container machine (qi-dev, Debian/linux).
;; Apply INSIDE the machine:  guix package -m guix/manifests/darwin-base.scm
;; This mirrors ubuntu-len-yog-ARM64/guix/manifests/base.scm minus the
;; Ubuntu/ARM64-specific notes (kdeconnect, drivers). The Debian base provides
;; glibc/apt tooling; Guix supplies the userland daily driver.
;;
;; NOTE: browsers (firefox etc.) prefer nonguix; firefox has no aarch64
;; substitute and would be a multi-hour source build (LESSONS-guix-browsers) —
;; install Firefox from the Debian base (`apt install firefox-esr`) instead.

(specifications->manifest
 (list
  ;; Dotfiles + shell tooling
  "stow"
  "git"
  "curl"
  "wget"
  "ripgrep"
  "fd"
  "fzf"
  "tmux"
  "tree"
  "htop"

  ;; Editors
  "emacs"
  "neovim"

  ;; Languages / toolchains
  "python"
  "uv"

  ;; Locales for Guix prompts on the foreign distro
  "glibc-locales"
  ))  ; end list
;; NOTE: the Guix `ghostty` package needs the saayix external channel — not
;; wired in darwin/guix/channels.scm (only nonguix). On the Macs, Ghostty is a
;; brew cask on the HOST; inside the machine the terminal is whatever
;; $LOCAL-shell you launch from macOS. Add saayix here if the machine needs
;; its own ghostty.