default:	all

%.html: %.mdwn
	pandoc --self-contained -t slidy -s $< -o $@

%.mdwn.txt: %.mdwn
	cp -f $< $@

%.html.txt: %.html
	cp -f $< $@

clean:
	rm -f slides.html

export: slides.mdwn.txt slides.html.txt

all: slides.html
