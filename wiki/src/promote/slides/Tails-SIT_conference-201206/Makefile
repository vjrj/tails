default:	debug

debug:		clean all
	evince *.pdf

beamer.template:

%.odt:		%.tex
	pandoc -f latex -t odt -o $@ $<

%.pdf:		%.tex
	# Run twice to get the TOC right.
	xelatex $<
	xelatex $<
	mat $@

%.tex:		%.mdwn beamer.template pandoc-filters/beamer
	pandoc -t json --smart $< | ./pandoc-filters/beamer | pandoc -f json -t latex --template=beamer.template -o $@

pandoc-filters/beamer: pandoc-filters/beamer.hs
	ghc -O $<

clean:
	for ext in aux dvi log nav odt out pdf ps snm toc vrb ; do rm -f slides.$$ext ; done
	rm -f slides.tex

all:		slides.pdf slides.odt
