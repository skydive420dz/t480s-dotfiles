;;; sk-json.el --- JSON editing helpers -*- lexical-binding: t; -*-

;; vscode-json-language-server currently advertises pull diagnostics, while the
;; bundled Eglot in Emacs 30.2 only wires publish diagnostics into Flymake.
;; Keep the language server for completion/hover and use Emacs' JSON parser for
;; local syntax diagnostics.

(require 'flymake)
(require 'json)

(defun sk/json-error-position (error)
  "Return buffer position from JSON parse ERROR, or nil if unavailable."
  (pcase-let ((`(json-parse-error ,line ,column . ,_) error))
    (when (and (integerp line) (integerp column))
      (save-excursion
        (goto-char (point-min))
        (forward-line (1- line))
        (forward-char (max 0 (1- column)))
        (point)))))

(defun sk/json-flymake-backend (report-fn &rest _args)
  "Report JSON syntax diagnostics through REPORT-FN."
  (condition-case error
      (let (diagnostics)
        (save-excursion
          (goto-char (point-min))
          (json-parse-buffer)
          (skip-chars-forward " \t\r\n")
          (unless (eobp)
            (push (flymake-make-diagnostic
                   (current-buffer)
                   (point)
                   (min (point-max) (1+ (point)))
                   :error
                   "Trailing characters after JSON value")
                  diagnostics)))
        (funcall report-fn diagnostics))
    (json-parse-error
     (let* ((reported-position (or (sk/json-error-position error) (point-min)))
            (position (if (< reported-position (point-max))
                          reported-position
                        (max (point-min) (1- (point-max)))))
            (end (min (point-max) (1+ position)))
            (message (error-message-string error)))
       (funcall report-fn
                (list (flymake-make-diagnostic
                       (current-buffer)
                       position
                       end
                       :error
                       message)))))))

(defun sk/json-enable-flymake-parser ()
  "Add parser-backed JSON syntax diagnostics for the current buffer."
  (add-hook 'flymake-diagnostic-functions #'sk/json-flymake-backend nil t))

(dolist (hook '(json-mode-hook json-ts-mode-hook js-json-mode-hook))
  (add-hook hook #'sk/json-enable-flymake-parser))

(provide 'sk-json)

;;; sk-json.el ends here
