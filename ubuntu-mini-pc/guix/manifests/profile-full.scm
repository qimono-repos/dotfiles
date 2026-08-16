;; Full user profile for qi-mini-pc-ubu-rr — THE only safe -m file.
;;
;;   guix package -m guix/manifests/profile-full.scm
;;
;; CRITICAL:
;;   `guix package -m FILE` installs *exactly* these packages (replaces the
;;   previous generation). Keep this list complete.
;;   Yoga already wiped emacs/uv/stow with a rust-only -m. Do not repeat that.
;;
;; Day-1 quantum workstation: python + uv + jupyter + native libs for wheels.
;; Browsers / rust / kdeconnect stay off this list until deliberately added.

(specifications->manifest
 (list
  ;; Already on this host — must stay listed
  "emacs"
  "stow"

  ;; Developer toolchain (Guix python wins PATH; apt python stays for the OS)
  "python"
  "uv"
  "jupyter"

  ;; Native bits NumPy / Aer wheels still dlopen
  "gcc-toolchain"
  "zlib"
  "openssl"
  "pkg-config"
  "glibc-locales"
  ))
