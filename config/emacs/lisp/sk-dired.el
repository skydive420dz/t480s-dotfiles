;;; sk-dired.el --- File management -*- lexical-binding: t; -*-

(defun sk/ls-supports-group-directories-first-p ()
  "Return non-nil when the active `ls' supports GNU directory grouping."
  (and insert-directory-program
       (executable-find insert-directory-program)
       (with-temp-buffer
         (eq 0 (call-process insert-directory-program nil t nil
                             "--group-directories-first" "-d" ".")))))

(defun sk/dired-next-line ()
  "Move to the next Dired line and refresh preview immediately."
  (interactive)
  (dired-next-line 1)
  (when (bound-and-true-p dired-preview-mode)
    (dired-preview-trigger :no-delay)))

(defun sk/dired-previous-line ()
  "Move to the previous Dired line and refresh preview immediately."
  (interactive)
  (dired-previous-line 1)
  (when (bound-and-true-p dired-preview-mode)
    (dired-preview-trigger :no-delay)))

(defun sk/main-edit-window ()
  "Return the main non-side editing window."
  (or (seq-find (lambda (window)
                  (not (window-parameter window 'window-side)))
                (window-list nil 'no-minibuf))
      (selected-window)))

(defun sk/dired-find-file ()
  "Open directories in Dired and files in the main editing window."
  (interactive)
  (let ((file (dired-get-file-for-visit)))
    (if (file-directory-p file)
        (dired-find-file)
      (select-window (sk/main-edit-window))
      (find-file file))))

(use-package dired
  :ensure nil
  :config
  (setq dired-kill-when-opening-new-dired-buffer t
        dired-listing-switches (if (sk/ls-supports-group-directories-first-p)
                                   "-alh --group-directories-first"
                                 "-alh")
        delete-by-moving-to-trash t)
  (add-hook 'dired-mode-hook #'dired-hide-details-mode)
  (add-hook 'dired-mode-hook #'hl-line-mode)
  (add-hook 'dired-mode-hook
            (lambda ()
              (when (fboundp 'evil-local-set-key)
                (evil-local-set-key 'normal (kbd "h") #'dired-up-directory)
                (evil-local-set-key 'normal (kbd "j") #'sk/dired-next-line)
                (evil-local-set-key 'normal (kbd "k") #'sk/dired-previous-line)
                (evil-local-set-key 'normal (kbd "l") #'sk/dired-find-file)
                (evil-local-set-key 'normal (kbd "RET") #'sk/dired-find-file)
                (evil-local-set-key 'normal (kbd "SPC m h") #'dired-omit-mode)
                (evil-local-set-key 'normal (kbd "SPC m p") #'dired-preview-mode)))))

(use-package dired-preview
  :after dired
  :commands (dired-preview-mode dired-preview-global-mode)
  :config
  (setq dired-preview-delay 0.15
        dired-preview-display-action-alist
        '((display-buffer-in-side-window)
          (side . bottom)
          (window-height . 0.12)
          (preserve-size . (nil . t)))
        dired-preview-max-size (expt 2 25)
        dired-preview-image-extensions-regexp
        "\\.\\(png\\|jpe?g\\|webp\\|gif\\|tiff?\\|svg\\|xpm\\|xbm\\|pbm\\)\\'"
        dired-preview-ignored-extensions-regexp
        (concat "\\."
                "\\(gz\\|zst\\|tar\\|xz\\|rar\\|zip\\|iso\\|epub\\)"
                "\\'")
        dired-preview-trigger-commands
        '(dired-next-line
          dired-previous-line
          dired-flag-file-deletion
          dired-mark
          dired-unmark
          dired-unmark-backward
          dired-del-marker
          dired-goto-file
          dired-find-file
          sk/dired-find-file
          evil-next-line
          evil-previous-line
          evil-next-visual-line
          evil-previous-visual-line
          next-line
          previous-line
          scroll-up-command
          scroll-down-command)))

(provide 'sk-dired)

;;; sk-dired.el ends here
