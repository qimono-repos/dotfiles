;; Complete, intentionally small VPS profile.
;; Applied as a full profile generation: keep every desired package here.
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
  "(@ (gnu packages build-tools) uv)"
  "gradle"
  "pkg-config"
  "openssl"
  "zlib"
  "make"
  "gcc-toolchain"
  ;; Useful inspection / archive tools
  ;; nss-certs provides the CA certificate bundle on Guix.
  "file"
  "unzip"
  "xz"
  "which"
  "curl"
  "wget"
  "nss-certs"
  "glibc-locales"))
