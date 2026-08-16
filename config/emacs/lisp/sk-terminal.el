;;; sk-terminal.el --- Terminal integration -*- lexical-binding: t; -*-

(require 'subr-x)

(use-package vterm
  :commands vterm
  :init
  (setq vterm-module-cmake-args "-DUSE_SYSTEM_LIBVTERM=Off"
        vterm-always-compile-module t)
  :config
  (setq vterm-shell (or (getenv "SK_EMACS_SHELL") (executable-find "fish") shell-file-name)
        vterm-max-scrollback 10000)
  (sk/load-theme)
  (add-hook 'vterm-mode-hook #'evil-insert-state)
  (add-hook 'vterm-mode-hook (lambda () (hl-line-mode -1)))
  (define-key vterm-mode-map (kbd "C-h") #'windmove-left)
  (define-key vterm-mode-map (kbd "C-j") #'windmove-down)
  (define-key vterm-mode-map (kbd "C-k") #'windmove-up)
  (define-key vterm-mode-map (kbd "C-l") #'windmove-right))

(defun sk/open-vterm ()
  "Open Vterm in the right utility panel."
  (interactive)
  (let ((buffer (save-window-excursion
                  (vterm)
                  (current-buffer))))
    (select-window (sk/display-buffer-right buffer 0.48))))

(defun sk/open-eshell ()
  "Open Eshell in the right utility panel."
  (interactive)
  (let ((buffer (save-window-excursion
                  (eshell)
                  (current-buffer))))
    (select-window (sk/display-buffer-right buffer 0.48))))

(defun sk/open-eshell-new (name)
  "Create a new eshell buffer named NAME."
  (interactive "sName: ")
  (let ((name (concat "$" name)))
    (sk/open-eshell)
    (rename-buffer name)))

(defalias 'eshell-new #'sk/open-eshell-new)

(defface sk/eshell-prompt-directory
  '((t (:inherit eshell-prompt)))
  "Face for the directory segment in the Sky Eshell prompt.")

(defface sk/eshell-prompt-symbol
  '((t (:inherit eshell-prompt :weight bold)))
  "Face for the prompt symbol in the Sky Eshell prompt.")

(defconst sk/eshell-prompt-symbol "λ"
  "Prompt symbol used by the Sky Eshell prompt.")

(defvar sk/generated-eshell-aliases nil
  "Generated Eshell aliases loaded from Home Manager.")

(defun sk/load-generated-eshell-aliases ()
  "Load generated Eshell aliases from `SK_EMACS_ESHELL_ALIASES_FILE'."
  (setq sk/generated-eshell-aliases nil)
  (when-let ((file (getenv "SK_EMACS_ESHELL_ALIASES_FILE")))
    (when (file-readable-p file)
      (load file nil 'nomessage)))
  sk/generated-eshell-aliases)

(defun sk/eshell-set-alias (name definition)
  "Set Eshell alias NAME to DEFINITION without writing alias state."
  (if-let ((entry (assoc name eshell-command-aliases-list)))
      (setcdr entry (list definition))
    (push (list name definition) eshell-command-aliases-list)))

(defun sk/eshell-install-generated-aliases ()
  "Install generated shell aliases into the current Eshell session."
  (dolist (alias (sk/load-generated-eshell-aliases))
    (sk/eshell-set-alias
     (if (symbolp (car alias))
         (symbol-name (car alias))
       (car alias))
     (cdr alias))))

(defun sk/eshell-prompt ()
  "Return the Sky Eshell prompt."
  (let* ((status (if (and (boundp 'eshell-last-command-status)
                          (numberp eshell-last-command-status)
                          (not (zerop eshell-last-command-status)))
                     (format " %s" eshell-last-command-status)
                   ""))
         (directory (abbreviate-file-name (eshell/pwd))))
    (concat
     (propertize directory 'face 'sk/eshell-prompt-directory)
     (when (not (string-empty-p status))
       (propertize status 'face 'font-lock-warning-face))
     "\n"
     (propertize sk/eshell-prompt-symbol 'face 'sk/eshell-prompt-symbol)
     " ")))

(use-package eshell-syntax-highlighting
  :after esh-mode
  :config
  (eshell-syntax-highlighting-global-mode 1))

(use-package eshell
  :ensure nil
  :config
  (let ((eshell-directory (expand-file-name "eshell/" sk/user-directory)))
    (make-directory eshell-directory t)
    (setq eshell-rc-script (expand-file-name "profile" eshell-directory)
          eshell-aliases-file (expand-file-name "aliases" eshell-directory)))
  (setq eshell-history-size 5000
        eshell-buffer-maximum-lines 5000
        eshell-hist-ignoredups t
        eshell-scroll-to-bottom-on-input t
        eshell-destroy-buffer-when-process-dies t
        eshell-visual-commands '("bash" "fish" "less" "man" "more" "ssh" "top")
        eshell-prompt-function #'sk/eshell-prompt
        eshell-prompt-regexp (concat "^" (regexp-quote sk/eshell-prompt-symbol) " "))
  (add-hook 'eshell-mode-hook #'sk/eshell-install-generated-aliases))

(with-eval-after-load 'corfu
  (add-hook 'eshell-mode-hook (lambda () (corfu-mode -1))))

(dolist (hook '(eshell-mode-hook shell-mode-hook term-mode-hook))
  (add-hook hook (lambda () (hl-line-mode -1))))

(provide 'sk-terminal)

;;; sk-terminal.el ends here
