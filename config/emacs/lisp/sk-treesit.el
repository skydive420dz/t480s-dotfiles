;;; sk-treesit.el --- Tree-sitter grammar wiring -*- lexical-binding: t; -*-

;; Nix owns parser delivery through SK_EMACS_TREE_SITTER_GRAMMAR_PATH. Emacs
;; only decides which built-in TS modes are safe to use.

(require 'treesit nil t)
(require 'subr-x)
(require 'seq)

(defvar sk/tree-sitter-grammar-path-env "SK_EMACS_TREE_SITTER_GRAMMAR_PATH"
  "Environment variable containing Nix-provided Tree-sitter parser directories.")

(defvar sk/tree-sitter-grammar-path-fallback
  (expand-file-name "tree-sitter-grammars/lib" user-emacs-directory)
  "Fallback Nix-linked Tree-sitter parser directory for GUI launches.")

(defconst sk/tree-sitter-mode-remaps
  '((python-mode . (python-ts-mode . python))
    (rust-mode . (rust-ts-mode . rust))
    (c-mode . (c-ts-mode . c))
    (c++-mode . (c++-ts-mode . cpp))
    (lua-mode . (lua-ts-mode . lua))
    (sh-mode . (bash-ts-mode . bash))
    (json-mode . (json-ts-mode . json))
    (yaml-mode . (yaml-ts-mode . yaml))
    (css-mode . (css-ts-mode . css)))
  "Classic modes to remap when their TS mode and grammar are available.")

(defconst sk/tree-sitter-direct-modes
  '(("\\.nix\\'" . (nix-ts-mode . nix))
    ("\\.lua\\'" . (lua-ts-mode . lua))
    ("\\.md\\'" . (markdown-ts-mode . markdown))
    ("\\.toml\\'" . (toml-ts-mode . toml))
    ("\\.html?\\'" . (html-ts-mode . html))
    ("\\.m?js\\'" . (js-ts-mode . javascript))
    ("\\.cjs\\'" . (js-ts-mode . javascript))
    ("\\.ts\\'" . (typescript-ts-mode . typescript))
    ("\\.tsx\\'" . (tsx-ts-mode . tsx)))
  "File patterns that can use built-in TS modes directly.")

(defconst sk/tree-sitter-managed-remap-modes
  '(python-mode rust-mode c-mode c++-mode sh-mode json-mode yaml-mode
    css-mode js-mode typescript-mode lua-mode)
  "Classic modes whose Tree-sitter remaps are owned by Sky Emacs.")

(defconst sk/tree-sitter-managed-direct-patterns
  (mapcar #'car sk/tree-sitter-direct-modes)
  "File patterns whose direct Tree-sitter routing is owned by Sky Emacs.")

(defun sk/tree-sitter-available-p (language mode)
  "Return non-nil when LANGUAGE grammar and MODE function are both available."
  (and (fboundp mode)
       (fboundp 'treesit-available-p)
       (treesit-available-p)
       (treesit-language-available-p language)))

(defun sk/tree-sitter-add-load-paths ()
  "Add Nix-provided Tree-sitter grammar directories to Emacs."
  (dolist (dir (append
                (when-let ((path (getenv sk/tree-sitter-grammar-path-env)))
                  (split-string path path-separator t))
                (list sk/tree-sitter-grammar-path-fallback)))
    (when (file-directory-p dir)
      (add-to-list 'treesit-extra-load-path dir))))

(defun sk/tree-sitter-setup ()
  "Enable conservative Tree-sitter mode routing."
  (sk/tree-sitter-add-load-paths)
  (setq major-mode-remap-alist
        (seq-remove (lambda (entry)
                      (memq (car entry) sk/tree-sitter-managed-remap-modes))
                    major-mode-remap-alist))
  (setq auto-mode-alist
        (seq-remove (lambda (entry)
                      (member (car entry) sk/tree-sitter-managed-direct-patterns))
                    auto-mode-alist))
  (dolist (entry sk/tree-sitter-mode-remaps)
    (let* ((classic-mode (car entry))
           (ts-mode (cadr entry))
           (language (cddr entry)))
      (when (sk/tree-sitter-available-p language ts-mode)
        (add-to-list 'major-mode-remap-alist (cons classic-mode ts-mode)))))
  (dolist (entry sk/tree-sitter-direct-modes)
    (let* ((pattern (car entry))
           (ts-mode (cadr entry))
           (language (cddr entry)))
      (when (sk/tree-sitter-available-p language ts-mode)
        (add-to-list 'auto-mode-alist (cons pattern ts-mode))))))

(sk/tree-sitter-setup)

(provide 'sk-treesit)

;;; sk-treesit.el ends here
