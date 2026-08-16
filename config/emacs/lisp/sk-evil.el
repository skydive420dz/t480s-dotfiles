;;; sk-evil.el --- Evil editing -*- lexical-binding: t; -*-

(use-package evil
  :demand t
  :init
  (setq evil-want-keybinding nil
        evil-want-integration t
        evil-want-C-u-scroll t
        evil-respect-visual-line-mode t)
  (setq evil-want-clipboard t)
  :config
  (evil-mode 1)
  (define-key evil-normal-state-map (kbd "s") #'evil-substitute)
  (define-key evil-normal-state-map (kbd "S") #'evil-change-whole-line))

(use-package evil-collection
  :after evil
  :init
  (setq evil-collection-magit-use-y-for-yank t
        evil-collection-magit-want-horizontal-movement nil
        evil-collection-magit-use-z-for-folds nil)
  :config
  (evil-collection-init))

(provide 'sk-evil)

;;; sk-evil.el ends here
