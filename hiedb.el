;;; hiedb.el --- Use hiedb code navigation and information

;; Copyright (C) 2022 James King

;; Author: James King <james@agentultra.com>
;; Version: 0.1
;; Keywords: haskell

;;; Commentary:

;; This package provides a minor-mode front end to hiedb for querying
;; Haskell code.

;;; Code:

(eval-when-compile (require 'subr-x))

(defcustom hiedb-command "hiedb"
  "Path to the hiedb executable."
  :type 'string
  :group 'hiedb-mode)

(defcustom hiedb-dbfile ".hiedb"
  "Path to the generated hiedb."
  :type 'string
  :group 'hiedb-mode)

(defcustom hiedb-hiefiles ".hiefiles"
  "Path to the hie files."
  :type 'string
  :group 'hiedb-mode)

(defcustom hiedb-project-root nil
  "Path to project source root."
  :type 'string
  :group 'hiedb-mode)

(define-minor-mode hiedb-mode
  "A minor mode for querying hiedb."
  :init-value nil
  :lighter " hie-mode"
  :keymap '(("\C-c\C-dr" . hiedb-interactive-refs)
            ("\C-c\C-dt" . hiedb-interactive-types)
            ("\C-c\C-dd" . hiedb-interactive-defs)
            ("\C-c\C-d\i" . hiedb-interactive-info))
  )

;; Interactive functions

;;;###autoload
(defun hiedb-interactive-refs ()
  "Query hiedb for references of symbol at point."
  (interactive)
  (let ((module (hiedb-module-from-path)))
    (hiedb-query-point-refs module (line-number-at-pos) (1+ (current-column)))))

;;;###autoload
(defun hiedb-interactive-types ()
  "Query hiedb type of symbol at point."
  (interactive)
  (let ((module (hiedb-module-from-path)))
    (hiedb-query-point-types module (line-number-at-pos) (1+ (current-column)))))

;;;###autoload
(defun hiedb-interactive-defs ()
  "Query hiedb definition of symbol at point."
  (interactive)
  (let ((module (hiedb-module-from-path)))
    (hiedb-query-point-defs module (line-number-at-pos) (1+ (current-column)))))

;;;###autoload
(defun hiedb-interactive-info ()
  "Query hiedb information on symbol at point."
  (interactive)
  (let ((module (hiedb-module-from-path)))
    (hiedb-query-point-info module (line-number-at-pos) (1+ (current-column)))))

;; Shell commands for calling out to hiedb.

(defun hiedb-query-point-refs (mod sline scol)
  "Query hiedb point-refs of MOD at SLINE SCOL."
  (call-hiedb "point-refs" mod sline scol))

(defun hiedb-query-point-types (mod sline scol)
  "Query type at point in MOD at SLINE SCOL."
  (call-hiedb "point-types" mod sline scol))

(defun hiedb-query-point-defs (mod sline scol)
  "Query defintions at SLINE SCOL in MOD."
  (call-hiedb "point-defs" mod sline scol))

(defun hiedb-query-point-info (mod sline scol)
  "Query symbol information at SLINE SCOL in MOD."
  (call-hiedb "point-info" mod sline scol))

(defun call-hiedb (cmd mod sline scol)
  (message (format "running %s -D %s point-info %s %d %d"
                         hiedb-command
                         hiedb-dbfile
                         mod sline scol))
  (let*
      ((log-buffer (get-buffer-create "*hiedb*")))
      (set-buffer log-buffer)
      (read-only-mode -1)
      (with-current-buffer log-buffer
        (erase-buffer)
        (call-process "hiedb" nil t t
             "-D" hiedb-dbfile cmd
             mod (format "%d" sline) (format "%d" scol)))
      (display-buffer-pop-up-window log-buffer nil)
      (special-mode)))


;; Utilities

(defun hiedb-module-from-path ()
  "Get the module name from the buffer file path."
  (let ((module-path (string-remove-prefix (concat hiedb-project-root "/src") (buffer-file-name))))
    (string-remove-prefix "." (subst-char-in-string ?/ ?. (string-remove-suffix ".hs" module-path)))))

(provide 'hiedb)
;;; hiedb.el ends here
