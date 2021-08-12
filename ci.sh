# see https://gitlab.com/Kaligule/org-to-pdf
Readme.pdf: Readme.org
	emacs Readme.org --batch -f org-latex-export-to-pdf --kill
