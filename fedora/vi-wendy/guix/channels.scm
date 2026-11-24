;; QIMONO-VI-WENDY-CHANNELS-VERSION: v1.1.0
;; Authenticated Guix + Nonguix channels.
;;
;; Guix moved its primary Git repository to Codeberg in May 2025.
;; The Guix 1.5.0 live installer still defaults to the old Savannah URL,
;; which now redirects and fails in its bundled Git library.
;; Inherit the official Guix channel's trusted introduction, changing URL only.
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
