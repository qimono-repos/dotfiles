;; QIMONO-VI-WENDY-CHANNELS-VERSION: v1.0.0
;; Authenticated Nonguix channel + official Guix channels.
;; Introduction and fingerprint: Nonguix upstream README.
(cons*
  (channel
    (name 'nonguix)
    (url "https://gitlab.com/nonguix/nonguix")
    (introduction
      (make-channel-introduction
        "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
        (openpgp-fingerprint
          "2A39 3FFF 68F4 EF7A 3D29 12AF 6F51 20A0 22FB B2D5"))))
  %default-channels)
