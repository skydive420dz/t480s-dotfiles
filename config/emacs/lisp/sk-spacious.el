;;; sk-spacious.el --- Subtle interface padding -*- lexical-binding: t; -*-

(use-package spacious-padding
  :demand t
  :custom
  (spacious-padding-widths
   '(:internal-border-width 8
     :header-line-width 6
     :mode-line-width 6
     :tab-width 4
     :right-divider-width 1
     :scroll-bar-width 0
     :fringe-width 10))
  (spacious-padding-subtle-mode-line nil)
  :config
  (spacious-padding-mode 1))

(provide 'sk-spacious)

;;; sk-spacious.el ends here
