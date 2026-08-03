;; Host-side Guix packages that help quantum / scientific Python.
;; Does NOT install Qiskit/PennyLane (those are uv/PyPI).
;;
;;   guix package -m guix/manifests/quantum-host.scm
;;
;; Can be combined with base.scm by installing both manifests over time,
;; or merge lists into one profile generation.

(specifications->manifest
 (list
  "python"
  "uv"
  "stow"

  ;; Useful when building or debugging native extensions
  "gcc-toolchain"
  "gfortran-toolchain"
  "pkg-config"
  "cmake"
  "make"
  "openblas"
  "lapack"
  "fftw"
  "hdf5"
  "openssl"
  "zlib"
  "bzip2"
  "xz"
  "libpng"
  "freetype"

  "git"
  "ripgrep"
  "glibc-locales"))
