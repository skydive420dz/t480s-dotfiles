;;; early-init.el --- Early startup for Sky Emacs -*- lexical-binding: t; -*-

(setq package-enable-at-startup nil
      frame-inhibit-implied-resize t
      inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name)

(defvar sk/source-directory
  (file-name-directory (or load-file-name buffer-file-name))
  "Source directory of the Sky Emacs config.")

(defvar sk/cache-directory
  (file-name-as-directory
   (or (getenv "XDG_CACHE_HOME")
       (expand-file-name "~/.cache")))
  "XDG cache directory for Sky Emacs runtime files.")

(defvar sk/runtime-directory
  (expand-file-name "emacs/" sk/cache-directory)
  "Runtime directory for Sky Emacs package/cache/state files.")

(setq user-emacs-directory sk/runtime-directory
      package-user-dir (expand-file-name "elpa/" sk/runtime-directory)
      custom-file (expand-file-name "custom.el" sk/runtime-directory)
      auto-save-list-file-prefix (expand-file-name "auto-save-list/.saves-" sk/runtime-directory))

(make-directory user-emacs-directory t)
(make-directory package-user-dir t)
(make-directory (file-name-directory auto-save-list-file-prefix) t)

(when (boundp 'native-comp-eln-load-path)
  (startup-redirect-eln-cache (expand-file-name "eln-cache/" sk/runtime-directory)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(setq default-frame-alist
      '((vertical-scroll-bars . nil)
        (internal-border-width . 0)))

;;; early-init.el ends here
