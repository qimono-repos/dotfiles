(setq inhibit-startup-message t)       

(setq straight-base-dir (expand-file-name "/root/.emacs.d/straight/"))
(load (expand-file-name "/root/.emacs.d/straight/repos/straight.el/straight.el"))

;;(setq straight-base-dir (expand-file-name "~/.emacs.d/straight/"))
;;(load (expand-file-name "~/.emacs.d/straight/repos/straight.el/straight.el"))

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t)


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

;;(setq initial-frame-alist
;;      '((top . 80)    ; sets the initial position on the top
;;        (left . 0)   ; sets the initial position on the left
;;        (width . 100) ; sets the width in characters
;;        (height . 50) ; sets the height in lines
;;       ))

(use-package evil
  :config
  (evil-mode 1))

(use-package copilot
  :straight (:host github :repo "copilot-emacs/copilot.el" :files ("dist" "*.el"))
  :ensure t
  :after evil
  :hook (prog-mode . copilot-mode)
  :config
  (setq copilot-node-executable "/usr/bin/node")
  (setq copilot-server-executable "/usr/local/bin/copilot-language-server")
  (setq copilot-enable-ssl-verify t))

(defun my/copilot-tab ()
  (interactive)
  (message "my/copilot-tab called: Copilot completion %s, falling back to indent" (if (copilot-accept-completion) "accepted" "not accepted"))
  (if (copilot-accept-completion)
      t
    (indent-for-tab-command)))
;;  (if (copilot-accept-completion nil t)
;;     t
;;    (indent-for-tab-command)))

(with-eval-after-load 'copilot
  (define-key copilot-mode-map (kbd "<tab>") 'my/copilot-tab)
  (define-key copilot-mode-map (kbd "TAB") 'my/copilot-tab)
  (define-key copilot-mode-map (kbd "C-<tab>") 'copilot-accept-completion-by-word)
  (define-key copilot-mode-map (kbd "C-S-<tab>") 'copilot-previous-completion))

(with-eval-after-load 'evil
  (define-key evil-insert-state-map (kbd "<tab>") 'my/copilot-tab)
  (define-key evil-motion-state-map (kbd "<tab>") 'my/copilot-tab))



(use-package treemacs
  :ensure t
  :bind
  (:map global-map
	("M-;" . treemacs)
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
  :ensure t
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (lsp-enable-which-key-integration 1)
;;  (use-package csharp-mode :ensure t :hook (csharp-mode . lsp-deferred) :config (setq csharp-format-on-save t))
;;  (use-package omnisharp :ensure t :config (setq omnisharp-server-use-studio t))
  (add-hook 'typescript-mode 'lsp-deferred)
  (add-hook 'js-mode 'lsp-deferred)
  (add-hook 'js-jsx-mode 'lsp-deferred))
 

(use-package company :ensure t :config
  (add-hook 'csharp-mode-hook 'company-mode))


(setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))

(setq copilot-server-executable "~/.emacs.d/.cache/copilot/bin/copilot-language-server")

;;(use-package copilot
;;  :straight (:host github :repo "copilot-emacs/copilot.el" :files ("dist" "*.el"))
;;  :ensure t
;;  :after evil
;;  :hook (prog-mode . copilot-mode)
;;  :config
;;  (setq copilot-node-executable "/usr/bin/node")
;;  (setq copilot-server-executable "/usr/local/bin/copilot-language-server")
;;  (setq copilot-enable-ssl-verify t))

;;(defun my/copilot-tab ()
;;  (interactive)
;;  (if (and (boundp 'copilot--completion-overlay) (overlayp copilot--completion-overlay))
;;      (copilot-accept-completion)
;;    (indent-for-tab-command)))

;;(defun my/copilot-tab ()
;;  (interactive)
;;  (if (and (boundp 'copilot--completion-overlay) (overlayp copilot--completion-overlay))
;;      (copilot-accept-completion)
;;    (company-indent-or-complete-common nil)))

;;(defun my/copilot-tab ()
;;  (interactive)
;;  (if (copilot--overlay-visible-p)
;;      (copilot-accept-completion)
;;    (company-indent-or-complete-common nil)))

;;(defun my/copilot-tab ()
;;  (interactive)
;;  (if (company--active-p)
;;      (company-complete-common)
;;    (if (copilot--overlay-visible-p)
;;        (copilot-accept-completion)
;;      (indent-for-tab-command))))

;;(with-eval-after-load 'copilot
;;  (define-key copilot-mode-map (kbd "<tab>") 'my/copilot-tab)
;;  (define-key copilot-mode-map (kbd "TAB") 'my/copilot-tab)
;;  (define-key copilot-mode-map (kbd "C-<tab>") 'copilot-accept-completion-by-word)
;;  (define-key copilot-mode-map (kbd "C-S-<tab>") 'copilot-previous-completion))

;;(with-eval-after-load 'evil
;;  (define-key evil-insert-state-map (kbd "<tab>") 'my/copilot-tab)
;;  (define-key evil-motion-state-map (kbd "<tab>") 'my/copilot-tab))
;;(with-eval-after-load 'evil
;;  (define-key evil-insert-state-map (kbd "<tab>") 'my/copilot-tab))

;;(add-hook 'csharp-mode-hook 'copilot-mode)

