;;; copyright.el --- update the copyright notice in current buffer

;; Copyright (C) 1991, 92, 93, 94, 95, 1998, 2001, 2003, 2004
;;           Free Software Foundation, Inc.

;; Author: Daniel Pfeiffer <occitan@esperanto.org>
;; Keywords: maint, tools

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Allows updating the copyright year and above mentioned GPL version manually
;; or when saving a file.
;; Do (add-hook 'write-file-functions 'copyright-update).

;;; Code:

(defgroup copyright nil
  "Update the copyright notice in current buffer."
  :group 'tools)

(defcustom copyright-limit 2000
  "*Don't try to update copyright beyond this position unless interactive.
A value of nil means to search whole buffer."
  :group 'copyright
  :type '(choice (integer :tag "Limit")
		 (const :tag "No limit")))

;; The character classes have the Latin-1 version and the Latin-9
;; version, which is probably enough.
(defcustom copyright-regexp
 "\\([����]\\|@copyright{}\\|[Cc]opyright\\s *:?\\s *\\(?:(C)\\)?\
\\|[Cc]opyright\\s *:?\\s *[����]\\)\
\\s *\\([1-9]\\([-0-9, ';%#\n\t]\\|\\s<\\|\\s>\\)*[0-9]+\\)"
  "*What your copyright notice looks like.
The second \\( \\) construct must match the years."
  :group 'copyright
  :type 'regexp)


(defcustom copyright-query 'function
  "*If non-nil, ask user before changing copyright.
When this is `function', only ask when called non-interactively."
  :group 'copyright
  :type '(choice (const :tag "Do not ask")
		 (const :tag "Ask unless interactive" function)
		 (other :tag "Ask" t)))


;; when modifying this, also modify the comment generated by autoinsert.el
(defconst copyright-current-gpl-version "2"
  "String representing the current version of the GPL or nil.")

(defvar copyright-update t)

;; This is a defvar rather than a defconst, because the year can
;; change during the Emacs session.
(defvar copyright-current-year (substring (current-time-string) -4)
  "String representing the current year.")

(defun copyright-update-year (replace noquery)
  (when (re-search-forward copyright-regexp (+ (point) copyright-limit) t)
    ;; Note that `current-time-string' isn't locale-sensitive.
    (setq copyright-current-year (substring (current-time-string) -4))
    (unless (string= (buffer-substring (- (match-end 2) 2) (match-end 2))
		     (substring copyright-current-year -2))
      (if (or noquery
	      (y-or-n-p (if replace
			    (concat "Replace copyright year(s) by "
				    copyright-current-year "? ")
			  (concat "Add " copyright-current-year
				  " to copyright? "))))
	  (if replace
	      (replace-match copyright-current-year t t nil 1)
	    (let ((size (save-excursion (skip-chars-backward "0-9"))))
	      (if (and (eq (% (- (string-to-number copyright-current-year)
				 (string-to-number (buffer-substring
						    (+ (point) size)
						    (point))))
			      100)
			   1)
		       (or (eq (char-after (+ (point) size -1)) ?-)
			   (eq (char-after (+ (point) size -2)) ?-)))
		  ;; This is a range so just replace the end part.
		  (delete-char size)
		;; Detect if this is using the following shorthand:
		;; (C) 1993, 94, 95, 1998, 2000, 01, 02, 2003
		(if (and
		     ;; Check that the last year was 4-chars and same century.
		     (eq size -4)
		     (equal (buffer-substring (- (point) 4) (- (point) 2))
			    (substring copyright-current-year 0 2))
		     ;; Check that there are 2-char years as well.
		     (save-excursion
		       (re-search-backward "[^0-9][0-9][0-9][^0-9]"
					   (line-beginning-position) t))
		     ;; Make sure we don't remove the first century marker.
		     (save-excursion
		       (forward-char size)
		       (re-search-backward
			(concat (buffer-substring (point) (+ (point) 2))
				"[0-9][0-9]")
			(line-beginning-position) t)))
		    ;; Remove the century marker of the last entry.
		    (delete-region (- (point) 4) (- (point) 2)))
		;; Insert a comma with the preferred number of spaces.
		(insert
		 (save-excursion
		   (if (re-search-backward "[0-9]\\( *, *\\)[0-9]"
					   (line-beginning-position) t)
		       (match-string 1)
		     ", ")))
		;; If people use the '91 '92 '93 scheme, do that as well.
		(if (eq (char-after (+ (point) size -3)) ?')
		    (insert ?')))
	      ;; Finally insert the new year.
	      (insert (substring copyright-current-year size))))))))

;;;###autoload
(defun copyright-update (&optional arg interactivep)
  "Update copyright notice at beginning of buffer to indicate the current year.
With prefix ARG, replace the years in the notice rather than adding
the current year after them.  If necessary, and
`copyright-current-gpl-version' is set, any copying permissions
following the copyright are updated as well.
If non-nil, INTERACTIVEP tells the function to behave as when it's called
interactively."
  (interactive "*P\nd")
  (when (or copyright-update interactivep)
    (let ((noquery (or (not copyright-query)
		       (and (eq copyright-query 'function) interactivep))))
      (save-excursion
	(save-restriction
	  (widen)
	  (goto-char (point-min))
	  (copyright-update-year arg noquery)
	  (goto-char (point-min))
	  (and copyright-current-gpl-version
	       ;; match the GPL version comment in .el files, including the
	       ;; bilingual Esperanto one in two-column, and in texinfo.tex
	       (re-search-forward "\\(the Free Software Foundation;\
 either \\|; a\\^u eldono \\([0-9]+\\)a, ? a\\^u (la\\^u via	 \\)\
version \\([0-9]+\\), or (at"
				  (+ (point) copyright-limit) t)
	       (not (string= (match-string 3) copyright-current-gpl-version))
	       (or noquery
		   (y-or-n-p (concat "Replace GPL version by "
				     copyright-current-gpl-version "? ")))
	       (progn
		 (if (match-end 2)
		     ;; Esperanto bilingual comment in two-column.el
		     (replace-match copyright-current-gpl-version t t nil 2))
		 (replace-match copyright-current-gpl-version t t nil 3))))
	(set (make-local-variable 'copyright-update) nil)))
    ;; If a write-file-hook returns non-nil, the file is presumed to be written.
    nil))


;;;###autoload
(define-skeleton copyright
  "Insert a copyright by $ORGANIZATION notice at cursor."
  "Company: "
  comment-start
  "Copyright (C) " `(substring (current-time-string) -4) " by "
  (or (getenv "ORGANIZATION")
      str)
  '(if (> (point) (+ (point-min) copyright-limit))
       (message "Copyright extends beyond `copyright-limit' and won't be updated automatically."))
  comment-end \n)

(provide 'copyright)

;; For the copyright sign:
;; Local Variables:
;; coding: emacs-mule
;; End:

;;; arch-tag: b4991afb-b6b1-4590-bebe-e076d9d4aee8
;;; copyright.el ends here
