;; Complete, intentionally conservative VPS profile.
;; Applied as a full profile generation: keep every desired package here.
;; Only use package names verified as package specifications.
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
