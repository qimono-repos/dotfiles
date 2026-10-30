;; Complete, intentionally small VPS profile.
;; Applied as a full profile generation: keep every desired package here.
;; Use package specifications supported by the active Guix generation.
(use-modules (gnu packages build-tools))

(specifications->manifest
 (list
  ;; Daily CLI and dotfiles
  "git"
  "neovim"
  "ripgrep"
  "fd"
  "fzf"
  "tree"
  "htop"
  "jq"
  "yq"
  "tmux"
  "stow"
  ;; Build and application tooling
  (package-name uv)
  "gradle"
  "pkg-config"
  "openssl"
  "zlib"
  "make"
  "gcc-toolchain"
  ;; Useful inspection / archive tools
  "file"
  "unzip"
  "xz"
  "which"
  "curl"
  "wget"
  "nss-certs"
  "glibc-locales"))
