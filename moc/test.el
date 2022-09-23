(require 'package)
(add-to-list 'package-archives '("gnu-devel" . "https://elpa.gnu.org/devel/") t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)

(package-refresh-contents)
(package-initialize)

;;;; lilypond
(org-babel-do-load-languages
'org-babel-load-languages
'((emacs-lisp . t)
  (lilypond t)))

;;;; Org-roam
(package-install 'org-roam)
(require 'org-roam)
(setq org-roam-directory (file-truename "../"))


;;;; transclusion
(package-install 'org-transclusion)
(require 'org-transclusion)

;;;; get org-file as a list
(defun os-walk (root)
  "see
https://kitchingroup.cheme.cmu.edu/blog/2014/03/23/Make-a-list-of-org-files-in-all-the-subdirectories-of-the-current-working-directory/"
  (let ((files '()) ;empty list to store results
        (current-list (directory-files root t)))
    ;;process current-list
    (while current-list
      (let ((fn (car current-list))) ; get next entry
        (cond
         ;; regular files
         ((and
           (file-regular-p fn)
           (not (backup-file-name-p fn)))
          (add-to-list 'files fn))
         ;; directories
         ((and
           (file-directory-p fn)
           ;; ignore . and ..
           (not (string-equal ".." (substring fn -2)))
           (not (string-equal "." (substring fn -1))))
          ;; we have to recurse into this directory
          (setq files (append files (os-walk fn))))
        )
      ;; cut list down by an element
      (setq current-list (cdr current-list))))
    files))

(require 'cl)

(setq casdu-all-org-files (remove-if-not
                           (lambda (x) (string= (file-name-extension x) "org"))
                           (os-walk "../")))

(org-id-update-id-locations casdu-all-org-files)

(find-file "./index.org")
(org-transclusion-add-all)
(org-latex-export-to-pdf)

(find-file "./music.org")
(org-transclusion-add-all)
(org-latex-export-to-pdf)
