FROM debian:wheezy
MAINTAINER tails@boum.org

COPY provision/assets/apt/deb.tails.boum.org.key   /tmp/deb.tails.boum.org.key
COPY provision/assets/apt/sources.list             /etc/apt/sources.list
COPY provision/assets/apt/preferences              /etc/apt/preferences.d/tails

RUN	apt-key add /tmp/deb.tails.boum.org.key &&			\
	apt-get update &&						\
	apt-get install --assume-yes --no-install-recommends		\
	  aufs-tools							\
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
	  procps							\
	  syslinux							\
	  time								\
	  wget								\
	  whois

COPY provision/assets/live-build/build.conf        /etc/live/build.conf
COPY provision/assets/scripts/build-tails          /usr/sbin/build-tails

WORKDIR /root/tails
ENTRYPOINT ["/bin/bash", "-l", "-c"]
CMD []
