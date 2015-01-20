FROM debian:wheezy
MAINTAINER tails@boum.org

ADD config/chroot_sources/tails.chroot.gpg /tmp/deb.tails.boum.org.key
ADD docker/provision/assets/apt/sources.list /etc/apt/sources.list
ADD docker/provision/assets/apt/preferences /etc/apt/preferences.d/tails
ADD docker/provision/assets/live-build/build.conf /etc/live/build.conf

RUN	apt-key add /tmp/deb.tails.boum.org.key				\
	apt-get update &&						\
	apt-get install --assume-yes --no-install-recommends		\
	--allow-unauthenticated						\
	bash								\
	cpio								\
	dpkg-dev							\
	eatmydata							\
	gettext/wheezy-backports					\
	git								\
	ikiwiki/wheezy-backports					\
	intltool							\
	libdpkg-perl							\
	libyaml-perl							\
	libyaml-syck-perl						\
	libyaml-libyaml-perl						\
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
