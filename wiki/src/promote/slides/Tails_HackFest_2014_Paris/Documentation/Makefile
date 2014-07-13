default: all

%.shtml: %.mdwn
	pandoc --self-contained -t slidy -s $< -o $@

%.mdwn.txt: %.mdwn
	cp -f $< $@

clean:
	rm -f *.shtml *.mdwn.txt

export: documentation.shtml documentation.mdwn.txt

all: export
