;; Official GNU Guix channel with its authenticated introduction.
;; These values are the upstream Guix channel trust anchor.
(list
 (channel
  (name 'guix)
  (url "https://git.savannah.gnu.org/git/guix.git")
  (branch "master")
  (introduction
   (make-channel-introduction
    "87a40d7203a813921b3ef0805c2b46c0026d6c31"
    (openpgp-fingerprint
     "BBB0 2DDF 2CEA F6A8 0D1D E643 A2A0 6DF2 A33A 54FA")))))
