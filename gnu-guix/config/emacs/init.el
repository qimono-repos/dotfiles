(setq inhibit-startup-message t)


(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(set-fringe-mode 10)

(menu-bar-mode -1)

(setq visible-bell t)

(set-face-attribute 'default nil :font "Caskaydia Cove Nerd Font" :height 130)

;;(load-theme 'tango-dark)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
			 ("org" . "https://orgmode.org/elpa/")
			 ("elpa" . "https://elpa.gnu.org/packages/")
			 ))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(column-number-mode)
(global-display-line-numbers-mode 1)

(dolist (mode '(org-mode-hook
		term-mode-hook
		shell-mode-hook
		eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;;(use-package command-log-mode)

(use-package counsel
  :ensure t
  :config
  (counsel-mode 1)
  )

(use-package ivy
  :diminish
  :bind (("C-s" . swiper)
	 :map ivy-minibuffer-map
	 ("TAB" . ivy-alt-done)
	 ("C-l" . ivy-alt-done)
	 ("C-j" . ivy-next-line)
	 ("C-k" . ivy-previous-line)
	 :map ivy-switch-buffer-map
	 ("C-k" . ivy-previous-line)
	 ("C-l" . ivy-done)
	 ("C-d" . ivy-switch-fuffer-kill)
	 :map ivy-reverse-i-search-map
	 ("C-k" . ivy-previous-line)
	 ("C-d" . ivy-reverse-search-kill)

	 )
  :config
  (ivy-mode 1))

(global-set-key (kbd "C-<tab>") 'counsel-switch-buffer)

(use-package all-the-icons)

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

(use-package doom-themes
  :init
  (load-theme 'doom-nord t))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 2.5))

(setq initial-frame-alist
      '((top . 80)    ; sets the initial position on the top
        (left . 0)   ; sets the initial position on the left
        (width . 100) ; sets the width in characters
        (height . 50) ; sets the height in lines
       ))

(use-package evil
  :config
  (evil-mode 1))

(use-package treemacs
  :ensure t
  :bind
  (:map global-map
	("M-1" . treemacs)
	)
  :config
  (setq treemacs-is-never-other-window t
	treemacs-position 'right)
  :defer t
  :init
  )
(use-package treemacs-evil
  :after (treemacs evil)
  :ensure t)

(defun close-treemacs-on-buffer-change ()
  "Closes the Treemacs buffer if another buffer is selected."
  (when (and (buffer-p) (not (equal (current-buffer) treemacs-buffer)))
    (delete-buffer treemacs-buffer)))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (lsp-enable-which-key-integration 1))
