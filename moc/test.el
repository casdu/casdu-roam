(require 'package)
(add-to-list 'package-archives '("gnu-devel" . "https://elpa.gnu.org/devel/") t)
(package-initialize)
(find-file "./index.org")
(org-transclusion-add-all)
(org-latex-export-to-pdf)
