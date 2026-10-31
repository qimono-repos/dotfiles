;;; init.el --- Minimal Evil-mode configuration for the VPS -*- lexical-binding: t; -*-

;; Evil is installed from Ubuntu's elpa-evil package. Keep Emacs startup light;
;; this is a terminal-friendly alternative editor, not a full desktop setup.
(require 'evil)
(evil-mode 1)

(setq inhibit-startup-screen t
      ring-bell-function #'ignore
      make-backup-files t
      backup-directory-alist `(("." . "~/.cache/emacs/backups/"))
      auto-save-file-name-transforms `((".*" "~/.cache/emacs/autosave/" t)))

(when (not (display-graphic-p))
  (xterm-mouse-mode 1))

;;; init.el ends here
