;; QIMONO GUIX LOBBY: Nonguix channel manifest v1.1.0
;; In older Guix releases %default-channels may still use Savannah.
;; Override the official channel's URL with Codeberg while inheriting
;; its authenticated introduction. Nonguix introduction remains unchanged.
(cons
  (channel
    (name 'nonguix)
    (url "https://gitlab.com/nonguix/nonguix")
    (introduction
      (make-channel-introduction
        "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
        (openpgp-fingerprint
          "2A39 3FFF 68F4 EF7A 3D29 12AF 6F51 20A0 22FB B2D5"))))
  (map
    (lambda (upstream-channel)
      (if (eq? (channel-name upstream-channel) 'guix)
        (channel
          (inherit upstream-channel)
          (url "https://codeberg.org/guix/guix.git"))
        upstream-channel))
    %default-channels))
