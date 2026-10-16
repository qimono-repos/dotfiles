;; Full user profile for qi-mini-pc-ubu-rr — THE only safe -m file.
;;
;;   guix package -m guix/manifests/profile-full.scm
;;
;; CRITICAL:
;;   `guix package -m FILE` installs *exactly* these packages (replaces the
;;   previous generation). Keep this list complete.
;;   Yoga already wiped emacs/uv/stow with a rust-only -m. Do not repeat that.
;;
;; Day-1 quantum workstation: Python + uv + Jupyter + native libs for wheels.
;; Functional stack: JVM Clojure on the Java 21 LTS toolchain.
;; Browsers / rust / kdeconnect stay off this list until deliberately added.
;;
;; Flatpak: Guix-owned *client* only. Apps live in ~/.local/share/flatpak
;; (user remotes). Do not apt install a second flatpak.

(specifications->manifest
 (list
  ;; Already on this host — must stay listed
  "emacs"
  "stow"
  "blender"
  "bat"

  ;; Functional programming toolchain: use the JDK output, not only default out
  "openjdk@21:jdk"
  "clojure"
  "clojure-tools"

  ;; Developer toolchain (Guix python wins PATH; apt python stays for the OS)
  "python@3.12"
  "uv"
  "jupyter"

  ;; Native bits NumPy / Aer wheels still dlopen
  "gcc-toolchain"
  "zlib"
  "openssl"
  "pkg-config"
  "glibc-locales"

  ;; Desktop escape hatch (Flathub user remotes). See docs/flatpak-guix.md.
  "flatpak"
  ))
