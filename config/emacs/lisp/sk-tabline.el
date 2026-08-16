;;; sk-tabline.el --- Polished buffer tab line -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'tab-line)
(require 'nerd-icons nil t)

(defconst sk/tabline-hidden-buffer-regexp
  (rx string-start
      (or " "
          "*"))
  "Buffer names that should not appear in the tab line.")

(defconst sk/tabline-hidden-modes
  '(apropos-mode
    compilation-mode
    dired-mode
    eshell-mode
    help-mode
    ibuffer-mode
    magit-mode
    special-mode
    shell-mode
    term-mode
    vterm-mode)
  "Major modes that should not appear in the tab line.")

(defun sk/tabline-hidden-buffer-p (buffer)
  "Return non-nil when BUFFER is internal or helper-only."
  (let ((name (buffer-name buffer)))
    (or (minibufferp buffer)
        (and name
             (string-match-p sk/tabline-hidden-buffer-regexp name))
        (with-current-buffer buffer
          (memq major-mode sk/tabline-hidden-modes)))))

(defun sk/tabline-buffer-visible-p (buffer)
  "Return non-nil when BUFFER should be shown in the tab line."
  (let ((name (buffer-name buffer)))
    (and name
         (not (sk/tabline-hidden-buffer-p buffer)))))

(defun sk/tabline-buffers ()
  "Return buffers for the tab line."
  (seq-filter #'sk/tabline-buffer-visible-p (buffer-list)))

(defun sk/tabline-buffer-icon (buffer)
  "Return a Nerd Icon for BUFFER."
  (if (fboundp 'nerd-icons-icon-for-buffer)
      (or (ignore-errors
            (nerd-icons-icon-for-buffer buffer :height 0.9 :v-adjust -0.05))
          "")
    ""))

(defun sk/tabline-buffer-name (buffer &optional _buffers)
  "Return the displayed tab name for BUFFER."
  (let* ((name (buffer-name buffer))
         (trimmed (truncate-string-to-width name 28 nil nil "…"))
         (modified (and (buffer-file-name buffer)
                        (buffer-modified-p buffer)))
         (icon (sk/tabline-buffer-icon buffer)))
    (concat " " icon " " trimmed (if modified " ●" "") " ")))

(defun sk/tabline-disable ()
  "Disable tab line in utility/helper buffers."
  (tab-line-mode -1))

(defun sk/tabline-disable-if-hidden ()
  "Disable tab line when the current buffer is hidden from the tab list."
  (when (sk/tabline-hidden-buffer-p (current-buffer))
    (sk/tabline-disable)))

(setq tab-line-tabs-function #'sk/tabline-buffers
      tab-line-tab-name-function #'sk/tabline-buffer-name
      tab-line-close-button-show nil
      tab-line-new-button-show nil
      tab-line-separator " "
      tab-line-exclude-modes sk/tabline-hidden-modes)

(dolist (hook '(apropos-mode-hook
                compilation-mode-hook
                dired-mode-hook
                eshell-mode-hook
                help-mode-hook
                ibuffer-mode-hook
                magit-mode-hook
                shell-mode-hook
                special-mode-hook
                term-mode-hook
                vterm-mode-hook))
  (add-hook hook #'sk/tabline-disable))

(add-hook 'after-change-major-mode-hook #'sk/tabline-disable-if-hidden)

(global-tab-line-mode 1)

(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (sk/tabline-disable-if-hidden)))

(provide 'sk-tabline)

;;; sk-tabline.el ends here
