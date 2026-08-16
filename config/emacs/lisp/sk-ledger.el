;;; sk-ledger.el --- Plain-text accounting support -*- lexical-binding: t; -*-

(defvar sk/ledger-directory (expand-file-name "~/Documents/finance/")
  "Private directory for Ledger files.")

(defvar sk/ledger-localleader-map (make-sparse-keymap)
  "Ledger commands under the Doom-style local leader.")

(defun sk/ledger-open-directory ()
  "Open the private Ledger directory."
  (interactive)
  (make-directory sk/ledger-directory t)
  (dired sk/ledger-directory))

(use-package ledger-mode
  :mode (("\\.ledger\\'" . ledger-mode)
         ("\\.journal\\'" . ledger-mode)
         ("\\.dat\\'" . ledger-mode))
  :init
  (setq ledger-binary-path (or (executable-find "ledger") "ledger"))
  :config
  (setq ledger-clear-whole-transactions t)
  (define-key ledger-mode-map (kbd "TAB") #'completion-at-point)
  (define-key ledger-mode-map (kbd "SPC m") sk/ledger-localleader-map)
  (define-key sk/ledger-localleader-map (kbd "a") #'ledger-add-transaction)
  (define-key sk/ledger-localleader-map (kbd "b") #'ledger-report)
  (define-key sk/ledger-localleader-map (kbd "d") #'sk/ledger-open-directory)
  (define-key sk/ledger-localleader-map (kbd "r") #'ledger-report)
  (with-eval-after-load 'which-key
    (which-key-add-key-based-replacements
      "SPC m" "ledger"
      "SPC m a" "add transaction"
      "SPC m b" "balance/report"
      "SPC m d" "finance directory"
      "SPC m r" "report")))

(provide 'sk-ledger)

;;; sk-ledger.el ends here
