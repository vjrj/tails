FROM debian:wheezy
MAINTAINER amnesia@boum.org

ADD setup_container /root/setup_container
RUN bash /root/setup_container

RUN	apt-get update &&						\
	apt-get install --assume-yes --no-install-recommends		\
	--allow-unauthenticated						\
	bash								\
	cpio								\
	dpkg-dev							\
	eatmydata/squeeze-backports					\
	git								\
	ikiwiki/wheezy-backports					\
	intltool							\
	libdpkg-perl							\
	libyaml-perl							\
	libyaml-syck-perl						\
	live-build/builder-wheezy					\
	perlmagick							\
	po4a								\
	syslinux							\
	time								\
	wget								\
	whois

WORKDIR /root/tails
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD []
