#CURRENT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
#DOCKER_IMAGE_NAME := "tails$(if $(CURRENT_BRANCH),-$(CURRENT_BRANCH))"
DOCKER_IMAGE_NAME := "tails_builder"
DOCKER_MOUNT := "$(shell pwd):/root/tails"
DOCKER_RUN := docker run --rm --privileged -v $(DOCKER_MOUNT) -t $(DOCKER_IMAGE_NAME)

default: all

all: env image

image:
	$(DOCKER_RUN) "lb clean --all && lb config --cache false && lb build"

env:
	docker build -t "$(DOCKER_IMAGE_NAME)" .
