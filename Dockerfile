FROM debian:wheezy
MAINTAINER tails@boum.org

COPY config/chroot_sources/tails.chroot.gpg        /tmp/deb.tails.boum.org.key
COPY docker/provision/assets/apt/sources.list      /etc/apt/sources.list
COPY docker/provision/assets/apt/preferences       /etc/apt/preferences.d/tails

RUN	apt-key add /tmp/deb.tails.boum.org.key &&			\
	apt-get update &&						\
	apt-get install --assume-yes --no-install-recommends		\
	  bash								\
	  cpio								\
	  dpkg-dev							\
	  eatmydata							\
	  gettext/wheezy-backports					\
	  git								\
	  ikiwiki/wheezy-backports					\
	  intltool							\
	  libdpkg-perl							\
	  libyaml-libyaml-perl						\
	  libyaml-perl							\
	  libyaml-syck-perl						\
	  live-build/builder-wheezy					\
	  perlmagick							\
	  po4a								\
	  syslinux							\
	  time								\
	  wget								\
	  whois

COPY docker/provision/assets/live-build/build.conf /etc/live/build.conf

WORKDIR /root/tails
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD []
