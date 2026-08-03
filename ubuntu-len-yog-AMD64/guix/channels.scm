;; channels.scm — Guix channels for this pack / machine
;; Stow also links a copy via stow-source/guix-env → ~/.config/guix/channels.scm
;;
;; We rely on channels for ALL Guix-related work (stage 1 → Guix System).
;; nonguix: firmware, some browsers, nonfree-adjacent packages.
;; Community / educational referent: David Wilson (System Crafters) for
;; Emacs + Guix workflow patterns — add explicit channel URLs here only when
;; you pin a channel you actually use (avoid cargo-cult empty channels).

(cons* (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix")
        (introduction
         (make-channel-introduction
          "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
          (openpgp-fingerprint
           "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
       %default-channels)
