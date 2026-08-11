;; Persisted Guix profile manifest — SINGLE SOURCE OF TRUTH for ~/.guix-profile.
;;
;; IMPORTANT: `guix package --manifest` makes the profile match this file
;; EXACTLY (it removes anything not listed). Keep every Guix-installed package
;; here. Currently: firefox + epiphany (browsers), jupyter, vscodium (IDE).
;;
;; vscodium notes: nonguix marks it #:substitutable? #f (never on
;; substitutes.nonguix.org), and its `install-license-files` phase crashes on
;; the release tarball (match-error in guix/build/gnu-build-system.scm). The
;; phase only copies a license into share/doc; VSCodium ships its LICENSE
;; inside the app. So we inherit vscodium and delete that phase. The build is
;; fast: it repackages the prebuilt GitHub release tarball (~90 MB).
;;
;; Wired into scripts/20-guix-pull-channels.sh (idempotent).
(use-modules (guix packages)
             (guix profiles)
             (guix utils)
             (gnu packages)
             (nongnu packages editors))

(define vscodium-fixed
  (package
    (inherit vscodium)
    (arguments
     (substitute-keyword-arguments (package-arguments vscodium)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'install-license-files)))))))

(packages->manifest
 (cons vscodium-fixed
       (map specification->package '("firefox" "epiphany" "jupyter"))))
