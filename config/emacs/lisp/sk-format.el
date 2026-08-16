;;; sk-format.el --- Explicit formatting commands -*- lexical-binding: t; -*-

;; Formatting is manual by design. There is no format-on-save hook here.

(require 'subr-x)
(require 'eglot)

(defconst sk/formatter-alist
  '((nix-mode . ("nixfmt"))
    (nix-ts-mode . ("nixfmt"))
    (lua-mode . ("stylua" "-"))
    (lua-ts-mode . ("stylua" "-"))
    (rust-mode . ("rustfmt"))
    (rust-ts-mode . ("rustfmt"))
    (c-mode . ("clang-format"))
    (c++-mode . ("clang-format"))
    (c-ts-mode . ("clang-format"))
    (c++-ts-mode . ("clang-format"))
    (python-mode . ("black" "-q" "-"))
    (python-ts-mode . ("black" "-q" "-"))
    (sh-mode . ("shfmt"))
    (bash-ts-mode . ("shfmt"))
    (json-mode . ("prettier" "--parser" "json"))
    (json-ts-mode . ("prettier" "--parser" "json"))
    (yaml-mode . ("prettier" "--parser" "yaml"))
    (yaml-ts-mode . ("prettier" "--parser" "yaml"))
    (js-mode . ("prettier" "--parser" "babel"))
    (js-ts-mode . ("prettier" "--parser" "babel"))
    (typescript-mode . ("prettier" "--parser" "typescript"))
    (typescript-ts-mode . ("prettier" "--parser" "typescript"))
    (tsx-ts-mode . ("prettier" "--parser" "typescript"))
    (web-mode . ("prettier" "--parser" "html"))
    (html-mode . ("prettier" "--parser" "html"))
    (html-ts-mode . ("prettier" "--parser" "html"))
    (mhtml-mode . ("prettier" "--parser" "html"))
    (css-mode . ("prettier" "--parser" "css"))
    (css-ts-mode . ("prettier" "--parser" "css")))
  "Formatter commands keyed by major mode.

Most commands read from stdin and write formatted text to stdout.
Commands containing `:file' receive a temporary file path instead.")

(defun sk/formatter-temp-file-suffix ()
  "Return a useful temporary file suffix for the current buffer."
  (or (when-let* ((file (buffer-file-name))
                  (extension (file-name-extension file)))
        (concat "." extension))
      (pcase major-mode
        ('python-mode ".py")
        ('python-ts-mode ".py")
        ('rust-mode ".rs")
        ('nix-mode ".nix")
        ('nix-ts-mode ".nix")
        ('lua-mode ".lua")
        ('lua-ts-mode ".lua")
        (_ ".txt"))))

(defun sk/formatter-command ()
  "Return the formatter command for the current buffer."
  (alist-get major-mode sk/formatter-alist))

(defun sk/format-range-bounds ()
  "Return formatting bounds for active region or whole buffer."
  (if (use-region-p)
      (cons (region-beginning) (region-end))
    (cons (point-min) (point-max))))

(defun sk/run-formatter-stdin-command (command start end output-buffer error-file)
  "Run stdin/stdout formatter COMMAND over START and END."
  (apply #'call-process-region
         start
         end
         (car command)
         nil
         (list output-buffer error-file)
         nil
         (cdr command)))

(defun sk/run-formatter-file-command (command start end output-buffer error-file)
  "Run temp-file formatter COMMAND over START and END."
  (let ((temp-file (make-temp-file "sk-format-" nil (sk/formatter-temp-file-suffix))))
    (unwind-protect
        (progn
          (write-region start end temp-file nil 'silent)
          (apply #'call-process
                 (car command)
                 nil
                 (list output-buffer error-file)
                 nil
                 (mapcar (lambda (argument)
                           (if (eq argument :file) temp-file argument))
                         (cdr command))))
      (delete-file temp-file))))

(defun sk/run-formatter-command (command start end)
  "Run formatter COMMAND over START and END."
  (unless (executable-find (car command))
    (user-error "Formatter not found: %s" (car command)))
  (let* ((output-buffer (generate-new-buffer " *sk-format-output*"))
         (error-file (make-temp-file "sk-format-error-"))
         (coding-system-for-read 'utf-8-unix)
         (coding-system-for-write 'utf-8-unix)
         (status nil))
    (unwind-protect
        (progn
          (setq status (if (memq :file command)
                           (sk/run-formatter-file-command command start end output-buffer error-file)
                         (sk/run-formatter-stdin-command command start end output-buffer error-file)))
          (unless (eq status 0)
            (user-error "Formatter failed: %s"
                        (with-temp-buffer
                          (insert-file-contents error-file)
                          (string-trim (buffer-string)))))
          (let ((point-marker (copy-marker (point) t)))
            (delete-region start end)
            (insert-buffer-substring output-buffer)
            (goto-char (min point-marker (point-max)))))
      (kill-buffer output-buffer)
      (delete-file error-file))))

(defun sk/format-buffer-or-region ()
  "Format the active region or current buffer explicitly."
  (interactive)
  (let* ((bounds (sk/format-range-bounds))
         (start (car bounds))
         (end (cdr bounds))
         (command (sk/formatter-command)))
    (cond
     (command
      (sk/run-formatter-command command start end)
      (message "Formatted with %s" (car command)))
     ((eglot-managed-p)
      (if (use-region-p)
          (eglot-format start end)
        (eglot-format-buffer))
      (message "Formatted with Eglot"))
     (t
      (indent-region start end)
      (message "Indented region")))))

(provide 'sk-format)

;;; sk-format.el ends here
