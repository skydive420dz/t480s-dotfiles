;;; sk-core.el --- Core editor behavior -*- lexical-binding: t; -*-

(setq user-full-name "Rafael Oliveira"
      user-mail-address "r0liveira@icloud.com")

(setq inhibit-startup-screen t
      ring-bell-function 'ignore
      use-dialog-box nil
      confirm-kill-emacs #'y-or-n-p
      font-lock-maximum-decoration t
      treesit-font-lock-level 4
      read-process-output-max (* 1024 1024))

(fset #'yes-or-no-p #'y-or-n-p)

(defun sk/prepend-exec-path (directory)
  "Prepend DIRECTORY to `exec-path' and process PATH when it exists."
  (when (and directory (file-directory-p directory))
    (add-to-list 'exec-path directory)
    (setenv "PATH" (concat directory path-separator (or (getenv "PATH") "")))))

(dolist (directory (list invocation-directory
                         (expand-file-name "~/.nix-profile/bin")
                         (format "/etc/profiles/per-user/%s/bin" user-login-name)
                         "/nix/var/nix/profiles/default/bin"))
  (sk/prepend-exec-path directory))

(setq backup-directory-alist `(("." . ,(expand-file-name "backups/" user-emacs-directory)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" user-emacs-directory) t))
      create-lockfiles nil)

(make-directory (expand-file-name "backups/" user-emacs-directory) t)
(make-directory (expand-file-name "auto-save/" user-emacs-directory) t)


(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 100)

(setq standard-indent 4)

(defun sk/set-indent-width (width)
  "Set common buffer-local indentation variables to WIDTH."
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width width)
  (setq-local standard-indent width)
  (setq-local c-basic-offset width)
  (setq-local js-indent-level width))

(electric-pair-mode 1)
(electric-indent-mode 1)
(global-hl-line-mode 1)
(save-place-mode 1)
(recentf-mode 1)
(global-auto-revert-mode 1)

(when (and (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  (setq native-comp-jit-compilation t
        native-comp-async-report-warnings-errors 'silent
        native-comp-speed 4))

(provide 'sk-core)

;;; sk-core.el ends here
