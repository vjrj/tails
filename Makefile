#CURRENT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
#DOCKER_IMAGE_NAME := "tails$(if $(CURRENT_BRANCH),-$(CURRENT_BRANCH))"
BUILDER_IMAGE := "tails_builder"
BUILDER_MOUNT := "$(shell pwd):/root/tails"
DOCKER_RUN_IN_BUILDER := docker run --rm --privileged -v $(BUILDER_RUN) -t $(BUILDER_IMAGE)
ISO_BUILD_COMMAND := apt-get update && apt-get dist-upgrade && lb clean --all && lb config --cache false && lb build

default: all

all: containers iso_image

iso_image:
	$(DOCKER_RUN_IN_BUILDER) "$(ISO_BUILD_COMMAND)"

containers: builder_container

builder_container:
	docker build -t "$(BUILDER_IMAGE)" .
