;;; sk-keybindings.el --- Survival navigation layer -*- lexical-binding: t; -*-

;; This file is intentionally boring: it gives the clean config enough
;; Doom-like navigation to be testable without hiding behavior in a framework.

(require 'windmove)
(require 'winner)
(require 'project)
(require 'subr-x)
(require 'seq)
(require 'recentf)
(require 'eglot)
(require 'flymake)
(require 'flycheck nil t)
(require 'eldoc)
(require 'compile)
(require 'xref)
(require 'dired-x)
(require 'sk-dashboard)

(winner-mode 1)

(defun sk/new-empty-buffer ()
  "Create and switch to a new unnamed buffer."
  (interactive)
  (switch-to-buffer (generate-new-buffer "untitled")))

(defun sk/kill-current-buffer ()
  "Kill the current buffer without asking for a buffer name."
  (interactive)
  (kill-buffer (current-buffer))
  (sk/show-dashboard-if-no-ordinary-buffers))

(defun sk/switch-to-last-buffer ()
  "Switch to the previously visited buffer."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

(defun sk/user-buffer-p (buffer)
  "Return non-nil when BUFFER is a user-facing buffer."
  (let ((name (buffer-name buffer)))
    (and name
         (not (string-prefix-p " " name))
         (not (sk/dashboard-buffer-p buffer)))))

(defun sk/ordinary-buffer-p (buffer)
  "Return non-nil when BUFFER should keep the home buffer hidden."
  (let ((name (buffer-name buffer)))
    (and (buffer-live-p buffer)
         name
         (not (string-prefix-p " " name))
         (not (string-prefix-p "*" name))
         (not (sk/dashboard-buffer-p buffer)))))

(defun sk/show-dashboard-if-no-ordinary-buffers ()
  "Show the Sky home buffer when no ordinary buffers remain."
  (unless (seq-some #'sk/ordinary-buffer-p (buffer-list))
    (sk/dashboard)))

(defun sk/kill-all-buffers ()
  "Kill user-facing buffers."
  (interactive)
  (mapc (lambda (buffer)
          (when (and (buffer-live-p buffer)
                     (sk/user-buffer-p buffer))
            (kill-buffer buffer)))
        (buffer-list))
  (sk/dashboard))

(defun sk/kill-other-buffers ()
  "Kill user-facing buffers except the current buffer."
  (interactive)
  (let ((current (current-buffer)))
    (mapc (lambda (buffer)
            (when (and (not (eq buffer current))
                       (buffer-live-p buffer)
                       (sk/user-buffer-p buffer))
              (kill-buffer buffer)))
          (buffer-list))
    (sk/show-dashboard-if-no-ordinary-buffers)))

(defun sk/kill-buried-buffers ()
  "Kill user-facing buffers that are not visible in any window."
  (interactive)
  (let ((visible (mapcar #'window-buffer (window-list nil 'no-minibuf t))))
    (mapc (lambda (buffer)
            (when (and (not (memq buffer visible))
                       (buffer-live-p buffer)
                       (sk/user-buffer-p buffer))
              (kill-buffer buffer)))
          (buffer-list))
    (sk/show-dashboard-if-no-ordinary-buffers)))

(defun sk/yank-buffer-contents ()
  "Copy the current buffer contents to the kill ring."
  (interactive)
  (kill-new (buffer-substring-no-properties (point-min) (point-max)))
  (message "Copied buffer contents"))

(defun sk/current-file ()
  "Return the current buffer file or raise a user error."
  (or (buffer-file-name)
      (user-error "Current buffer is not visiting a file")))

(defun sk/find-file-here ()
  "Find a file from the current file's directory."
  (interactive)
  (let ((default-directory (or (file-name-directory (buffer-file-name))
                               default-directory)))
    (call-interactively #'find-file)))

(defun sk/copy-current-file (target)
  "Copy the current file to TARGET."
  (interactive
   (let ((file (sk/current-file)))
     (list (read-file-name "Copy current file to: "
                           (file-name-directory file)
                           nil nil
                           (file-name-nondirectory file)))))
  (copy-file (sk/current-file) target 1)
  (message "Copied file to %s" target))

(defun sk/delete-current-file ()
  "Move the current file to trash, then kill its buffer."
  (interactive)
  (let ((file (sk/current-file)))
    (when (yes-or-no-p (format "Move %s to trash? " file))
      (delete-file file t)
      (kill-buffer (current-buffer))
      (sk/show-dashboard-if-no-ordinary-buffers)
      (message "Moved file to trash: %s" file))))

(defun sk/rename-current-file (target)
  "Rename or move the current file to TARGET."
  (interactive
   (let ((file (sk/current-file)))
     (list (read-file-name "Rename/move current file to: "
                           (file-name-directory file)
                           nil nil
                           (file-name-nondirectory file)))))
  (rename-file (sk/current-file) target 1)
  (set-visited-file-name target t t))

(defun sk/sudo-file-name (file)
  "Return a TRAMP sudo path for FILE."
  (concat "/sudo:root@localhost:" (expand-file-name file)))

(defun sk/sudo-find-file (file)
  "Open FILE through sudo."
  (interactive "FSudo find file: ")
  (find-file (sk/sudo-file-name file)))

(defun sk/sudo-current-file ()
  "Reopen the current file through sudo."
  (interactive)
  (find-alternate-file (sk/sudo-file-name (sk/current-file))))

(defun sk/current-file-path (&optional relative)
  "Return the current file path, optionally RELATIVE to project root."
  (let ((file (sk/current-file)))
    (if (not relative)
        file
      (if-let ((project (project-current nil)))
          (file-relative-name file (project-root project))
        (file-name-nondirectory file)))))

(defun sk/yank-current-file-path ()
  "Copy the current file path to the kill ring."
  (interactive)
  (let ((path (sk/current-file-path)))
    (kill-new path)
    (message "Copied %s" path)))

(defun sk/yank-current-file-path-relative ()
  "Copy the project-relative current file path to the kill ring."
  (interactive)
  (let ((path (sk/current-file-path t)))
    (kill-new path)
    (message "Copied %s" path)))

(defun sk/restart-emacs-daemon ()
  "Restart the user Emacs daemon and open a fresh graphical client frame."
  (interactive)
  (when (y-or-n-p "Restart Emacs daemon and reopen a frame? ")
    (save-some-buffers)
    (let* ((unit (format "sk-emacs-restart-%s" (emacs-pid)))
           (client-command "emacsclient --create-frame --alternate-editor=false")
           (restart-command (format "sleep 0.2; systemctl --user restart emacs.service; i=0; while [ \"$i\" -lt 80 ]; do emacsclient --alternate-editor=false --eval '(emacs-pid)' >/dev/null 2>&1 && exec %s; i=$((i + 1)); sleep 0.1; done; echo 'emacs daemon did not become ready' >&2; exit 1"
                                    client-command)))
      (unless (executable-find "systemd-run")
        (user-error "Emacs daemon restart is currently wired for systemd user services only"))
      (start-process "sk-emacs-restart" nil
                     "systemd-run" "--user" "--quiet" "--collect"
                     (concat "--unit=" unit)
                     "sh" "-lc" restart-command)
      (message "Restarting Emacs daemon..."))))

(defun sk/emacs-sync ()
  "Run the Emacs package/config sync command in the background."
  (interactive)
  (unless (executable-find "emacs-sync")
    (user-error "emacs-sync is not available"))
  (let* ((buffer (get-buffer-create " *emacs-sync*"))
         (process (start-process "emacs-sync" buffer "emacs-sync")))
    (with-current-buffer buffer
      (erase-buffer))
    (set-process-query-on-exit-flag process nil)
    (set-process-sentinel
     process
     (lambda (proc _event)
       (when (memq (process-status proc) '(exit signal))
         (if (= (process-exit-status proc) 0)
             (message "emacs-sync complete")
           (message "emacs-sync failed; output is in %s"
                    (buffer-name (process-buffer proc)))))))
    (message "emacs-sync started...")))

(defun sk/read-project-root ()
  "Return the current project root or raise a user error."
  (or (when-let ((project (project-current nil)))
        (project-root project))
      (user-error "Not in a project")))

(defun sk/search-project ()
  "Search the current project with ripgrep."
  (interactive)
  (consult-ripgrep (sk/read-project-root)))

(defun sk/search-project-symbol-at-point ()
  "Search the current project for the symbol at point."
  (interactive)
  (consult-ripgrep (sk/read-project-root) (thing-at-point 'symbol t)))

(defun sk/search-current-directory ()
  "Search the current directory with ripgrep."
  (interactive)
  (consult-ripgrep default-directory))

(defun sk/search-other-directory (directory)
  "Search DIRECTORY with ripgrep."
  (interactive "DSearch directory: ")
  (consult-ripgrep directory))

(defun sk/search-buffer-symbol-at-point ()
  "Search the current buffer for the symbol at point."
  (interactive)
  (consult-line (thing-at-point 'symbol t)))

(defun sk/project-run-shell-command (command)
  "Run shell COMMAND from the current project root."
  (interactive (list (read-shell-command "Project shell command: ")))
  (let ((default-directory (sk/read-project-root)))
    (compile command)))

(defun sk/project-run-async-shell-command (command)
  "Run async shell COMMAND from the current project root."
  (interactive (list (read-shell-command "Project async shell command: ")))
  (let ((default-directory (sk/read-project-root)))
    (async-shell-command command)))

(defun sk/project-compile ()
  "Run `compile' from the current project root."
  (interactive)
  (let ((default-directory (sk/read-project-root)))
    (call-interactively #'compile)))

(defun sk/project-recompile ()
  "Run `recompile' from the current project root."
  (interactive)
  (let ((default-directory (or (when-let ((project (project-current nil)))
                                (project-root project))
                              default-directory)))
    (recompile)))

(defun sk/project-edit-dir-locals ()
  "Open the current project's .dir-locals.el file."
  (interactive)
  (find-file (expand-file-name ".dir-locals.el" (sk/read-project-root))))

(defun sk/project-find-file-in-other-project ()
  "Pick another known project and find a file in it."
  (interactive)
  (let ((default-directory (project-prompt-project-dir)))
    (call-interactively #'project-find-file)))

(defun sk/project-save-buffers ()
  "Save file buffers that belong to the current project."
  (interactive)
  (let ((root (sk/read-project-root))
        (saved 0))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when-let ((file (buffer-file-name)))
          (when (and (buffer-modified-p)
                     (file-in-directory-p file root))
            (save-buffer)
            (setq saved (1+ saved))))))
    (message "Saved %d project buffer%s" saved (if (= saved 1) "" "s"))))

(defun sk/project-kill-buffers ()
  "Kill file buffers that belong to the current project."
  (interactive)
  (let ((root (sk/read-project-root))
        (killed 0))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when-let ((file (buffer-file-name)))
          (when (file-in-directory-p file root)
            (kill-buffer buffer)
            (setq killed (1+ killed))))))
    (message "Killed %d project buffer%s" killed (if (= killed 1) "" "s"))))

(defun sk/project-recent-file ()
  "Find a recent file inside the current project."
  (interactive)
  (let* ((root (sk/read-project-root))
         (files (seq-filter (lambda (file) (file-in-directory-p file root))
                            recentf-list)))
    (if files
        (find-file (completing-read "Recent project file: " files nil t))
      (user-error "No recent files for this project"))))

(defun sk/lsp-managed-p ()
  "Return non-nil when the current buffer is managed by lsp-mode."
  (bound-and-true-p lsp-mode))

(defun sk/code-action ()
  "Run code actions through the active language-server backend."
  (interactive)
  (cond
   ((and (sk/lsp-managed-p)
         (fboundp 'lsp-execute-code-action))
    (call-interactively #'lsp-execute-code-action))
   ((eglot-managed-p)
    (call-interactively #'eglot-code-actions))
   (t
    (user-error "Current buffer is not managed by a language server"))))

(defun sk/code-rename ()
  "Rename symbol through the active language-server backend."
  (interactive)
  (cond
   ((and (sk/lsp-managed-p)
         (fboundp 'lsp-rename))
    (call-interactively #'lsp-rename))
   ((eglot-managed-p)
    (call-interactively #'eglot-rename))
   (t
    (user-error "Current buffer is not managed by a language server"))))

(defun sk/code-implementation ()
  "Find implementation through the active language-server backend."
  (interactive)
  (cond
   ((and (sk/lsp-managed-p)
         (fboundp 'lsp-find-implementation))
    (call-interactively #'lsp-find-implementation))
   ((eglot-managed-p)
    (call-interactively #'eglot-find-implementation))
   (t
    (user-error "Current buffer is not managed by a language server"))))

(defun sk/code-type-definition ()
  "Find type definition through the active language-server backend."
  (interactive)
  (cond
   ((and (sk/lsp-managed-p)
         (fboundp 'lsp-find-type-definition))
    (call-interactively #'lsp-find-type-definition))
   ((eglot-managed-p)
    (call-interactively #'eglot-find-typeDefinition))
   (t
    (user-error "Current buffer is not managed by a language server"))))

(defun sk/code-reference-identifier-at-point ()
  "Return the Xref identifier at point, falling back to the symbol at point."
  (or (ignore-errors
        (xref-backend-identifier-at-point (xref-find-backend)))
      (thing-at-point 'symbol t)))

(defun sk/code-references (&optional prompt)
  "Find references for the identifier at point.
With PROMPT, use the normal `xref-find-references' prompt."
  (interactive "P")
  (if prompt
      (call-interactively #'xref-find-references)
    (if-let ((identifier (sk/code-reference-identifier-at-point)))
        (xref-find-references identifier)
      (call-interactively #'xref-find-references))))

(defun sk/code-symbols ()
  "Show symbols in the current buffer."
  (interactive)
  (consult-imenu))

(defun sk/code-docs ()
  "Display live documentation for the thing at point."
  (interactive)
  (eldoc-mode 1)
  (eldoc-print-current-symbol-info)
  (eldoc-doc-buffer t))

(defun sk/code-errors ()
  "Show diagnostics through the active diagnostics backend."
  (interactive)
  (cond
   ((and (bound-and-true-p flycheck-mode)
         (fboundp 'flycheck-list-errors))
    (call-interactively #'flycheck-list-errors))
   ((fboundp 'flymake-show-buffer-diagnostics)
    (call-interactively #'flymake-show-buffer-diagnostics))
   (t
    (user-error "No diagnostics backend is active"))))

(defun sk/xref-next-and-preview ()
  "Move to the next Xref result and preview its source location."
  (interactive)
  (xref-next-line)
  (xref-show-location-at-point))

(defun sk/xref-previous-and-preview ()
  "Move to the previous Xref result and preview its source location."
  (interactive)
  (xref-prev-line)
  (xref-show-location-at-point))

(defun sk/tabulated-list-move-to-entry (direction)
  "Move to the next tabulated-list entry in DIRECTION."
  (let ((step (if (< direction 0) -1 1))
        (found nil))
    (while (and (not found)
                (= (forward-line step) 0)
                (not (if (< step 0) (bobp) (eobp))))
      (setq found (tabulated-list-get-id)))
    found))

(defun sk/flymake-diagnostics-next-and-preview ()
  "Move to the next Flymake diagnostic and preview its source location."
  (interactive)
  (when (sk/tabulated-list-move-to-entry 1)
    (save-selected-window
      (flymake-show-diagnostic (point) t))))

(defun sk/flymake-diagnostics-previous-and-preview ()
  "Move to the previous Flymake diagnostic and preview its source location."
  (interactive)
  (when (sk/tabulated-list-move-to-entry -1)
    (save-selected-window
      (flymake-show-diagnostic (point) t))))

(defun sk/save-buffer-and-quit ()
  "Save the current file buffer, then quit this Emacs client/session."
  (interactive)
  (when (buffer-file-name)
    (save-buffer))
  (save-buffers-kill-terminal))

(defconst sk/reload-module-files
  '("sk-package"
    "sk-core"
    "sk-theme"
    "sk-ui"
    "sk-windows"
    "sk-solaire"
    "sk-spacious"
    "sk-tabline"
    "sk-evil"
    "sk-completion"
    "sk-languages"
    "sk-treesit"
    "sk-lsp"
    "sk-format"
    "sk-org"
    "sk-notes"
    "sk-dired"
    "sk-terminal"
    "sk-ledger"
    "sk-devdocs"
    "sk-project"
    "sk-git"
    "sk-keybindings")
  "Sky Emacs modules to reload with `sk/reload-config'.")

(defun sk/reload-config ()
  "Reload the clean Sky Emacs config modules."
  (interactive)
  (when (fboundp 'corfu-quit)
    (ignore-errors (corfu-quit)))
  (dolist (file sk/reload-module-files)
    (load (expand-file-name file sk/lisp-directory) nil 'nomessage))
  (when (fboundp 'yas-reload-all)
    (yas-reload-all))
  (when (fboundp 'sk/refresh-completion-modes)
    (sk/refresh-completion-modes))
  (message "Sky Emacs config reloaded"))

(defun sk/split-window-right-and-focus ()
  "Split the current window to the right and focus the new window."
  (interactive)
  (split-window-right)
  (windmove-right))

(defun sk/split-window-below-and-focus ()
  "Split the current window below and focus the new window."
  (interactive)
  (split-window-below)
  (windmove-down))

(defun sk/next-window ()
  "Move to the next window."
  (interactive)
  (other-window 1))

(defun sk/previous-window ()
  "Move to the previous window."
  (interactive)
  (other-window -1))

(defun sk/resize-window-left ()
  "Resize the current window left by shrinking width."
  (interactive)
  (shrink-window-horizontally 5))

(defun sk/resize-window-right ()
  "Resize the current window right by enlarging width."
  (interactive)
  (enlarge-window-horizontally 5))

(defun sk/resize-window-down ()
  "Resize the current window down by shrinking height."
  (interactive)
  (shrink-window 3))

(defun sk/resize-window-up ()
  "Resize the current window up by enlarging height."
  (interactive)
  (enlarge-window 3))

(defvar sk/leader-map (make-sparse-keymap)
  "Root keymap for Sky leader commands.")

(defvar sk/file-map (make-sparse-keymap)
  "File commands under `sk/leader-map'.")

(defvar sk/buffer-map (make-sparse-keymap)
  "Buffer commands under `sk/leader-map'.")

(defvar sk/window-map (make-sparse-keymap)
  "Window commands under `sk/leader-map'.")

(defvar sk/project-map (make-sparse-keymap)
  "Project commands under `sk/leader-map'.")

(defvar sk/search-map (make-sparse-keymap)
  "Search commands under `sk/leader-map'.")

(defvar sk/code-map (make-sparse-keymap)
  "Code commands under `sk/leader-map'.")

(defvar sk/git-map (make-sparse-keymap)
  "Git commands under `sk/leader-map'.")

(defvar sk/notes-map (make-sparse-keymap)
  "Notes commands under `sk/leader-map'.")

(defvar sk/open-map (make-sparse-keymap)
  "Open/tool commands under `sk/leader-map'.")

(defvar sk/toggle-map (make-sparse-keymap)
  "Toggle commands under `sk/leader-map'.")

(defvar sk/tab-map (make-sparse-keymap)
  "Tab commands under `sk/leader-map'.")

(defvar sk/help-map (make-sparse-keymap)
  "Help commands under `sk/leader-map'.")

(defvar sk/help-reload-map (make-sparse-keymap)
  "Reload commands under `sk/help-map'.")

(defvar sk/quit-map (make-sparse-keymap)
  "Quit/session commands under `sk/leader-map'.")

(define-key sk/leader-map (kbd "SPC") #'execute-extended-command)
(define-key sk/leader-map (kbd ":") #'execute-extended-command)
(define-key sk/leader-map (kbd ".") #'find-file)
(define-key sk/leader-map (kbd ",") #'consult-buffer)
(define-key sk/leader-map (kbd "`") #'sk/switch-to-last-buffer)
(define-key sk/leader-map (kbd "/") #'sk/search-project)
(define-key sk/leader-map (kbd "*") #'sk/search-project-symbol-at-point)
(define-key sk/leader-map (kbd "u") #'universal-argument)
(define-key sk/leader-map (kbd "x") #'scratch-buffer)
(define-key sk/leader-map (kbd "X") #'org-capture)
(define-key sk/leader-map (kbd "f") sk/file-map)
(define-key sk/leader-map (kbd "b") sk/buffer-map)
(define-key sk/leader-map (kbd "w") sk/window-map)
(define-key sk/leader-map (kbd "c") sk/code-map)
(define-key sk/leader-map (kbd "p") sk/project-map)
(define-key sk/leader-map (kbd "s") sk/search-map)
(define-key sk/leader-map (kbd "g") sk/git-map)
(define-key sk/leader-map (kbd "n") sk/notes-map)
(define-key sk/leader-map (kbd "o") sk/open-map)
(define-key sk/leader-map (kbd "t") sk/tab-map)
(define-key sk/leader-map (kbd "T") sk/toggle-map)
(define-key sk/leader-map (kbd "h") sk/help-map)
(define-key sk/leader-map (kbd "q") sk/quit-map)

(define-key sk/file-map (kbd "C") #'sk/copy-current-file)
(define-key sk/file-map (kbd "d") #'sk/open-dired)
(define-key sk/file-map (kbd "D") #'sk/delete-current-file)
(define-key sk/file-map (kbd "f") #'find-file)
(define-key sk/file-map (kbd "F") #'sk/find-file-here)
(define-key sk/file-map (kbd "l") #'locate)
(define-key sk/file-map (kbd "R") #'sk/rename-current-file)
(define-key sk/file-map (kbd "r") #'consult-recent-file)
(define-key sk/file-map (kbd "s") #'save-buffer)
(define-key sk/file-map (kbd "S") #'write-file)
(define-key sk/file-map (kbd "u") #'sk/sudo-find-file)
(define-key sk/file-map (kbd "U") #'sk/sudo-current-file)
(define-key sk/file-map (kbd "y") #'sk/yank-current-file-path)
(define-key sk/file-map (kbd "Y") #'sk/yank-current-file-path-relative)

(define-key sk/buffer-map (kbd "[") #'previous-buffer)
(define-key sk/buffer-map (kbd "]") #'next-buffer)
(define-key sk/buffer-map (kbd "b") #'consult-buffer)
(define-key sk/buffer-map (kbd "d") #'sk/kill-current-buffer)
(define-key sk/buffer-map (kbd "i") #'sk/open-ibuffer)
(define-key sk/buffer-map (kbd "k") #'sk/kill-current-buffer)
(define-key sk/buffer-map (kbd "K") #'sk/kill-all-buffers)
(define-key sk/buffer-map (kbd "l") #'sk/switch-to-last-buffer)
(define-key sk/buffer-map (kbd "m") #'bookmark-set)
(define-key sk/buffer-map (kbd "M") #'bookmark-delete)
(define-key sk/buffer-map (kbd "n") #'next-buffer)
(define-key sk/buffer-map (kbd "N") #'sk/new-empty-buffer)
(define-key sk/buffer-map (kbd "O") #'sk/kill-other-buffers)
(define-key sk/buffer-map (kbd "p") #'previous-buffer)
(define-key sk/buffer-map (kbd "r") #'revert-buffer)
(define-key sk/buffer-map (kbd "R") #'rename-buffer)
(define-key sk/buffer-map (kbd "s") #'save-buffer)
(define-key sk/buffer-map (kbd "S") #'save-some-buffers)
(define-key sk/buffer-map (kbd "x") #'scratch-buffer)
(define-key sk/buffer-map (kbd "X") #'scratch-buffer)
(define-key sk/buffer-map (kbd "y") #'sk/yank-buffer-contents)
(define-key sk/buffer-map (kbd "z") #'bury-buffer)
(define-key sk/buffer-map (kbd "Z") #'sk/kill-buried-buffers)

(define-key sk/window-map (kbd "v") #'sk/split-window-right-and-focus)
(define-key sk/window-map (kbd "s") #'sk/split-window-below-and-focus)
(define-key sk/window-map (kbd "w") #'sk/next-window)
(define-key sk/window-map (kbd "W") #'sk/previous-window)
(define-key sk/window-map (kbd "x") #'delete-window)
(define-key sk/window-map (kbd "o") #'delete-other-windows)
(define-key sk/window-map (kbd "f") #'sk/toggle-window-full-frame)
(define-key sk/window-map (kbd "=") #'balance-windows)
(define-key sk/window-map (kbd "u") #'winner-undo)
(define-key sk/window-map (kbd "U") #'winner-redo)
(define-key sk/window-map (kbd "h") #'windmove-left)
(define-key sk/window-map (kbd "j") #'windmove-down)
(define-key sk/window-map (kbd "k") #'windmove-up)
(define-key sk/window-map (kbd "l") #'windmove-right)
(define-key sk/window-map (kbd "H") #'sk/resize-window-left)
(define-key sk/window-map (kbd "J") #'sk/resize-window-down)
(define-key sk/window-map (kbd "K") #'sk/resize-window-up)
(define-key sk/window-map (kbd "L") #'sk/resize-window-right)

(define-key sk/code-map (kbd "a") #'sk/code-action)
(define-key sk/code-map (kbd "c") #'compile)
(define-key sk/code-map (kbd "C") #'recompile)
(define-key sk/code-map (kbd "d") #'xref-find-definitions)
(define-key sk/code-map (kbd "D") #'sk/code-references)
(define-key sk/code-map (kbd "f") #'sk/format-buffer-or-region)
(define-key sk/code-map (kbd "i") #'sk/code-implementation)
(define-key sk/code-map (kbd "k") #'sk/code-docs)
(define-key sk/code-map (kbd "r") #'sk/code-rename)
(define-key sk/code-map (kbd "s") #'sk/code-symbols)
(define-key sk/code-map (kbd "t") #'sk/code-type-definition)
(define-key sk/code-map (kbd "w") #'ispell-word)
(define-key sk/code-map (kbd "W") #'delete-trailing-whitespace)
(define-key sk/code-map (kbd "x") #'sk/code-errors)

(define-key sk/project-map (kbd ".") #'sk/search-project-symbol-at-point)
(define-key sk/project-map (kbd "!") #'sk/project-run-shell-command)
(define-key sk/project-map (kbd "&") #'sk/project-run-async-shell-command)
(define-key sk/project-map (kbd "c") #'sk/project-compile)
(define-key sk/project-map (kbd "C") #'sk/project-recompile)
(define-key sk/project-map (kbd "e") #'sk/project-edit-dir-locals)
(define-key sk/project-map (kbd "f") #'project-find-file)
(define-key sk/project-map (kbd "F") #'sk/project-find-file-in-other-project)
(define-key sk/project-map (kbd "k") #'sk/project-kill-buffers)
(define-key sk/project-map (kbd "o") #'find-sibling-file)
(define-key sk/project-map (kbd "p") #'project-switch-project)
(define-key sk/project-map (kbd "r") #'sk/project-recent-file)
(define-key sk/project-map (kbd "R") #'project-compile)
(define-key sk/project-map (kbd "S") #'sk/project-save-buffers)
(define-key sk/project-map (kbd "s") #'consult-ripgrep)
(define-key sk/project-map (kbd "b") #'consult-project-buffer)
(define-key sk/project-map (kbd "g") #'magit-status)
(define-key sk/project-map (kbd "t") #'sk/project-vterm)
(define-key sk/project-map (kbd "n") #'sk/project-notes)

(define-key sk/search-map (kbd ".") #'sk/search-project-symbol-at-point)
(define-key sk/search-map (kbd "b") #'consult-line)
(define-key sk/search-map (kbd "B") #'consult-line-multi)
(define-key sk/search-map (kbd "d") #'sk/search-current-directory)
(define-key sk/search-map (kbd "D") #'sk/search-other-directory)
(define-key sk/search-map (kbd "f") #'locate)
(define-key sk/search-map (kbd "s") #'consult-line)
(define-key sk/search-map (kbd "S") #'sk/search-buffer-symbol-at-point)
(define-key sk/search-map (kbd "p") #'consult-ripgrep)
(define-key sk/search-map (kbd "i") #'consult-imenu)
(define-key sk/search-map (kbd "I") #'consult-imenu-multi)
(define-key sk/search-map (kbd "m") #'bookmark-jump)

(define-key sk/git-map (kbd "g") #'magit-status)

(define-key sk/notes-map (kbd "i") #'sk/org-open-inbox)
(define-key sk/notes-map (kbd "d") #'sk/org-open-daily-note)
(define-key sk/notes-map (kbd "t") #'sk/org-open-topic-note)
(define-key sk/notes-map (kbd "p") #'sk/org-open-project-note)
(define-key sk/notes-map (kbd "o") #'sk/org-open-notes-root)
(define-key sk/notes-map (kbd "f") #'sk/org-find-note)
(define-key sk/notes-map (kbd "s") #'sk/org-search-notes)
(define-key sk/notes-map (kbd "c") #'org-capture)
(define-key sk/notes-map (kbd "a") #'sk/org-agenda)
(define-key sk/notes-map (kbd "T") #'sk/org-todo-agenda)
(define-key sk/notes-map (kbd "r") #'sk/org-daily-review)
(define-key sk/notes-map (kbd "R") #'sk/org-refresh-agenda-files)

(define-key sk/open-map (kbd "d") #'sk/devdocs-open)
(define-key sk/open-map (kbd "D") #'sk/open-dired)
(define-key sk/open-map (kbd "b") #'browse-url-of-file)
(define-key sk/open-map (kbd "e") #'sk/open-eshell)
(define-key sk/open-map (kbd "E") #'sk/open-eshell-new)
(define-key sk/open-map (kbd "f") #'make-frame)
(define-key sk/open-map (kbd "F") #'select-frame-by-name)
(define-key sk/open-map (kbd "t") #'sk/open-vterm)
(define-key sk/open-map (kbd "-") #'dired-jump)

(define-key sk/toggle-map (kbd "l") #'display-line-numbers-mode)
(define-key sk/toggle-map (kbd "w") #'visual-line-mode)

(define-key sk/tab-map (kbd "n") #'tab-new)
(define-key sk/tab-map (kbd "x") #'tab-close)
(define-key sk/tab-map (kbd "o") #'tab-close-other)
(define-key sk/tab-map (kbd "]") #'tab-next)
(define-key sk/tab-map (kbd "[") #'tab-previous)

(define-key sk/help-map (kbd "k") #'describe-key)
(define-key sk/help-map (kbd "f") #'describe-function)
(define-key sk/help-map (kbd "v") #'describe-variable)
(define-key sk/help-map (kbd "m") #'describe-mode)
(define-key sk/help-map (kbd "b") #'describe-bindings)
(define-key sk/help-map (kbd "r") sk/help-reload-map)

(define-key sk/help-reload-map (kbd "r") #'sk/reload-config)
(define-key sk/help-reload-map (kbd "s") #'sk/emacs-sync)
(define-key sk/help-reload-map (kbd "t") #'sk/load-theme)

(define-key sk/quit-map (kbd "q") #'save-buffers-kill-terminal)
(define-key sk/quit-map (kbd "a") #'save-buffers-kill-emacs)
(define-key sk/quit-map (kbd "w") #'sk/save-buffer-and-quit)
(define-key sk/quit-map (kbd "f") #'kill-emacs)
(define-key sk/quit-map (kbd "r") #'sk/restart-emacs-daemon)

(use-package which-key
  :demand t
  :config
  (setq which-key-idle-delay 0.35
        which-key-idle-secondary-delay 0.05
        which-key-sort-order #'which-key-key-order-alpha)
  (which-key-mode 1)
  (which-key-add-key-based-replacements
    "SPC f" "files"
    "SPC f C" "copy current file"
    "SPC f D" "delete current file"
    "SPC f F" "find from here"
    "SPC f R" "rename current file"
    "SPC f u" "sudo find file"
    "SPC f U" "sudo current file"
    "SPC f y" "copy file path"
    "SPC f Y" "copy project path"
    "SPC b" "buffers"
    "SPC b i" "buffer list"
    "SPC b k" "kill buffer"
    "SPC b K" "kill all buffers"
    "SPC b O" "kill other buffers"
    "SPC b x" "scratch buffer"
    "SPC b X" "scratch buffer"
    "SPC b y" "copy buffer contents"
    "SPC b z" "bury buffer"
    "SPC b Z" "kill buried buffers"
    "SPC w" "windows"
    "SPC w w" "next window"
    "SPC w W" "previous window"
    "SPC w x" "close window"
    "SPC w o" "only window"
    "SPC w f" "toggle full-frame window"
    "SPC w u" "undo window layout"
    "SPC w U" "redo window layout"
    "SPC c" "code"
    "SPC c a" "code action"
    "SPC c c" "compile"
    "SPC c d" "definition"
    "SPC c D" "references"
    "SPC c f" "format explicitly"
    "SPC c r" "rename symbol"
    "SPC c s" "symbols"
    "SPC c w" "spell word"
    "SPC c W" "delete trailing whitespace"
    "SPC c x" "diagnostics"
    "SPC p" "projects"
    "SPC p !" "project shell command"
    "SPC p &" "project async command"
    "SPC p ." "search symbol in project"
    "SPC p c" "compile project"
    "SPC p e" "edit dir-locals"
    "SPC p k" "kill project buffers"
    "SPC p r" "recent project file"
    "SPC p S" "save project buffers"
    "SPC s" "search"
    "SPC s ." "search project symbol"
    "SPC s b" "search buffer"
    "SPC s B" "search open buffers"
    "SPC s d" "search current directory"
    "SPC s D" "search other directory"
    "SPC s S" "search symbol in buffer"
    "SPC g" "git"
    "SPC n" "notes"
    "SPC n a" "agenda"
    "SPC n c" "capture"
    "SPC n d" "daily note"
    "SPC n f" "find note"
    "SPC n i" "inbox"
    "SPC n o" "open notes folder"
    "SPC n p" "project note"
    "SPC n r" "daily review"
    "SPC n R" "refresh agenda"
    "SPC n s" "search notes"
    "SPC n T" "TODO agenda"
    "SPC n t" "topic note"
    "SPC o" "open"
    "SPC o -" "dired jump"
    "SPC o b" "browser"
    "SPC o d" "devdocs helper"
    "SPC o D" "dired"
    "SPC o e" "eshell"
    "SPC o E" "named eshell"
    "SPC o f" "new frame"
    "SPC o F" "select frame"
    "SPC o t" "vterm"
    "SPC t" "tabs"
    "SPC t n" "new tab"
    "SPC t x" "close tab"
    "SPC t o" "only tab"
    "SPC T" "toggles"
    "SPC h" "help"
    "SPC h r" "reload"
    "SPC h r r" "reload config"
    "SPC h r s" "sync emacs"
    "SPC h r t" "reload theme"
    "SPC q" "quit"
    "SPC q q" "quit"
    "SPC q a" "quit emacs"
    "SPC q w" "write and quit"
    "SPC q f" "force quit"
    "SPC q r" "restart daemon"))

(with-eval-after-load 'evil
  (dolist (map (list evil-insert-state-map
                     evil-replace-state-map
                     evil-emacs-state-map
                     evil-normal-state-map
                     evil-visual-state-map
                     evil-motion-state-map))
    (define-key map (kbd "C-h") #'sk/completion-quit-or-window-left)
    (define-key map (kbd "C-j") #'sk/completion-next-or-window-down)
    (define-key map (kbd "C-k") #'sk/completion-previous-or-window-up)
    (define-key map (kbd "C-l") #'sk/completion-accept-or-window-right))

  (dolist (map (list evil-normal-state-map
                     evil-visual-state-map
                     evil-motion-state-map))
    (define-key map (kbd "SPC") sk/leader-map))

  (dolist (map (list evil-normal-state-map
                     evil-motion-state-map))
    (define-key map (kbd "TAB") #'next-buffer)
    (define-key map (kbd "<tab>") #'next-buffer)
    (define-key map (kbd "<backtab>") #'previous-buffer)
    (define-key map (kbd "S-TAB") #'previous-buffer)))

(with-eval-after-load 'ibuffer
  (with-eval-after-load 'evil
    (evil-define-key '(normal motion) ibuffer-mode-map
      (kbd "h") #'ibuffer-backward-filter-group
      (kbd "j") #'ibuffer-forward-line
      (kbd "k") #'ibuffer-backward-line
      (kbd "l") #'ibuffer-visit-buffer
      (kbd "RET") #'ibuffer-visit-buffer)))

(with-eval-after-load 'help-mode
  (with-eval-after-load 'evil
    (evil-define-key '(normal motion) help-mode-map
      (kbd "h") #'help-go-back
      (kbd "j") #'next-line
      (kbd "k") #'previous-line
      (kbd "l") #'help-go-forward
      (kbd "RET") #'push-button)))

(with-eval-after-load 'xref
  (with-eval-after-load 'evil
    (evil-define-key '(normal motion) xref--xref-buffer-mode-map
      (kbd "j") #'sk/xref-next-and-preview
      (kbd "k") #'sk/xref-previous-and-preview
      (kbd "l") #'xref-goto-xref
      (kbd "RET") #'xref-goto-xref
      (kbd "q") #'quit-window)))

(with-eval-after-load 'flycheck
  (with-eval-after-load 'evil
    (evil-define-key '(normal motion) flycheck-error-list-mode-map
      (kbd "j") #'flycheck-error-list-next-error
      (kbd "k") #'flycheck-error-list-previous-error
      (kbd "l") #'flycheck-error-list-goto-error
      (kbd "RET") #'flycheck-error-list-goto-error
      (kbd "q") #'quit-window)))

(with-eval-after-load 'flymake
  (with-eval-after-load 'evil
    (evil-define-key '(normal motion) flymake-diagnostics-buffer-mode-map
      (kbd "j") #'sk/flymake-diagnostics-next-and-preview
      (kbd "k") #'sk/flymake-diagnostics-previous-and-preview
      (kbd "l") #'flymake-goto-diagnostic
      (kbd "RET") #'flymake-goto-diagnostic
      (kbd "q") #'quit-window)))

(provide 'sk-keybindings)

;;; sk-keybindings.el ends here
