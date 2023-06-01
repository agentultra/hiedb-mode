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

;;;###autoload
(define-minor-mode hiedb-mode
  "A minor mode for querying hiedb."
  :init-value nil
  :lighter " hie-mode"
  :keymap '(("\C-c\C-dr" . hiedb-interactive-refs)
            ("\C-c\C-dt" . hiedb-interactive-types)
            ("\C-c\C-dd" . hiedb-interactive-defs)
            ("\C-c\C-d\i" . hiedb-interactive-info)
            ("\C-c\C-d\s" . hiedb-interactive-reindex)
            ("\C-c\C-dT" . hiedb-interactive-type-def)
            ("\C-c\C-dN" . hiedb-interactive-name-def)
            )
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;        Interactive functions        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun hiedb-interactive-refs ()
  "Query hiedb for references of symbol at point."
  (interactive)
  (query-info-at-point "point-refs"))

;;;###autoload
(defun hiedb-interactive-types ()
  "Query hiedb type of symbol at point."
  (interactive)
  (query-info-at-point "point-types"))

;;;###autoload
(defun hiedb-interactive-defs ()
  "Query hiedb definition of symbol at point."
  (interactive)
  (query-info-at-point "point-defs"))

;;;###autoload
(defun hiedb-interactive-info ()
  "Query hiedb information on symbol at point."
  (interactive)
  (query-info-at-point "point-info"))

;;;###autoload
(defun hiedb-interactive-reindex ()
  "Query hiedb information on symbol at point."
  (interactive)
  (call-hiedb-reindex-async))

;;;###autoload
(defun hiedb-interactive-type-def ()
  "Look up definition of type."
  (interactive)
  (let ((value (read-string "Type name: ")))
    (call-hiedb-sync "type-def" value)
    ))

;;;###autoload
(defun hiedb-interactive-name-def ()
  "Look up definition of type."
  (interactive)
  (let ((value (read-string "Constructor name: ")))
    (call-hiedb-sync "name-def" value)
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;        Shell commands for calling out to hiedb        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; invoke the hiedb command that queries information at current position
;;; cmd - the hiedb command name
(defun query-info-at-point (cmd)
  (let ((module (hiedb-module-from-path))
        (sline (line-number-at-pos))
        (scol (1+ (current-column)))
       )
    (call-hiedb-sync cmd module (format "%d" sline) (format "%d" scol))))

(defun call-hiedb-sync (&rest cmdArgs)
  (let*
      ((log-buffer (get-buffer-create "*hiedb*")))
    (message (format "%s -D %s %s"
                     hiedb-command
                     hiedb-dbfile
                     (mapconcat #'identity cmdArgs " ")
                     ))
    (set-buffer log-buffer)
    (read-only-mode -1)
    (with-current-buffer log-buffer
      (erase-buffer)
      (apply 'call-process
             hiedb-command nil t t
             "-D" hiedb-dbfile
             cmdArgs)
      (read-only-mode 1)
      (display-buffer log-buffer
                      '(display-buffer-pop-up-window . ((side . top)
                                                        (window-height . 5)
                                                        (mode . (special-mode))
                                                        ))))))
;;; Invoke reindex async since re-index usually take a while.
(defun call-hiedb-reindex-async ()
  (let*
      ((log-buffer (get-buffer-create "*hiedb*")))
    (message (format "%s -D -%s index %s"
                     hiedb-command
                     hiedb-dbfile
                     hiedb-hiefiles))
    (set-buffer log-buffer)
    (read-only-mode -1)
    (with-current-buffer log-buffer
      (erase-buffer)
      (make-process :name "reindex hiedb"
                    :buffer log-buffer
                    :command (list hiedb-command "-D" hiedb-dbfile "index" hiedb-hiefiles)
                    :stderr log-buffer))
    (read-only-mode 1)
    (display-buffer log-buffer
                    '(display-buffer-pop-up-window . ((side . top)
                                                      (window-height . 5)
                                                      (mode . (special-mode))
                                                      )))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;              Utilities ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun hiedb-module-from-path ()
  "Get the module name from the buffer file path."
  (let ((s (buffer-string)))
    (if (string-match "^module \\([^ \n]+\\)" s)
        (match-string 1 s)
      (buffer-file-name))))

(provide 'hiedb)
;;; hiedb.el ends here
