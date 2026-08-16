;;; init.el --- Sky Emacs entrypoint -*- lexical-binding: t; -*-

(defvar sk/user-directory
  (or (bound-and-true-p sk/source-directory)
      (file-name-directory (or load-file-name buffer-file-name)))
  "Root directory of the Sky Emacs config.")

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file nil t))

(setq load-prefer-newer t)

(defvar sk/lisp-directory
  (expand-file-name "lisp" sk/user-directory)
  "Directory for Sky Emacs modules.")

(add-to-list 'load-path sk/lisp-directory)

(require 'sk-package)
(require 'sk-core)
(require 'sk-theme)
(require 'sk-ui)
(require 'sk-windows)
(require 'sk-solaire)
(require 'sk-spacious)
(require 'sk-tabline)
(require 'sk-dashboard)
(require 'sk-evil)
(require 'sk-completion)
(require 'sk-languages)
(require 'sk-treesit)
(require 'sk-lsp)
(require 'sk-lsp-mode)
(require 'sk-json)
(require 'sk-format)
(require 'sk-org)
(require 'sk-notes)
(require 'sk-dired)
(require 'sk-terminal)
(require 'sk-ledger)
(require 'sk-devdocs)
(require 'sk-project)
(require 'sk-git)
(require 'sk-keybindings)

(provide 'init)

;;; init.el ends here
