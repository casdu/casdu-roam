(require 'package)
(add-to-list 'package-archives '("gnu-devel" . "https://elpa.gnu.org/devel/") t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)

(package-refresh-contents)
(package-initialize)

;;;; Org-roam
(package-install 'org-roam)
(require 'org-roam)
(setq org-roam-directory (file-truename "../"))

;;;; backlink
(defun collect-backlinks-string (backend)
  "see <https://org-roam.discourse.group/t/export-backlinks-on-org-export/1756/21>"
  (when (org-roam-node-at-point)
    (let* ((source-node (org-roam-node-at-point))
           (source-file (org-roam-node-file source-node))
           (nodes-in-file (--filter (s-equals? (org-roam-node-file it) source-file)
                                    (org-roam-node-list)))
           (nodes-start-position (-map 'org-roam-node-point nodes-in-file))
           ;; Nodes don't store the last position, so get the next headline position
           ;; and subtract one character (or, if no next headline, get point-max)
           (nodes-end-position (-map (lambda (nodes-start-position)
                                       (goto-char nodes-start-position)
                                       (if (org-before-first-heading-p) ;; file node
                                           (point-max)
                                         (call-interactively
                                          'org-forward-heading-same-level)
                                         (if (> (point) nodes-start-position)
                                             (- (point) 1) ;; successfully found next
                                           (point-max)))) ;; there was no next
                                     nodes-start-position))
           ;; sort in order of decreasing end position
           (nodes-in-file-sorted (->> (-zip nodes-in-file nodes-end-position)
                                      (--sort (> (cdr it) (cdr other))))))
      (dolist (node-and-end nodes-in-file-sorted)
        (-let (((node . end-position) node-and-end))
          (when (org-roam-backlinks-get node)
            (goto-char end-position)
            ;; Add the references as a subtree of the node
            (setq heading (format "\n\n%s References\n"
                                  (s-repeat (+ (org-roam-node-level node) 1) "*")))
            (insert heading)
            (setq properties-drawer ":PROPERTIES:\n:HTML_CONTAINER_CLASS: references\n:END:\n")
            (insert properties-drawer)
            (dolist (backlink (org-roam-backlinks-get node))
              (let* ((source-node (org-roam-backlink-source-node backlink))
                     (properties (org-roam-backlink-properties backlink))
                     (outline (when-let ((outline (plist-get properties :outline)))
                                  (mapconcat #'org-link-display-format outline " > ")))
                     (point (org-roam-backlink-point backlink))
                     (text (s-replace "\n" " " (org-roam-preview-get-contents
                                                (org-roam-node-file source-node)
                                                point)))
                     (reference (format "%s [[id:%s][%s]]\n%s\n%s\n\n"
                                        (s-repeat (+ (org-roam-node-level node) 2) "*")
                                        (org-roam-node-id source-node)
                                        (org-roam-node-title source-node)
                                        (if outline (format "%s (/%s/)"
                                        (s-repeat (+ (org-roam-node-level node) 3) "*") outline) "")
                                        text)))
                (insert reference)))))))))

;;;; transclusion
(package-install 'org-transclusion)
(require 'org-transclusion)

;; get org-file as a list
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
(add-hook 'org-export-before-processing-hook #'collect-backlinks-string)
(org-latex-export-to-pdf)
