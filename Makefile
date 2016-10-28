
all:
	pdflatex main.tex
	bibtex main
	pdflatex main.tex
	pdflatex main.tex

test:
	make -C src test

clean:
	rm -rf *~ *.aux *.log main.pdf *.bbl *.blg *.toc
	make -C src clean
