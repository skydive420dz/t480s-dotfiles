;;; sk-git.el --- Git tools -*- lexical-binding: t; -*-

(use-package with-editor
  :defer t
  :config
  (when-let ((emacsclient (or (executable-find "emacsclient")
                              (let ((candidate (expand-file-name "emacsclient"
                                                                 invocation-directory)))
                                (and (file-executable-p candidate) candidate)))))
    (setq with-editor-emacsclient-executable emacsclient)))

(use-package magit
  :commands magit-status
  :bind (("C-c g" . magit-status))
  :config
  (setq magit-display-buffer-function #'sk/display-magit-buffer)
  (evil-collection-init 'magit)
  (evil-define-key '(normal motion) magit-mode-map
    (kbd "TAB") #'magit-section-toggle
    (kbd "<tab>") #'magit-section-toggle
    (kbd "S-TAB") #'magit-section-cycle-global
    (kbd "<backtab>") #'magit-section-cycle-global))

(provide 'sk-git)

;;; sk-git.el ends here
