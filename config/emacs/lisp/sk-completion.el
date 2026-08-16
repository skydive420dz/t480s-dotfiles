;;; sk-completion.el --- Completion layers -*- lexical-binding: t; -*-

;; Layering:
;; - Vertico/Orderless/Marginalia/Embark/Consult for minibuffer completion.
;; - Corfu for in-buffer completion UI.
;; - CAPF sources are added per buffer class, not globally everywhere.

(require 'seq)

(defvar sk/company-code-backends
  '((company-capf
     company-yasnippet
     company-files
     company-keywords
     company-dabbrev-code))
  "Shared Company backend stack for lsp-mode proof buffers.")

(with-eval-after-load 'company-keywords
  (add-to-list 'company-keywords-alist '(lua-ts-mode . lua-mode)))

(use-package vertico
  :demand t
  :config
  (define-key vertico-map (kbd "C-j") #'vertico-next)
  (define-key vertico-map (kbd "C-k") #'vertico-previous)
  (define-key vertico-map (kbd "C-l") #'vertico-exit)
  (vertico-mode 1))

(use-package orderless
  :demand t
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :demand t
  :config
  (marginalia-mode 1))

(use-package savehist
  :ensure nil
  :demand t
  :config
  (add-to-list 'savehist-additional-variables 'corfu-history)
  (savehist-mode 1))

(use-package consult
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)
         ("M-y" . consult-yank-pop)))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)))

(use-package embark-consult
  :after (embark consult))

