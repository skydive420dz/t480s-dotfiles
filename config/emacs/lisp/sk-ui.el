;;; sk-ui.el --- UI settings -*- lexical-binding: t; -*-

(set-face-attribute 'default nil :family "Iosevka Term" :height 120)

;; Keep the desktop opaque by default. Transparency was measured as a real redraw cost.
(add-to-list 'default-frame-alist '(alpha . 100))
(add-to-list 'default-frame-alist '(alpha-background . 100))

(setq resize-mini-windows t)

(setq display-line-numbers-type 'relative)

(defun sk/enable-line-numbers ()
  "Enable relative line numbers in the current buffer."
  (display-line-numbers-mode 1))

(defun sk/disable-line-numbers ()
  "Disable line numbers in the current buffer."
  (display-line-numbers-mode -1))

(defun sk/apply-line-number-policy ()
  "Apply the Sky line-number policy to the current buffer."
  (if (derived-mode-p 'prog-mode)
      (sk/enable-line-numbers)
    (sk/disable-line-numbers)))

(global-display-line-numbers-mode -1)

(add-hook 'prog-mode-hook #'sk/enable-line-numbers)

(defun sk/enable-prose-wrapping ()
  "Enable visual wrapping for prose buffers."
  (visual-line-mode 1))

(dolist (hook '(org-mode-hook
                markdown-mode-hook
                text-mode-hook
                dired-mode-hook
                vterm-mode-hook
                term-mode-hook
                shell-mode-hook
                eshell-mode-hook
                help-mode-hook
                special-mode-hook
                completion-list-mode-hook))
  (add-hook hook #'sk/disable-line-numbers))

(dolist (hook '(org-mode-hook
                markdown-mode-hook
                markdown-ts-mode-hook
                text-mode-hook))
  (add-hook hook #'sk/enable-prose-wrapping))

(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (sk/apply-line-number-policy)))

(defconst sk/terminal-frame-colors
  '((background . "color-234")
    (foreground . "color-255")
    (mode-line . "color-235")
    (mode-line-inactive . "color-233")
    (muted . "color-245")
    (border . "color-237"))
  "256-color-safe fallback colors for terminal Emacs frames.")

(defun sk/terminal-frame-color (name)
  "Return terminal fallback color NAME."
  (alist-get name sk/terminal-frame-colors))

(defun sk/terminal-frame-direct-color-p (frame)
  "Return non-nil when FRAME can render direct colors."
  (> (display-color-cells frame) 256))

(defun sk/frame-color (frame sky-color fallback-color)
  "Return SKY-COLOR for FRAME, falling back to FALLBACK-COLOR in 256-color terminals."
  (if (sk/terminal-frame-direct-color-p frame)
      (sk/theme-color sky-color)
    (sk/terminal-frame-color fallback-color)))

(defun sk/apply-terminal-frame-theme (&optional frame)
  "Apply Sky colors to terminal FRAME."
  (let ((target-frame (or frame (selected-frame))))
    (with-selected-frame target-frame
      (unless (display-graphic-p target-frame)
        (set-frame-parameter target-frame 'background-color
                             (sk/frame-color target-frame 'background 'background))
        (set-frame-parameter target-frame 'foreground-color
                             (sk/frame-color target-frame 'foreground 'foreground))
        (set-face-background 'default
                             (sk/frame-color target-frame 'background 'background)
                             target-frame)
        (set-face-foreground 'default
                             (sk/frame-color target-frame 'foreground 'foreground)
                             target-frame)
        (set-face-background 'mode-line
                             (sk/frame-color target-frame 'surface 'mode-line)
                             target-frame)
        (set-face-foreground 'mode-line
                             (sk/frame-color target-frame 'foreground 'foreground)
                             target-frame)
        (set-face-background 'mode-line-inactive
                             (sk/frame-color target-frame 'background-alt 'mode-line-inactive)
                             target-frame)
        (set-face-foreground 'mode-line-inactive
                             (sk/frame-color target-frame 'muted 'muted)
                             target-frame)
        (set-face-background 'vertical-border
                             (sk/frame-color target-frame 'border 'border)
                             target-frame)
        (set-face-foreground 'vertical-border
                             (sk/frame-color target-frame 'border 'border)
                             target-frame)))))

(add-hook 'after-make-frame-functions #'sk/apply-terminal-frame-theme)

(sk/load-theme)
(sk/apply-terminal-frame-theme)

(use-package doom-modeline
  :demand t
  :config
  (setq doom-modeline-height 28
        doom-modeline-bar-width 4
        doom-modeline-window-width-limit 80
        doom-modeline-buffer-file-name-style 'relative-to-project
        doom-modeline-buffer-encoding nil
        doom-modeline-major-mode-icon t
        doom-modeline-major-mode-color-icon t
        doom-modeline-buffer-state-icon t
        doom-modeline-buffer-modification-icon t
        doom-modeline-vcs-max-length 24
        doom-modeline-env-version nil
        doom-modeline-github nil
        doom-modeline-gnus nil
        doom-modeline-irc nil
        doom-modeline-persp-name nil
        doom-modeline-workspace-name nil
        doom-modeline-modal-icon nil
        doom-modeline-enable-word-count nil)
  (doom-modeline-mode 1))

(provide 'sk-ui)

;;; sk-ui.el ends here
