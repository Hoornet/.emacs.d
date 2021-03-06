;;; oppdrag-mode.el --- Convenience utilities for working with Finn Oppdrag in Emacs

;; Copyright (C) 2011  Christian Johansen

;; Author: Christian Johansen <christian@moon>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 's)

(defun oppdrag-hot-deploy-buffer-file ()
  "If the current buffer is visiting a file, and that file is deployed
in an exploded war, re-deploy the file."
  (interactive)
  (let* ((source (buffer-file-name))
         (target (s-replace "src/main/webapp" "target/oppdrag" source)))
    (if (and (file-writable-p target)
             (not (string= source target)))
        (progn
          (copy-file source target t)
          (message (concat "Deployed " source " to " target)))
      (message (concat target " does not exist, file not deployed")))))

(define-minor-mode oppdrag-mode
  "Convenience utilities for working with Finn Oppdrag"
  nil " Oppdrag" nil
  (if oppdrag-mode
      (add-hook 'after-save-hook 'oppdrag-hot-deploy-buffer-file nil t)
    (remove-hook 'after-save-hook 'oppdrag-hot-deploy-buffer-file t)))

(defun oppdrag--setup-js-quirks ()
  (when (string-match-p "oppdrag-services" (buffer-file-name))
    (fci-mode 1)
    (setq js2-additional-externs '("FINN" "testCase" "cull"))
    (setq js2r-path-to-tests "/test/javascript/tests/")
    (setq js2r-path-to-sources "/main/webapp/oppdrag/scripts/")
    (setq js2r-test-suffix "Test")
    (setq buster-default-global "FINN.oppdrag")
    (setq buster-add-default-global-to-iife t)
    (setq buster-testcase-snippets-enabled nil)
    (make-variable-buffer-local 'buster-test-prefix)
    (setq buster-test-prefix "test should ")
    (set (make-local-variable 'sgml-basic-offset) 4)
    (make-variable-buffer-local 'js2-basic-offset)
    (setq js2-basic-offset 4)))

(eval-after-load "grep"
  '(progn (add-to-list 'grep-find-ignored-directories "ckeditor")
          (add-to-list 'grep-find-ignored-directories "external")))

(add-hook 'js2-mode-hook 'oppdrag--setup-js-quirks)

(defun strapon-transform-mod ()
  (interactive)
  (save-excursion
    (let (internal extra-bg beg)
      (end-of-line)
      (search-backward "class=\"mod")
      (search-forward "mod mod")
      (setq internal (looking-at "_2nd"))
      (setq extra-bg (cond
                      ((looking-at "_3rd") " bg-pale-blue")
                      ((looking-at "Att") " bg-pissyellow")
                      ((looking-at "Tip") " bg-snotgreen")
                      ((looking-at "Admin") " bg-firm contrast")
                      ((looking-at "Neutral") " bg-lt-gray")
                      (t "")))
      (er/mark-symbol)
      (delete-region (region-beginning) (region-end))
      (delete-char -1)
      (when internal
        (insert " internal"))
      (setq beg (point))
      (search-forward ">")
      (er/mark-inner-tag)
      (kill-region (region-beginning) (region-end))
      (newline)
      (insert "<div class=\"inner" extra-bg "\">")
      (yank)
      (insert "</div>")
      (newline)
      (indent-region beg (1+ (point))))))

(defun strapon-transform-request-mapping ()
  (interactive)
  (save-excursion
    (let (method-name method-signature beg)
      (end-of-line)

      (search-backward "@RequestMapping")
      (forward-line 1)
      (search-forward "(")
      (er/mark-inside-pairs)
      (setq method-signature
            (let (case-fold-search)
              (--> (buffer-substring (region-beginning) (region-end))
                (split-string it "\\s ")
                (--select (s-matches? "^[a-z]" it) it)
                (--reject (s-matches? "long" it) it)
                (s-join " " it)
                (s-collapse-whitespace it))))
      (deactivate-mark)

      (forward-char -1)
      (er/mark-symbol)
      (setq method-name (buffer-substring (region-beginning) (region-end)))
      (deactivate-mark)

      (search-backward "@RequestMapping")
      (setq beg (point))
      (search-forward "{")
      (while (er--point-inside-string-p)
        (search-forward "{"))
      (copy-region-as-kill beg (point))
      (goto-char beg)

      (new-line-above)
      (new-line-above)
      (let ((p (point)))
        (yank)

        (insert "
             model.addAttribute(\"strappedOn\", true);
             return " method-name "(" method-signature ") + \"-strapon\";
         }")

        (search-backward "@RequestMapping")
        (search-forward "\.")
        (replace-match "-strapon.")

        (forward-line 1)
        (search-forward "(")
        (replace-match "Strapon(")
        (search-forward "@RequestMapping")
        (indent-region p (point))))))

(defun strapon-create-strapon-jsp ()
  (interactive)
  (write-file
   (s-replace ".jsp" "-strapon.jsp" (buffer-file-name))
   t))

(f6 (strapon-transform-mod))
(f7 (strapon-transform-request-mapping))
(f12 (strapon-create-strapon-jsp))

(provide 'oppdrag-mode)
;;; oppdrag-mode.el ends here
