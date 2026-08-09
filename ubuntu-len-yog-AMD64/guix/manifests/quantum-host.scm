;; quantum-host.scm — Guix profile pieces for quantum / scientific host work
;;
;; Apply (may download a lot; prefer on AC power, free RAM):
;;   guix package -m guix/manifests/quantum-host.scm
;;
;; Layered apply (recommended on 6.5GiB machines):
;;   guix package -m guix/manifests/quantum-host-rust.scm
;;   # then optionally:
;;   guix package -m guix/manifests/quantum-host-native.scm
;;   guix package -u nix   # or include nix carefully
;;
;; Design (Ying-Yang feedback F7):
;;   - Rust: Guix-first (this file + quantum-host-rust.scm).
;;   - .NET 10: NOT provided by Guix package name "dotnet" on this channel set.
;;     Use host Microsoft SDK (already on this Yoga), official tarball, Nix, or
;;     podman — documented in docs/quantum-host-dotnet-rust.md.
;;   - Nix: Guix can install package "nix" as escape hatch (optional line below).
;;   - Qiskit / PennyLane / qdk: uv project only — never Guix python-qiskit.
;;
;; This combined file is the "full intent" manifest. Prefer the split files
;; if substitutes thrash memory.

(specifications->manifest
 (list
  ;; Shared with base
  "python"
  "uv"
  "stow"
  "jupyter"   ; Notebook UI; Qiskit/PennyLane remain in the uv project
  "git"
  "glibc-locales"
  "pkg-config"
  "openssl"
  "zlib"

  ;; Rust toolchain (compiler + cargo output)
  "rust"
  "rust:cargo"

  ;; Light native stack for scientific wheels / debugging
  "cmake"
  "make"
  "openblas"

  ;; Escape hatch PM (optional — uncomment if you want nix in the same generation)
  ;; "nix"

  ;; Editors already in base.scm — re-list only if installing this manifest alone
  ;; "emacs"
  ;; "neovim"
  ))
