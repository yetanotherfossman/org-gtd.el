;;; org-gtd-archive.el --- Logic to archive tasks -*- lexical-binding: t; coding: utf-8 -*-
;;
;; Copyright © 2019-2023 Aldric Giacomoni

;; Author: Aldric Giacomoni <trevoke@gmail.com>
;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Archiving logic for org-gtd
;;
;;; Code:

(require 'f)
(require 'org-archive)
(require 'org-element)
(require 'org-gtd-core)
(require 'org-gtd-agenda)

(defgroup org-gtd-archive nil
  "How to archive completed / canceled items."
  :package-version '(org-gtd . "3.0.0")
  :group 'org-gtd)

(defcustom org-gtd-archive-location #'org-gtd-archive-location-func
  "Function to generate archive location for org gtd.

That is to say, when items get cleaned up from the active files, they will go
to whatever file/tree is generated by this function.  See `org-archive-location'
to learn more about the valid values generated.  Note that this will only be
the file used by the standard `org-archive' functions if you
enable command `org-gtd-mode'.  If not, this will be used only by
org-gtd's archive behavior.

This function has an arity of zero.  By default this generates a file
called gtd_archive_<currentyear> in `org-gtd-directory' and puts the entries
into a datetree."
  :group 'org-gtd-archive
  :type 'sexp
  :package-version '(org-gtd . "2.0.0"))

(defconst org-gtd-archive-file-format "gtd_archive_%s"
  "File name format for where org-gtd archives things by default.")

(defun org-gtd-archive-item-at-point ()
  "Dirty hack to force archiving where I know I can."
  (interactive)
  (let* ((last-command nil)
         (temp-file (make-temp-file org-gtd-directory nil ".org"))
         (buffer (find-file-noselect temp-file)))
    (org-copy-subtree)
    (org-gtd-core-prepare-buffer buffer)
    (with-current-buffer buffer
      (org-paste-subtree)
      (goto-char (point-min))
      (with-org-gtd-context (org-archive-subtree))
      (basic-save-buffer)
      (kill-buffer))
    (delete-file temp-file)))

(defun org-gtd-archive-location-func ()
  "Default function to define where to archive items."
  (let* ((year (number-to-string (caddr (calendar-current-date))))
         (full-org-gtd-path (expand-file-name org-gtd-directory))
         (filename (format org-gtd-archive-file-format year))
         (filepath (f-join full-org-gtd-path filename)))
    (string-join `(,filepath "::" "datetree/"))))

;;;###autoload
(defun org-gtd-archive-completed-items ()
  "Archive everything that needs to be archived in your org-gtd."
  (interactive)
  (org-gtd-core-prepare-agenda-buffers)
  (with-org-gtd-context
      (org-gtd--archive-complete-projects)
      (org-map-entries #'org-gtd--archive-completed-actions
                       "+LEVEL=2&+ORG_GTD=\"Actions\""
                       'agenda)
    (org-map-entries #'org-gtd--archive-completed-actions
                     "+LEVEL=2&+ORG_GTD=\"Calendar\""
                     'agenda)
    (org-map-entries #'org-gtd--archive-completed-actions
                     "+LEVEL=2&+ORG_GTD=\"Incubated\""
                     'agenda)))

(defun org-gtd--archive-complete-projects ()
  "Archive all projects for which all actions/tasks are marked as done.

Done here is any done `org-todo-keyword'.  For org-gtd this means `org-gtd-done'
or `org-gtd-canceled'."
  (org-map-entries
   (lambda ()

     (when (org-gtd--all-subheadings-in-done-type-p)
       (setq org-map-continue-from
             (org-element-property :begin (org-element-at-point)))

       (org-archive-subtree-default)))
   "+LEVEL=2&+ORG_GTD=\"Projects\""
   'agenda))

(defun org-gtd--all-subheadings-in-done-type-p ()
  "Return t if every sub-heading is `org-gtd-done' or `org-gtd-canceled'."
  (seq-every-p (lambda (x) (eq x 'done))
               (org-map-entries (lambda ()
                                  (org-element-property :todo-type (org-element-at-point)))
                                "+LEVEL=3"
                                'tree)))

(defun org-gtd--archive-completed-actions ()
  "Private function.  With point on heading, archive if entry is done."
  (if (org-entry-is-done-p)
      (progn
        (setq org-map-continue-from (org-element-property
                                     :begin
                                     (org-element-at-point)))
        (org-archive-subtree-default))))

(provide 'org-gtd-archive)
;;; org-gtd-archive.el ends here
