IMAGE_NAME=phyllisstein/watchman
TAG=v2024.08.26.00

.PHONY: all manifest push

all: manifest push

build-amd64:
    docker buildx build --platform linux/amd64 -t $(IMAGE_NAME):$(TAG)-amd64 --load .
	docker tag $(IMAGE_NAME):$(TAG)-amd64 $(IMAGE_NAME):latest-amd64

build-arm64:
    docker buildx build --platform linux/arm64 -t $(IMAGE_NAME):$(TAG)-arm64 --load .
    docker tag $(IMAGE_NAME):$(TAG)-arm64 $(IMAGE_NAME):latest-arm64

build: build-amd64 build-arm64

push-amd64:
    docker push $(IMAGE_NAME):$(TAG)-amd64
	docekr push $(IMAGE_NAME):latest-amd64

push-arm64:
    docker push $(IMAGE_NAME):$(TAG)-arm64
	docker push $(IMAGE_NAME):latest-arm64

push: push-amd64 push-arm64
	docker push $(IMAGE_NAME):$(TAG)
	docker push $(IMAGE_NAME):latest

manifest: build
    docker buildx imagetools create -t $(IMAGE_NAME):$(TAG) \
		$(IMAGE_NAME):$(TAG)-amd64 \
    	$(IMAGE_NAME):$(TAG)-arm64

    docker buildx imagetools create -t $(IMAGE_NAME):latest \
      --amend $(IMAGE_NAME):$(TAG)-amd64 \
      --amend $(IMAGE_NAME):$(TAG)-arm64
