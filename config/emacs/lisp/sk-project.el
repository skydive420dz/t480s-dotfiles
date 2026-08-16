;;; sk-project.el --- Project and search commands -*- lexical-binding: t; -*-

(use-package project
  :ensure nil)

(defun sk/project-root ()
  "Return the current project root, or nil outside a project."
  (when-let ((project (project-current nil)))
    (project-root project)))

(defun sk/project-vterm ()
  "Open vterm from the project root when possible."
  (interactive)
  (let ((default-directory (or (sk/project-root) default-directory)))
    (sk/open-vterm)))

(defun sk/project-notes ()
  "Open a note for the current project."
  (interactive)
  (if-let ((root (sk/project-root)))
      (let* ((name (file-name-nondirectory (directory-file-name root)))
             (file (expand-file-name
                    (concat "projects/" name ".org")
                    sk/org-notes-root)))
        (find-file (sk/org--ensure-file
                    file
                    name
                    "* Overview\n* Tasks\n* Notes\n* Decisions\n* Follow-up\n")))
    (call-interactively #'sk/org-open-project-note)))

(global-set-key (kbd "C-c p f") #'project-find-file)
(global-set-key (kbd "C-c p p") #'project-switch-project)
(global-set-key (kbd "C-c p s") #'consult-ripgrep)

(provide 'sk-project)

;;; sk-project.el ends here
