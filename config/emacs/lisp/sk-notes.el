;;; sk-notes.el --- Personal note workflow -*- lexical-binding: t; -*-

(require 'subr-x)

(defvar sk/org-notes-root (expand-file-name "~/Documents/notes/")
  "Root directory for personal Org notes.")

(defconst sk/org-daily-note-template
  "* Today
** Focus
** Tasks
** Notes
** Questions
** Follow-up
** Review
- [ ] Process inbox into tasks, projects, topics, or archive.
- [ ] Clarify open TODOs and decide what still matters.
- [ ] Move project/topic notes where they belong.
- [ ] Mark follow-ups and waiting items.
- [ ] Choose tomorrow's first focus.
"
  "Body inserted into newly-created daily notes.")

(defun sk/org-agenda-note-files ()
  "Return every Org note file under `sk/org-notes-root'."
  (when (file-directory-p sk/org-notes-root)
    (directory-files-recursively sk/org-notes-root "\\.org\\'")))

(defun sk/org-refresh-agenda-files ()
  "Refresh `org-agenda-files' from the note tree."
  (interactive)
  (setq org-agenda-files (sk/org-agenda-note-files))
  (when (called-interactively-p 'interactive)
    (message "Org agenda files refreshed: %d" (length org-agenda-files))))

(defun sk/org--slugify (text)
  "Return a simple filename slug for TEXT."
  (let* ((downcased (downcase text))
         (clean (replace-regexp-in-string "[^[:alnum:]]+" "-" downcased)))
    (string-trim clean "-" "-")))

(defun sk/org--ensure-file (file title &optional body)
  "Create FILE with TITLE and optional BODY when it does not exist."
  (make-directory (file-name-directory file) t)
  (unless (file-exists-p file)
    (with-temp-file file
      (insert "#+title: " title "\n"
              "#+date: " (format-time-string "%Y-%m-%d") "\n"
              "#+startup: overview\n\n")
      (when body
        (insert body)))
    (when (boundp 'org-agenda-files)
      (sk/org-refresh-agenda-files)))
  file)

(defun sk/org-inbox-file ()
  "Return the personal inbox file, creating it if needed."
  (sk/org--ensure-file
   (expand-file-name "inbox.org" sk/org-notes-root)
   "Inbox"
   "* Inbox\n"))

(defun sk/org-daily-file ()
  "Return today's daily note file, creating it if needed."
  (let* ((year (format-time-string "%Y"))
         (date (format-time-string "%Y-%m-%d"))
         (file (expand-file-name (concat "daily/" year "/" date ".org") sk/org-notes-root)))
    (sk/org--ensure-file
     file
     date
     sk/org-daily-note-template)))

(defun sk/org-topic-file ()
  "Prompt for a topic note and return its file path, creating it if needed."
  (let* ((year (format-time-string "%Y"))
         (title (read-string "Topic: "))
         (slug (sk/org--slugify title))
         (date (format-time-string "%Y-%m-%d"))
         (file (expand-file-name (concat "topics/" year "/" date "-" slug ".org") sk/org-notes-root)))
    (sk/org--ensure-file file title "* Notes\n")))

(defun sk/org-project-file ()
  "Prompt for a project note and return its file path, creating it if needed."
  (let* ((name (read-string "Project: "))
         (slug (sk/org--slugify name))
         (file (expand-file-name (concat "projects/" slug ".org") sk/org-notes-root)))
    (sk/org--ensure-file
     file
     name
     "* Overview\n* Tasks\n* Notes\n* Decisions\n* Follow-up\n")))

(defun sk/org-open-daily-note ()
  "Open today's daily note."
  (interactive)
  (find-file (sk/org-daily-file)))

(defun sk/org-open-inbox ()
  "Open the personal inbox."
  (interactive)
  (find-file (sk/org-inbox-file)))

(defun sk/org-open-topic-note ()
  "Create or open a topic note."
  (interactive)
  (find-file (sk/org-topic-file)))

(defun sk/org-open-project-note ()
  "Create or open a project note."
  (interactive)
  (find-file (sk/org-project-file)))

(defun sk/org-open-notes-root ()
  "Open the personal notes root in Dired."
  (interactive)
  (dired sk/org-notes-root))

(defun sk/org-find-note ()
  "Find a note under `sk/org-notes-root'."
  (interactive)
  (if (fboundp 'consult-find)
      (consult-find sk/org-notes-root)
    (find-file (read-file-name "Find note: " sk/org-notes-root))))

(defun sk/org-search-notes ()
  "Search the personal notes tree."
  (interactive)
  (if (fboundp 'consult-ripgrep)
      (consult-ripgrep sk/org-notes-root)
    (rgrep (read-string "Search notes: ")
           "*.org"
           sk/org-notes-root)))

(defun sk/org-agenda ()
  "Refresh note discovery, then open Org agenda."
  (interactive)
  (sk/org-refresh-agenda-files)
  (call-interactively #'org-agenda))

(defun sk/org-todo-agenda ()
  "Refresh note discovery, then open the Org TODO agenda."
  (interactive)
  (sk/org-refresh-agenda-files)
  (org-agenda nil "t"))

(defun sk/org-daily-review ()
  "Open today's note and the daily agenda dashboard."
  (interactive)
  (sk/org-refresh-agenda-files)
  (find-file (sk/org-daily-file))
  (let ((daily-window (selected-window)))
    (split-window-right)
    (other-window 1)
    (org-agenda nil "d")
    (select-window daily-window)))

(setq org-directory sk/org-notes-root
      org-agenda-files (sk/org-agenda-note-files)
      org-default-notes-file (sk/org-inbox-file)
      org-refile-targets '((org-agenda-files :maxlevel . 3))
      org-refile-use-outline-path 'file
      org-outline-path-complete-in-steps nil
      org-refile-allow-creating-parent-nodes 'confirm)

(setq org-agenda-custom-commands
      '(("d" "Daily review"
         ((agenda "" ((org-agenda-span 'day)
                      (org-agenda-overriding-header "Today")))
          (todo "TODO" ((org-agenda-overriding-header "Open tasks")))))
        ("w" "Week"
         agenda ""
         ((org-agenda-span 'week)))
        ("i" "Inbox"
         tags "CATEGORY=\"inbox\""
         ((org-agenda-overriding-header "Inbox")))
        ("f" "Follow-up"
         search "Follow-up"
         ((org-agenda-overriding-header "Follow-up")))))

(setq org-capture-templates
      '(("i" "Inbox note" entry
         (file+headline sk/org-inbox-file "Inbox")
         "* %?\n  %U\n"
         :empty-lines 1)
        ("t" "Todo" entry
         (file+headline sk/org-inbox-file "Inbox")
         "* TODO %?\n  %U\n")
        ("d" "Daily note" entry
         (file+headline sk/org-daily-file "Notes")
         "* %?\n  %U\n"
         :empty-lines 1)
        ("T" "Topic note" entry
         (file+headline sk/org-topic-file "Notes")
         "* %?\n  %U\n"
         :empty-lines 1)
        ("p" "Project note" entry
         (file+headline sk/org-project-file "Notes")
         "* %?\n  %U\n"
         :empty-lines 1)))

(global-set-key (kbd "C-c n i") #'sk/org-open-inbox)
(global-set-key (kbd "C-c n d") #'sk/org-open-daily-note)
(global-set-key (kbd "C-c n t") #'sk/org-open-topic-note)
(global-set-key (kbd "C-c n p") #'sk/org-open-project-note)
(global-set-key (kbd "C-c n o") #'sk/org-open-notes-root)
(global-set-key (kbd "C-c n f") #'sk/org-find-note)
(global-set-key (kbd "C-c n s") #'sk/org-search-notes)
(global-set-key (kbd "C-c n c") #'org-capture)
(global-set-key (kbd "C-c n a") #'sk/org-agenda)
(global-set-key (kbd "C-c n T") #'sk/org-todo-agenda)
(global-set-key (kbd "C-c n r") #'sk/org-daily-review)
(global-set-key (kbd "C-c n R") #'sk/org-refresh-agenda-files)

(provide 'sk-notes)

;;; sk-notes.el ends here
