;;; sk-lsp.el --- Language server client -*- lexical-binding: t; -*-

;; Eglot is built into Emacs. Nix owns the external language-server executables.

(require 'seq)
(require 'eglot)

(defconst sk/eglot-managed-modes
  '(c-mode c++-mode c-ts-mode c++-ts-mode
    rust-mode rust-ts-mode
    python-mode python-ts-mode
    lua-mode lua-ts-mode
    nix-mode nix-ts-mode
    js-mode js-ts-mode typescript-mode typescript-ts-mode tsx-ts-mode
    web-mode html-mode html-ts-mode mhtml-mode css-mode css-ts-mode
    sh-mode bash-ts-mode
    yaml-mode yaml-ts-mode
    json-mode json-ts-mode
    markdown-mode markdown-ts-mode org-mode text-mode)
  "Major modes that should start Eglot when their server is available.")

(defconst sk/eglot-server-programs
  '(( ((lua-mode :language-id "lua")
       (lua-ts-mode :language-id "lua"))
      . ("lua-language-server"))
    ( ((nix-mode :language-id "nix")
       (nix-ts-mode :language-id "nix"))
      . ("nixd"))
    ( ((json-mode :language-id "json")
       (json-ts-mode :language-id "json")
       (js-json-mode :language-id "json"))
      . ("vscode-json-language-server" "--stdio"))
    ( ((yaml-mode :language-id "yaml")
       (yaml-ts-mode :language-id "yaml"))
      . ("yaml-language-server" "--stdio"))
    ( ((python-mode :language-id "python")
       (python-ts-mode :language-id "python"))
      . ("basedpyright-langserver" "--stdio"))
    ( ((web-mode :language-id "html")
       (html-mode :language-id "html")
       (html-ts-mode :language-id "html")
       (mhtml-mode :language-id "html"))
      . ("vscode-html-language-server" "--stdio"))
    ((css-mode css-ts-mode)
     . ("vscode-css-language-server" "--stdio"))
    ( ((js-mode :language-id "javascript")
       (js-ts-mode :language-id "javascript")
       (typescript-mode :language-id "typescript")
       (typescript-ts-mode :language-id "typescript")
       (tsx-ts-mode :language-id "typescriptreact"))
      . ("typescript-language-server" "--stdio"))
    ( ((markdown-mode :language-id "markdown")
       (markdown-ts-mode :language-id "markdown")
       (org-mode :language-id "org")
       (text-mode :language-id "plaintext"))
      . ("harper-ls" "--stdio")))
  "T480s Eglot server mappings, ordered from specific to broad.")

(defvar sk/org-agenda-generating-p nil
  "Non-nil while Org is collecting agenda buffers.")

(defvar sk/lsp-mode-owned-modes nil
  "Major modes intentionally handled by lsp-mode instead of Eglot.")

(defun sk/without-eglot-during-org-agenda (orig-fn &rest args)
  "Call ORIG-FN with prose Eglot autostart paused for agenda collection."
  (let ((sk/org-agenda-generating-p t))
    (apply orig-fn args)))

(defun sk/eglot-workspace-configuration (server)
  "Return per-server workspace configuration for SERVER."
  (let ((language-ids (eglot--language-ids server)))
    (cond
     ((member "lua" language-ids)
      (list :Lua
            (list :runtime (list :version "LuaJIT")
                  :diagnostics (list :globals [])
                  :workspace (list :checkThirdParty :json-false))))
     ((member "nix" language-ids)
      nil)
     ((seq-intersection '("markdown" "org" "plaintext") language-ids #'string=)
      '(:harper-ls (:userDictPath ""
                    :workspaceDictPath ""
                    :fileDictPath ""
                    :linters (:SpellCheck t
                              :SpelledNumbers :json-false
                              :AnA t
                              :SentenceCapitalization t
                              :UnclosedQuotes t
                              :WrongQuotes :json-false
                              :LongSentences t
                              :RepeatedWords t
                              :Spaces t
                              :Matcher t
                              :CorrectNumberSuffix t)
                    :codeActions (:ForceStable :json-false)
                    :markdown (:IgnoreLinkTitle :json-false)
                    :diagnosticSeverity "hint"
                    :isolateEnglish :json-false
                    :dialect "American"
                    :maxFileLength 120000
                    :ignoredLintsPath ""
                    :excludePatterns [])))
     (t nil))))

(defun sk/eglot-buffer-eligible-p ()
  "Return non-nil when the current buffer is a real file buffer for Eglot."
  (and buffer-file-name
       (not sk/org-agenda-generating-p)
       (not (string-prefix-p " " (buffer-name)))
       (or (not (memq major-mode '(rust-mode rust-ts-mode)))
           (locate-dominating-file default-directory "Cargo.toml")
           (locate-dominating-file default-directory "rust-project.json"))))

(defun sk/eglot-configure ()
  "Apply T480s Eglot defaults immediately and for new buffers."
  (setq-default eglot-autoshutdown nil
                eglot-workspace-configuration
                #'sk/eglot-workspace-configuration)
  (setq eglot-autoshutdown nil
        eglot-workspace-configuration
        #'sk/eglot-workspace-configuration)
  (dolist (server sk/eglot-server-programs)
    (setq eglot-server-programs
          (seq-remove (lambda (entry)
                        (equal (car entry) (car server)))
                      eglot-server-programs)))
  (setq eglot-server-programs
        (append sk/eglot-server-programs eglot-server-programs)))

(sk/eglot-configure)

(defun sk/eglot-ensure ()
  "Start Eglot for supported buffers."
  (when (and (memq major-mode sk/eglot-managed-modes)
             (not (memq major-mode sk/lsp-mode-owned-modes))
             (sk/eglot-buffer-eligible-p)
             (not (eglot-managed-p)))
    (condition-case err
        (progn
          (eglot-ensure)
          (when (fboundp 'sk/capf-code-defaults)
            (sk/capf-code-defaults)))
      (error
       (message "Eglot skipped for %s: %s"
                major-mode
                (error-message-string err))))))

(use-package eglot
  :ensure nil
  :hook ((c-mode c++-mode c-ts-mode c++-ts-mode
          rust-mode rust-ts-mode
          python-mode python-ts-mode
          lua-mode lua-ts-mode
          nix-mode nix-ts-mode
          js-mode js-ts-mode typescript-mode typescript-ts-mode tsx-ts-mode
          web-mode html-mode html-ts-mode mhtml-mode css-mode css-ts-mode
          sh-mode bash-ts-mode
          yaml-mode yaml-ts-mode
          json-mode json-ts-mode
          markdown-mode markdown-ts-mode org-mode text-mode) . sk/eglot-ensure)
  :config
  (sk/eglot-configure))

(with-eval-after-load 'org-agenda
  (advice-remove 'org-agenda #'sk/without-eglot-during-org-agenda)
  (advice-add 'org-agenda :around #'sk/without-eglot-during-org-agenda))

(provide 'sk-lsp)

;;; sk-lsp.el ends here
