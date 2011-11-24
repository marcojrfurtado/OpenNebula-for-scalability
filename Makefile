FILE=dissertacao
LATEX=pdflatex

all:compile clean
	@echo "OK"

compile:	
	$(LATEX) $(FILE)
	#bibtex gtdp
	#$(LATEX) $(FILE)
	$(LATEX) $(FILE)

clean:
	rm -Rf *~ *.aux *.bbl *.bak *.backup *.log *.blg *.toc *.lot *.lof *.dvi *.idx *.ilg *.ind *.siglax *.symbolsx *.gz  *.nav *.out *.snm *.synctex.gz* *.vrb

cleanup: clean
	rm -f $(FILE).pdf
