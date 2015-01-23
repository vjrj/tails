#CURRENT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
#DOCKER_IMAGE_NAME := "tails$(if $(CURRENT_BRANCH),-$(CURRENT_BRANCH))"
BUILDER_IMAGE := "tails_builder"
BUILDER_MOUNT := "$(shell pwd):/root/tails"
DOCKER_RUN_IN_BUILDER := docker run --rm --privileged -v $(BUILDER_MOUNT) -t $(BUILDER_IMAGE)
ISO_BUILD_COMMAND := apt-get update && apt-get dist-upgrade && /usr/sbin/build-tails

default: all

all: containers iso_image

iso_image:
	$(DOCKER_RUN_IN_BUILDER) "$(ISO_BUILD_COMMAND)"

containers: builder_container

builder_container: docker/tails_builder/provision/assets/apt/deb.tails.boum.org.key
	docker build -t "$(BUILDER_IMAGE)" docker/tails_builder

# Docker cannot COPY files from outside of its context (i.e. where the
# Dockerfile is stored) so we have to make it available in there while
# being careful its not a symlink, hence the `--dereference`. Also
# note that `--preserve=all` is crucial to prevent Docker from always
# rebuilding the tails_builder image since e.g. a new mtime in a
# COPY-source will be detected by Docker.
docker/tails_builder/provision/assets/apt/deb.tails.boum.org.key: config/chroot_sources/tails.chroot.gpg
	cp --dereference --preserve=all config/chroot_sources/tails.chroot.gpg $@
