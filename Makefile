IMAGE_NAME=phyllisstein/watchman
WATCHMAN_VERSION=2026.03.02.00
TAG=v$(WATCHMAN_VERSION)

.PHONY: all build build-amd64 build-arm64 push push-amd64 push-arm64 push-all manifest

all: build push-all

build-amd64:
	docker buildx build --platform linux/amd64 -t $(IMAGE_NAME):$(TAG)-amd64 --build-arg WATCHMAN_VERSION=$(WATCHMAN_VERSION) --load .
	docker tag $(IMAGE_NAME):$(TAG)-amd64 $(IMAGE_NAME):latest-amd64

build-arm64:
	docker buildx build --platform linux/arm64 -t $(IMAGE_NAME):$(TAG)-arm64 --build-arg WATCHMAN_VERSION=$(WATCHMAN_VERSION) --load .
	docker tag $(IMAGE_NAME):$(TAG)-arm64 $(IMAGE_NAME):latest-arm64

build: build-amd64 build-arm64

push-amd64:
	docker push $(IMAGE_NAME):$(TAG)-amd64
	docker push $(IMAGE_NAME):latest-amd64

push-arm64:
	docker push $(IMAGE_NAME):$(TAG)-arm64
	docker push $(IMAGE_NAME):latest-arm64

manifest:
	docker buildx imagetools create -t $(IMAGE_NAME):$(TAG) \
		$(IMAGE_NAME):$(TAG)-amd64 \
		$(IMAGE_NAME):$(TAG)-arm64
	docker buildx imagetools create -t $(IMAGE_NAME):latest \
		$(IMAGE_NAME):$(TAG)-amd64 \
		$(IMAGE_NAME):$(TAG)-arm64

push-all: push-amd64 push-arm64 manifest
