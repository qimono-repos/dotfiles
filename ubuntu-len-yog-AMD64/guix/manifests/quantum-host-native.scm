;; Optional native scientific build deps (heavier)
;;   guix package -m guix/manifests/quantum-host-native.scm
;;
;; Skip on 6.5GiB machines unless you are compiling extensions.

(specifications->manifest
 (list
  "gcc-toolchain"
  "gfortran-toolchain"
  "cmake"
  "make"
  "pkg-config"
  "openblas"
  "lapack"
  "fftw"
  "hdf5"
  "libpng"
  "freetype"
  "openssl"
  "zlib"
  "bzip2"
  "xz"
  "glibc-locales"))
