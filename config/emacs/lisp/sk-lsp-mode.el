;;; sk-lsp-mode.el --- lsp-mode proof slices -*- lexical-binding: t; -*-

;; This module is intentionally narrow.  It proves lsp-mode + Company on
;; selected languages without changing the Eglot/Corfu path for other modes.

(require 'cl-lib)
(require 'seq)
(require 'sk-completion)
(require 'sk-lsp)

(defconst sk/lsp-mode-lua-modes '(lua-mode lua-ts-mode)
  "Lua major modes owned by lsp-mode during the proof slice.")

(defconst sk/lsp-mode-nix-modes '(nix-mode nix-ts-mode)
  "Nix major modes owned by lsp-mode during the proof slice.")

(defconst sk/lsp-mode-python-modes '(python-mode python-ts-mode)
  "Python major modes owned by lsp-mode during the proof slice.")

(defconst sk/lsp-mode-code-capfs '(lsp-completion-at-point)
  "Completion-at-point functions allowed in lsp-mode proof buffers.")

(setq sk/lsp-mode-owned-modes
      (append sk/lsp-mode-lua-modes
              sk/lsp-mode-nix-modes
              sk/lsp-mode-python-modes))

(defun sk/lsp-lua-language-server-root ()
  "Return the Nix package root for lua-language-server, when available."
  (when-let ((binary (executable-find "lua-language-server")))
    (file-name-directory
     (directory-file-name
      (file-name-directory (file-truename binary))))))

(defun sk/lsp-lua-language-server-main ()
  "Return the Nix lua-language-server main.lua path, when available."
  (when-let ((root (sk/lsp-lua-language-server-root)))
    (let ((main (expand-file-name "share/lua-language-server/main.lua" root)))
      (when (file-exists-p main)
        main))))

(defun sk/lsp-mode-code-buffer-p ()
  "Return non-nil when the current buffer is owned by the lsp-mode proof stack."
  (memq major-mode sk/lsp-mode-owned-modes))

(defun sk/lsp-mode-ensure-language-client ()
  "Load the language client package needed by the current proof buffer."
  (when (memq major-mode sk/lsp-mode-python-modes)
    (unless (require 'lsp-pyright nil t)
      (user-error "Python lsp-mode requires lsp-pyright; run SPC h r s"))))

(defun sk/lsp-mode-use-strict-completion ()
  "Let lsp-mode own completion sources in proof buffers."
  (when (sk/lsp-mode-code-buffer-p)
    (setq-local completion-at-point-functions sk/lsp-mode-code-capfs)
    (setq-local company-backends sk/company-code-backends)))

(defun sk/lsp-mode-enable-breadcrumb ()
  "Enable lsp-mode breadcrumbs in proof buffers."
  (when (sk/lsp-mode-code-buffer-p)
    (require 'all-the-icons nil t)
    (require 'lsp-treemacs nil t)
    (require 'lsp-headerline nil t))
  (when (and (sk/lsp-mode-code-buffer-p)
             (fboundp 'lsp-headerline-breadcrumb-mode))
    (lsp-headerline-breadcrumb-mode 1)))

(defun sk/lsp-sanitize-image-spec (image)
  "Return IMAGE without PGTK-hostile transparent mask metadata."
  (if (and (listp image)
           (eq (car image) 'image))
      (let ((plist (copy-sequence (cdr image))))
        (cl-remf plist :mask)
        (when (eq (plist-get plist :background) 'unspecified)
          (cl-remf plist :background))
        (cons 'image plist))
    image))

(defun sk/lsp-sanitize-icon-display (icon)
  "Sanitize lsp-treemacs ICON display properties while keeping PNG images."
  (if (stringp icon)
      (let ((display (get-text-property 0 'display icon)))
        (if display
            (propertize icon 'display (sk/lsp-sanitize-image-spec display))
          icon))
    icon))

(defun sk/lsp-fix-breadcrumb-icon-rendering (original image)
  "Call ORIGINAL and sanitize returned PNG display specs for PGTK."
  (sk/lsp-sanitize-icon-display (funcall original image)))

(with-eval-after-load 'lsp-icons
  (advice-remove 'lsp-icons--fix-image-background
                 #'sk/lsp-fix-breadcrumb-icon-rendering)
  (advice-add 'lsp-icons--fix-image-background
              :around #'sk/lsp-fix-breadcrumb-icon-rendering))

(defun sk/lsp-mode-enable-code-buffer ()
  "Use the shared lsp-mode proof completion and diagnostics UI."
  (when (sk/lsp-mode-code-buffer-p)
    (when (fboundp 'corfu-mode)
      (corfu-mode -1))
    (sk/lsp-mode-use-strict-completion)
    (add-hook 'lsp-configure-hook #'sk/lsp-mode-use-strict-completion nil t)
    (add-hook 'lsp-completion-mode-hook #'sk/lsp-mode-use-strict-completion nil t)
    (add-hook 'lsp-configure-hook #'sk/lsp-mode-enable-breadcrumb nil t)
    (setq-local lsp-completion-no-cache t)
    (setq-local eldoc-display-functions '(eldoc-display-in-buffer))
    (setq-local company-minimum-prefix-length 0)
    (company-mode 1)
    (flycheck-mode 1)))

(defun sk/lsp-mode-start ()
  "Start lsp-mode for proof buffers."
  (when (and buffer-file-name
             (sk/lsp-mode-code-buffer-p))
    (sk/lsp-mode-ensure-language-client)
    (sk/lsp-mode-enable-code-buffer)
    (if noninteractive
        (lsp)
      (lsp-deferred))))

(use-package company
  :defer t
  :config
  (setq company-backends '(company-capf)
        company-frontends '(company-pseudo-tooltip-frontend)
        company-idle-delay 0.05
        company-minimum-prefix-length 1
        company-selection-wrap-around t
        company-tooltip-align-annotations t))

(use-package all-the-icons
  :defer t)

(use-package flycheck
  :defer t)

(use-package lsp-treemacs
  :after lsp-mode)

(use-package lsp-pyright
  :after lsp-mode
  :init
  (setq lsp-pyright-langserver-command "basedpyright"
        lsp-pyright-auto-import-completions t))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-auto-configure t
        lsp-auto-guess-root t
        lsp-guess-root-without-session t
        lsp-completion-enable t
        lsp-completion-provider :capf
        lsp-completion-show-detail t
        lsp-completion-show-kind t
        lsp-diagnostics-provider :flycheck
        lsp-eldoc-render-all t
        lsp-enable-snippet t
        lsp-enable-suggest-server-download nil
        lsp-headerline-breadcrumb-enable t
        lsp-headerline-breadcrumb-enable-diagnostics t
        lsp-headerline-breadcrumb-enable-symbol-numbers nil
        lsp-headerline-breadcrumb-icons-enable t
        lsp-headerline-breadcrumb-segments '(project file symbols)
        lsp-idle-delay 0.2
        lsp-lua-completion-call-snippet "Both"
        lsp-lua-completion-enable t
        lsp-lua-completion-keyword-snippet "Both"
        lsp-lua-diagnostics-globals []
        lsp-lua-runtime-version "LuaJIT"
        lsp-lua-telemetry-enable nil
        lsp-nix-nixd-server-path "nixd"
        lsp-nix-nixd-formatting-command nil
        lsp-nix-nixd-nixpkgs-expr nil
        lsp-nix-nixd-nixos-options-expr nil
        lsp-nix-nixd-home-manager-options-expr nil)
  :config
  (require 'lsp-nix nil t)
  (dolist (client '(nix-nil rnix-lsp ruff))
    (add-to-list 'lsp-disabled-clients client))
  (when-let ((binary (executable-find "lua-language-server")))
    (setq lsp-clients-lua-language-server-bin binary
          lsp-clients-lua-language-server-command (list binary)))
  (when-let ((main (sk/lsp-lua-language-server-main)))
    (setq lsp-clients-lua-language-server-main-location main)))

(remove-hook 'lua-mode-hook #'sk/lsp-mode-start)
(remove-hook 'lua-ts-mode-hook #'sk/lsp-mode-start)
(remove-hook 'nix-mode-hook #'sk/lsp-mode-start)
(remove-hook 'nix-ts-mode-hook #'sk/lsp-mode-start)
(remove-hook 'python-mode-hook #'sk/lsp-mode-start)
(remove-hook 'python-ts-mode-hook #'sk/lsp-mode-start)
(add-hook 'lua-mode-hook #'sk/lsp-mode-start t)
(add-hook 'lua-ts-mode-hook #'sk/lsp-mode-start t)
(add-hook 'nix-mode-hook #'sk/lsp-mode-start t)
(add-hook 'nix-ts-mode-hook #'sk/lsp-mode-start t)
(add-hook 'python-mode-hook #'sk/lsp-mode-start t)
(add-hook 'python-ts-mode-hook #'sk/lsp-mode-start t)

(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (when (and (sk/lsp-mode-code-buffer-p)
               (bound-and-true-p lsp-mode))
      (sk/lsp-mode-enable-code-buffer)
      (sk/lsp-mode-enable-breadcrumb))))

(provide 'sk-lsp-mode)

;;; sk-lsp-mode.el ends here
