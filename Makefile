.PHONY: build push manifest test verify-codegen charts
TAG?=latest

# docker manifest command will work with Docker CLI 18.03 or newer
# but for now it's still experimental feature so we need to enable that
export DOCKER_CLI_EXPERIMENTAL=enabled

build:
	docker build -t openfaas-incubator/mqtt-connector:$(TAG)-amd64 . -f Dockerfile
	docker build --build-arg OPTS="GOARCH=arm64" -t openfaas-incubator/mqtt-connector:$(TAG)-arm64 . -f Dockerfile
	docker build --build-arg OPTS="GOARCH=arm GOARM=6" -t openfaas-incubator/mqtt-connector:$(TAG)-armhf . -f Dockerfile

push:
	docker push openfaas-incubator/mqtt-connector:$(TAG)-amd64
	docker push openfaas-incubator/mqtt-connector:$(TAG)-arm64
	docker push openfaas-incubator/mqtt-connector:$(TAG)-armhf

manifest:
	docker manifest create --amend openfaas-incubator/mqtt-connector:$(TAG) \
		openfaas-incubator/mqtt-connector:$(TAG)-amd64 \
		openfaas-incubator/mqtt-connector:$(TAG)-arm64 \
		openfaas-incubator/mqtt-connector:$(TAG)-armhf
	docker manifest annotate openfaas-incubator/mqtt-connector:$(TAG) openfaas-incubator/mqtt-connector:$(TAG)-arm64 --os linux --arch arm64
	docker manifest annotate openfaas-incubator/mqtt-connector:$(TAG) openfaas-incubator/mqtt-connector:$(TAG)-armhf --os linux --arch arm --variant v6
	docker manifest push -p openfaas-incubator/mqtt-connector:$(TAG)

test:
	go test ./...

charts:
	cd chart && helm package mqtt-connector
	mv chart/*.tgz docs/
	helm repo index docs --url https://openfaas-incubator.github.io/mqtt-connector/ --merge ./docs/index.yaml
