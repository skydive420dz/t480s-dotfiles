;;; sk-languages.el --- Language modes -*- lexical-binding: t; -*-

(use-package nix-mode
  :mode "\\.nix\\'"
  :hook (nix-mode . (lambda () (sk/set-indent-width 2))))

(use-package nix-ts-mode
  :commands nix-ts-mode
  :hook (nix-ts-mode . (lambda () (sk/set-indent-width 2))))

(use-package lua-mode
  :mode "\\.lua\\'"
  :hook (lua-mode . (lambda ()
                      (sk/set-indent-width 2)
                      (setq-local lua-indent-level 2))))

(use-package rust-mode
  :mode "\\.rs\\'"
  :hook (rust-mode . (lambda () (sk/set-indent-width 4))))

(use-package typescript-mode
  :mode ("\\.ts\\'" "\\.tsx\\'")
  :hook (typescript-mode . (lambda ()
                             (sk/set-indent-width 2)
                             (setq-local typescript-indent-level 2))))

(use-package web-mode
  :mode "\\.html\\'"
  :hook (web-mode . (lambda ()
                      (sk/set-indent-width 2)
                      (setq-local web-mode-markup-indent-offset 2)
                      (setq-local web-mode-code-indent-offset 2)
                      (setq-local web-mode-css-indent-offset 2))))

(use-package json-mode
  :mode "\\.json\\'"
  :hook (json-mode . (lambda () (sk/set-indent-width 2))))

(use-package markdown-mode
  :mode "\\.md\\'")

(use-package markdown-ts-mode
  :commands markdown-ts-mode)

(use-package yaml-mode
  :mode "\\.ya?ml\\'"
  :hook (yaml-mode . (lambda () (sk/set-indent-width 2))))

(use-package yasnippet
  :demand t
  :config
  (setq yas-snippet-dirs (list (expand-file-name "snippets" sk/user-directory)))
  (define-key yas-minor-mode-map (kbd "TAB") nil)
  (define-key yas-minor-mode-map (kbd "<tab>") nil)
  (define-key yas-minor-mode-map (kbd "<backtab>") nil)
  (define-key yas-minor-mode-map (kbd "S-TAB") nil)
  (define-key yas-keymap (kbd "TAB") #'yas-next-field-or-maybe-expand)
  (define-key yas-keymap (kbd "<tab>") #'yas-next-field-or-maybe-expand)
  (define-key yas-keymap (kbd "<backtab>") #'yas-prev-field)
  (define-key yas-keymap (kbd "S-TAB") #'yas-prev-field)
  (yas-global-mode 1))

(provide 'sk-languages)

;;; sk-languages.el ends here
