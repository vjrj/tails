FROM debian:wheezy
MAINTAINER tails@boum.org

VOLUME ["/var/cache/apt-cacher-ng"]

COPY provision/assets/apt/sources.list             /etc/apt/sources.list
COPY provision/assets/apt/preferences              /etc/apt/preferences.d/tails

RUN	apt-get update &&						\
	apt-get upgrade --assume-yes &&					\
	apt-get install --assume-yes --no-install-recommends		\
	  apt-cacher-ng/wheezy-backports

COPY provision/assets/config/acng.conf             /etc/apt-cacher-ng/acng.conf

EXPOSE 3142

CMD /usr/sbin/apt-cacher-ng ForeGround=1 CacheDir=/var/cache/apt-cacher-ng
