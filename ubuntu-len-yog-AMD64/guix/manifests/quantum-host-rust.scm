;; Minimal Guix slice: Rust only (safer first step on low-RAM hosts)
;;   guix package -m guix/manifests/quantum-host-rust.scm

(specifications->manifest
 (list
  "rust"
  "rust:cargo"
  "pkg-config"
  "openssl"
  "zlib"
  "glibc-locales"))