(use-package corfu
  :demand t
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.05
        corfu-auto-prefix 2
        corfu-cycle t
        corfu-on-exact-match nil
        corfu-popupinfo-delay '(0.45 . 0.15)
        corfu-popupinfo-max-height 16
        corfu-popupinfo-min-height 3
        corfu-preview-current nil)
  (define-key corfu-map (kbd "C-j") #'corfu-next)
  (define-key corfu-map (kbd "C-k") #'corfu-previous)
  (define-key corfu-map (kbd "C-l") #'corfu-insert)
  (define-key corfu-map (kbd "C-h") #'corfu-quit)
  (define-key corfu-map (kbd "M-d") #'corfu-popupinfo-toggle)
  (corfu-history-mode 1)
  (corfu-popupinfo-mode 1)
  (global-corfu-mode 1))

(use-package cape
  :demand t
  :after corfu)

(defun sk/completion-company-owned-buffer-p ()
  "Return non-nil when another completion UI owns this buffer."
  (and (boundp 'sk/lsp-mode-owned-modes)
       (memq major-mode sk/lsp-mode-owned-modes)))

(defun sk/yas-snippet-candidates ()
  "Return snippet trigger/name pairs for the current major mode."
  (when (and (bound-and-true-p yas-minor-mode)
             (fboundp 'yas--get-snippet-tables)
             (fboundp 'yas--all-templates))
    (delete-dups
     (delq nil
           (mapcar (lambda (template)
                     (let ((key (yas--template-key template)))
                       (when (and key (not (string= key "")))
                         (cons key (yas--template-name template)))))
                   (yas--all-templates
                    (yas--get-snippet-tables major-mode)))))))

(defun sk/yas-capf ()
  "Complete Yasnippet triggers with Corfu and expand on accept."
  (when-let* ((candidates (sk/yas-snippet-candidates))
              (bounds (bounds-of-thing-at-point 'symbol))
              (start (car bounds))
              (end (cdr bounds))
              (prefix (buffer-substring-no-properties start end))
              (matches (seq-filter
                        (lambda (candidate)
                          (string-prefix-p prefix (car candidate)))
                        candidates)))
    (when matches
      (list start end (mapcar #'car matches)
            :exclusive 'no
            :annotation-function
            (lambda (candidate)
              (when-let ((name (cdr (assoc candidate matches))))
                (concat " " name)))
            :company-kind (lambda (_) 'snippet)
            :exit-function
            (lambda (_candidate status)
              (when (memq status '(finished exact sole))
                (yas-expand)))))))

(defun sk/capf-code-defaults ()
  "Add conservative fallback CAPFs for code/config buffers."
  (unless (sk/completion-company-owned-buffer-p)
    (when (fboundp 'cape-file)
      (add-hook 'completion-at-point-functions #'cape-file 20 t))
    (when (fboundp 'cape-dabbrev)
      (add-hook 'completion-at-point-functions #'cape-dabbrev 40 t))
    (when (fboundp 'cape-keyword)
      (add-hook 'completion-at-point-functions #'cape-keyword 60 t))
    (setq-local completion-at-point-functions
                (cons #'sk/yas-capf
                      (remq #'sk/yas-capf completion-at-point-functions)))))

(defun sk/capf-prose-defaults ()
  "Add safe prose CAPFs."
  (setq-local completion-at-point-functions
              (remq #'ispell-completion-at-point completion-at-point-functions))
  (when (fboundp 'cape-file)
    (add-hook 'completion-at-point-functions #'cape-file 20 t))
  (when (fboundp 'cape-dabbrev)
    (add-hook 'completion-at-point-functions #'cape-dabbrev 40 t)))

(dolist (hook '(prog-mode-hook conf-mode-hook
                nix-mode-hook nix-ts-mode-hook
                lua-mode-hook lua-ts-mode-hook
                yaml-mode-hook json-mode-hook))
  (add-hook hook #'sk/capf-code-defaults))

(dolist (hook '(org-mode-hook markdown-mode-hook markdown-ts-mode-hook text-mode-hook))
  (add-hook hook #'sk/capf-prose-defaults))

(global-set-key (kbd "M-/") #'completion-at-point)

(defvar sk/completion-disabled-modes
  '(vterm-mode term-mode shell-mode eshell-mode)
  "Major modes where Corfu should stay off.")

(defun sk/completion-buffer-p ()
  "Return non-nil when Corfu should be active in the current buffer."
  (and (not (minibufferp))
       (not (memq major-mode sk/completion-disabled-modes))
       (or (derived-mode-p 'prog-mode 'text-mode 'conf-mode)
           (memq major-mode '(nix-mode nix-ts-mode
                              lua-mode lua-ts-mode
                              yaml-mode yaml-ts-mode
                              json-mode json-ts-mode
                              markdown-mode markdown-ts-mode
                              org-mode)))))

(defun sk/completion-code-buffer-p ()
  "Return non-nil when code/config fallback CAPFs should be active."
  (or (derived-mode-p 'prog-mode 'conf-mode)
      (memq major-mode '(nix-mode nix-ts-mode
                         lua-mode lua-ts-mode
                         yaml-mode yaml-ts-mode
                         json-mode json-ts-mode))))

(defun sk/completion-prose-buffer-p ()
  "Return non-nil when prose fallback CAPFs should be active."
  (or (derived-mode-p 'text-mode)
      (memq major-mode '(markdown-mode markdown-ts-mode org-mode))))

(defun sk/refresh-completion-modes ()
  "Reapply completion minor modes to existing buffers after config reloads."
  (interactive)
  (global-corfu-mode 1)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (cond
       ((sk/completion-code-buffer-p)
        (sk/capf-code-defaults))
       ((sk/completion-prose-buffer-p)
        (sk/capf-prose-defaults)))
      (when (fboundp 'corfu-mode)
        (if (and (sk/completion-buffer-p)
                 (not (sk/completion-company-owned-buffer-p)))
            (corfu-mode 1)
          (corfu-mode -1))))))

(defun sk/completion-active-p ()
  "Return non-nil when in-buffer completion is active."
  (or (sk/corfu-completion-active-p)
      (sk/company-completion-active-p)))

(defun sk/corfu-completion-active-p ()
  "Return non-nil when Corfu completion is active."
  (or (bound-and-true-p completion-in-region-mode)
      (and (boundp 'corfu--candidates)
           corfu--candidates)))

(defun sk/company-completion-active-p ()
  "Return non-nil when Company completion is active."
  (and (fboundp 'company--active-p)
       (company--active-p)))

(defun sk/completion-next-or-window-down ()
  "Select the next completion candidate or move to the window below."
  (interactive)
  (cond
   ((sk/company-completion-active-p)
    (company-select-next))
   ((sk/corfu-completion-active-p)
    (corfu-next))
   (t
    (windmove-down))))

(defun sk/completion-previous-or-window-up ()
  "Select the previous completion candidate or move to the window above."
  (interactive)
  (cond
   ((sk/company-completion-active-p)
    (company-select-previous))
   ((sk/corfu-completion-active-p)
    (corfu-previous))
   (t
    (windmove-up))))

(defun sk/completion-accept-or-window-right ()
  "Accept the current completion candidate or move to the right window."
  (interactive)
  (cond
   ((sk/company-completion-active-p)
    (company-complete-selection))
   ((sk/corfu-completion-active-p)
    (corfu-insert))
   (t
    (windmove-right))))

(defun sk/completion-quit-or-window-left ()
  "Quit completion or move to the left window."
  (interactive)
  (cond
   ((sk/company-completion-active-p)
    (company-abort))
   ((sk/corfu-completion-active-p)
    (corfu-quit))
   (t
    (windmove-left))))

(with-eval-after-load 'company
  (define-key company-active-map (kbd "C-j") #'company-select-next)
  (define-key company-active-map (kbd "C-k") #'company-select-previous)
  (define-key company-active-map (kbd "C-l") #'company-complete-selection)
  (define-key company-active-map (kbd "C-h") #'company-abort)
  (define-key company-active-map (kbd "M-d") #'company-show-doc-buffer))

(provide 'sk-completion)

;;; sk-completion.el ends here
