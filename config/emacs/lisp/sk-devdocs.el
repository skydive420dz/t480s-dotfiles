;;; sk-devdocs.el --- DevDocs helper panel -*- lexical-binding: t; -*-

(require 'seq)
(require 'subr-x)
(require 'tabulated-list)

(defvar devdocs-current-docs)
(declare-function devdocs--available-docs "devdocs")
(declare-function devdocs--doc-title "devdocs")
(declare-function devdocs--entries "devdocs")
(declare-function devdocs--installed-docs "devdocs")
(declare-function devdocs--render "devdocs")
(declare-function devdocs-goto-target "devdocs")

(use-package devdocs
  :commands (devdocs-delete
             devdocs-install
             devdocs-peruse
             devdocs-update-all))

(defvar sk/devdocs-buffer-name "*Sky DevDocs*"
  "Name of the Sky DevDocs helper panel.")

(defvar-local sk/devdocs-view 'installed
  "Current Sky DevDocs panel view.")

(defvar-local sk/devdocs-query nil
  "Current Sky DevDocs filter or search query.")

(defvar-local sk/devdocs-items nil
  "Alist mapping row IDs to DevDocs item plists.")

(defvar-local sk/devdocs-status nil
  "Status line text for the Sky DevDocs panel.")

(defvar sk/devdocs-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map (kbd "RET") #'sk/devdocs-act)
    (define-key map (kbd "a") #'sk/devdocs-available)
    (define-key map (kbd "f") #'sk/devdocs-find-in-docset)
    (define-key map (kbd "g") #'sk/devdocs-refresh)
    (define-key map (kbd "i") #'sk/devdocs-install-selected)
    (define-key map (kbd "j") #'next-line)
    (define-key map (kbd "k") #'previous-line)
    (define-key map (kbd "r") #'sk/devdocs-remove-selected)
    (define-key map (kbd "s") #'sk/devdocs-search-installed)
    (define-key map (kbd "u") #'sk/devdocs-update-all)
    (define-key map (kbd "?") #'sk/devdocs-help)
    (define-key map (kbd "q") #'quit-window)
    map)
  "Keymap for `sk/devdocs-mode'.")

(define-derived-mode sk/devdocs-mode tabulated-list-mode "Sky DevDocs"
  "Magit/Dired-style helper panel for DevDocs."
  (setq tabulated-list-format
        [("Type" 12 t)
         ("Name" 34 t)
         ("Details" 0 t)]
        tabulated-list-padding 2
        tabulated-list-sort-key nil)
  (tabulated-list-init-header))

(defun sk/devdocs--require ()
  "Load DevDocs."
  (require 'devdocs))

(defun sk/devdocs--doc-slug (doc)
  "Return the slug for DevDocs DOC metadata."
  (alist-get 'slug doc))

(defun sk/devdocs--doc-title (doc)
  "Return display title for DevDocs DOC metadata."
  (sk/devdocs--require)
  (devdocs--doc-title doc))

(defun sk/devdocs--installed-docs ()
  "Return installed DevDocs metadata."
  (sk/devdocs--require)
  (devdocs--installed-docs))

(defun sk/devdocs--available-docs ()
  "Return available DevDocs metadata."
  (sk/devdocs--require)
  (devdocs--available-docs))

(defun sk/devdocs--installed-slugs ()
  "Return installed DevDocs slugs."
  (mapcar #'sk/devdocs--doc-slug (sk/devdocs--installed-docs)))

(defun sk/devdocs--item-at-point ()
  "Return the DevDocs item plist at point."
  (let ((id (tabulated-list-get-id)))
    (or (alist-get id sk/devdocs-items nil nil #'equal)
        (user-error "No DevDocs item on this line"))))

(defun sk/devdocs--doc-candidate (doc)
  "Return a display string for DOC."
  (format "%-24s %s"
          (sk/devdocs--doc-slug doc)
          (sk/devdocs--doc-title doc)))

(defun sk/devdocs--read-installed-doc (&optional prompt)
  "Read an installed docset with PROMPT."
  (let* ((docs (sk/devdocs--installed-docs))
         (choices (mapcar (lambda (doc)
                            (cons (sk/devdocs--doc-candidate doc) doc))
                          docs)))
    (unless choices
      (user-error "No DevDocs docsets installed yet"))
    (cdr (assoc (completing-read (or prompt "Docset: ") choices nil t)
                choices))))

(defun sk/devdocs--entry-doc (entry)
  "Return the metadata doc attached to ENTRY."
  (alist-get 'doc entry))

(defun sk/devdocs--entry-detail (entry)
  "Return a compact detail string for ENTRY."
  (let ((doc (sk/devdocs--entry-doc entry))
        (type (alist-get 'type entry))
        (path (alist-get 'path entry)))
    (string-join (delq nil (list (and doc (sk/devdocs--doc-title doc))
                                 type
                                 path))
                 " / ")))

(defun sk/devdocs--row (id kind name detail item)
  "Return a tabulated row and register ITEM under ID."
  (push (cons id item) sk/devdocs-items)
  (list id (vector kind name detail)))

(defun sk/devdocs--header ()
  "Return the panel header text."
  (concat
   "Sky DevDocs  "
   (pcase sk/devdocs-view
     ('installed "Installed")
     ('available (format "Available%s" (if sk/devdocs-query
                                           (format " / %s" sk/devdocs-query)
                                         "")))
     ('search (format "Search / %s" (or sk/devdocs-query "")))
     (_ ""))
   (when sk/devdocs-status
     (format "  -  %s" sk/devdocs-status))))

(defun sk/devdocs--insert-panel-text ()
  "Insert static helper text at the top of the panel body."
  (insert "RET act  s search  f find in docset  a available  i install  r remove  u update  g refresh  q quit  ? help\n\n"))

(defun sk/devdocs--print (rows)
  "Render ROWS in the current panel."
  (setq sk/devdocs-items nil
        tabulated-list-entries rows
        header-line-format '(:eval (sk/devdocs--header)))
  (tabulated-list-print t)
  (let ((inhibit-read-only t))
    (goto-char (point-min))
    (sk/devdocs--insert-panel-text))
  (goto-char (point-min))
  (forward-line 2))

(defun sk/devdocs--render-installed ()
  "Render installed docsets."
  (let ((docs (sk/devdocs--installed-docs))
        rows)
    (setq sk/devdocs-view 'installed)
    (if docs
        (setq rows
              (seq-map-indexed
               (lambda (doc index)
                 (sk/devdocs--row
                  (format "installed:%s" index)
                  "installed"
                  (sk/devdocs--doc-slug doc)
                  (sk/devdocs--doc-title doc)
                  (list :kind 'installed :doc doc)))
               docs))
      (setq rows
            (list (sk/devdocs--row "empty:installed" "empty" "No installed docsets"
                                   "Press a to browse available docs or i to install by name."
                                   (list :kind 'empty)))))
    (sk/devdocs--print rows)))

(defun sk/devdocs--render-available (query)
  "Render available docsets matching QUERY."
  (let* ((needle (string-trim (or query "")))
         (installed (sk/devdocs--installed-slugs))
         (docs (sk/devdocs--available-docs))
         (filtered (if (string-empty-p needle)
                       docs
                     (seq-filter
                      (lambda (doc)
                        (string-match-p
                         (regexp-quote (downcase needle))
                         (downcase (sk/devdocs--doc-candidate doc))))
                      docs))))
    (setq sk/devdocs-view 'available
          sk/devdocs-query (unless (string-empty-p needle) needle))
    (sk/devdocs--print
     (if filtered
         (seq-map-indexed
          (lambda (doc index)
            (let ((slug (sk/devdocs--doc-slug doc)))
              (sk/devdocs--row
               (format "available:%s" index)
               (if (member slug installed) "installed" "available")
               slug
               (sk/devdocs--doc-title doc)
               (list :kind 'available :doc doc))))
          filtered)
       (list (sk/devdocs--row "empty:available" "empty" "No matching docsets"
                              "Press a and try another search."
                              (list :kind 'empty)))))))

(defun sk/devdocs--render-search (query &optional doc)
  "Render search results for QUERY, optionally limited to DOC."
  (let* ((needle (string-trim query))
         (docs (if doc
                   (list doc)
                 (sk/devdocs--installed-docs)))
         (entries (when docs
                    (devdocs--entries docs)))
         (filtered (seq-filter
                    (lambda (candidate)
                      (string-match-p
                       (regexp-quote (downcase needle))
                       (downcase (substring-no-properties candidate))))
                    entries)))
    (setq sk/devdocs-view 'search
          sk/devdocs-query (if doc
                               (format "%s in %s" needle (sk/devdocs--doc-title doc))
                             needle))
    (sk/devdocs--print
     (if filtered
         (seq-map-indexed
          (lambda (candidate index)
            (let ((entry (get-text-property 0 'devdocs--data candidate)))
              (sk/devdocs--row
               (format "entry:%s" index)
               "entry"
               (substring-no-properties candidate)
               (sk/devdocs--entry-detail entry)
               (list :kind 'entry :entry entry))))
          filtered)
       (list (sk/devdocs--row "empty:search" "empty" "No matching entries"
                              "Press s or f and try another query."
                              (list :kind 'empty)))))))

(defun sk/devdocs-open ()
  "Open the Sky DevDocs helper panel."
  (interactive)
  (let ((buffer (get-buffer-create sk/devdocs-buffer-name)))
    (with-current-buffer buffer
      (sk/devdocs-mode)
      (setq sk/devdocs-status nil)
      (sk/devdocs--render-installed))
    (let ((window (sk/display-buffer-right buffer 0.48)))
      (select-window window))))

(defun sk/devdocs-refresh ()
  "Refresh the current Sky DevDocs panel view."
  (interactive)
  (pcase sk/devdocs-view
    ('available (sk/devdocs--render-available sk/devdocs-query))
    ('search (sk/devdocs--render-installed))
    (_ (sk/devdocs--render-installed))))

(defun sk/devdocs-available (query)
  "Show available DevDocs docsets matching QUERY."
  (interactive "sAvailable docsets search: ")
  (setq sk/devdocs-status nil)
  (sk/devdocs--render-available query))

(defun sk/devdocs-search-installed (query)
  "Search all installed docsets for QUERY and show results in the panel."
  (interactive "sSearch installed docs: ")
  (unless (sk/devdocs--installed-docs)
    (user-error "No DevDocs docsets installed yet"))
  (setq sk/devdocs-status nil)
  (sk/devdocs--render-search query))

(defun sk/devdocs-find-in-docset (query)
  "Search selected or chosen docset for QUERY."
  (interactive "sFind in docset: ")
  (let* ((item (ignore-errors (sk/devdocs--item-at-point)))
         (doc (or (plist-get item :doc)
                  (sk/devdocs--read-installed-doc "Find in docset: "))))
    (setq sk/devdocs-status nil)
    (sk/devdocs--render-search query doc)))

(defun sk/devdocs--open-entry (entry)
  "Open DevDocs ENTRY."
  (let* ((buffer (devdocs--render entry))
         (window (display-buffer buffer)))
    (when window
      (with-selected-window window
        (devdocs-goto-target)
        (recenter 0))
      (select-window window))))

(defun sk/devdocs-act ()
  "Act on the selected panel item."
  (interactive)
  (let* ((item (sk/devdocs--item-at-point))
         (kind (plist-get item :kind)))
    (pcase kind
      ('installed (devdocs-peruse (plist-get item :doc)))
      ('available (sk/devdocs-install-selected))
      ('entry (sk/devdocs--open-entry (plist-get item :entry)))
      (_ (user-error "Nothing to do on this line")))))

(defun sk/devdocs-install-selected ()
  "Install the selected available docset, or prompt for one."
  (interactive)
  (let* ((item (ignore-errors (sk/devdocs--item-at-point)))
         (doc (or (and (eq (plist-get item :kind) 'available)
                       (plist-get item :doc))
                  (let* ((docs (sk/devdocs--available-docs))
                         (choices (mapcar (lambda (doc)
                                            (cons (sk/devdocs--doc-candidate doc) doc))
                                          docs)))
                    (cdr (assoc (completing-read "Install docset: " choices nil t)
                                choices))))))
    (devdocs-install doc)
    (setq sk/devdocs-status
          (format "Installed %s" (sk/devdocs--doc-title doc)))
    (sk/devdocs--render-installed)))

(defun sk/devdocs-remove-selected ()
  "Remove the selected installed docset, or prompt for one."
  (interactive)
  (let* ((item (ignore-errors (sk/devdocs--item-at-point)))
         (doc (or (and (eq (plist-get item :kind) 'installed)
                       (plist-get item :doc))
                  (sk/devdocs--read-installed-doc "Remove docset: "))))
    (when (y-or-n-p (format "Remove %s? " (sk/devdocs--doc-title doc)))
      (devdocs-delete doc)
      (setq sk/devdocs-status
            (format "Removed %s" (sk/devdocs--doc-title doc)))
      (sk/devdocs--render-installed))))

(defun sk/devdocs-update-all ()
  "Update installed DevDocs docsets and refresh the panel."
  (interactive)
  (devdocs-update-all)
  (setq sk/devdocs-status "Update finished")
  (sk/devdocs--render-installed))

(defun sk/devdocs-help ()
  "Show DevDocs helper help."
  (interactive)
  (message "DevDocs panel: j/k move, RET act, a available, i install, r remove, s search all, f find selected docset, u update, g refresh, q quit"))

(provide 'sk-devdocs)

;;; sk-devdocs.el ends here
