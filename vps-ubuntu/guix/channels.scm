;; Keep the VPS on the official GNU Guix channel initially.
;; Additional channels (e.g. Nonguix) should be introduced only for a
;; concrete package requirement, with their signing keys explicitly reviewed.
(list
 (channel
  (name 'guix)
  (url "https://git.savannah.gnu.org/git/guix.git")
  (branch "master")))
