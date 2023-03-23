;;; org-gtd-capture.el --- capturing items to the inbox -*- lexical-binding: t; coding: utf-8 -*-
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
;; capturing items to the inbox for org-gtd.
;;
;;; Code:

(require 'org-capture)
(require 'org-gtd-core)
(require 'org-gtd-files)

(defcustom org-gtd-capture-templates
  `(("i" "Inbox"
        entry  (file ,#'org-gtd-inbox-path)
        "* %?\n%U\n\n  %i"
        :kill-buffer t)
    ("l" "Inbox with link"
        entry (file ,#'org-gtd-inbox-path)
        "* %?\n%U\n\n  %i\n  %a"
        :kill-buffer t))
  "Capture templates to be used when adding something to the inbox.

See `org-capture-templates' for the format of each capture template.
Make the sure the template string starts with a single asterisk to denote a
top level heading, or the behavior of org-gtd will be undefined."
  :group 'org-gtd
  :type 'sexp
  :package-version '(org-gtd . "2.0.0"))

;;;###autoload
(defun org-gtd-capture (&optional goto keys)
  "Capture something into the GTD inbox.

Wraps the function `org-capture' to ensure the inbox exists.

For GOTO and KEYS, see `org-capture' documentation for the variables of the same name."
  (interactive)
  (with-org-gtd-context
      (org-capture goto keys)))

(provide 'org-gtd-capture)
;;; org-gtd-capture.el ends here
