# getting release version.
image_name = crowbarkz/coraline:latest


# build backend container
.PHONY: build
build:
	# build container
	docker build -t $(image_name) . \
		-f docker/backend.dockerfile --network=host --pull

# prepare 3rd party containers; just rerun them if they exist
.PHONY: run-3rdparty
run-3rdparty:
	docker volume create coraline-pgdata
	docker run -d --name coraline-postgres -v coraline-pgdata:/var/lib/postgresql/data postgres:11.1-alpine || docker start coraline-postgres
	docker run -d --name coraline-rabbit --hostname coraline-rabbit rabbitmq:3.7-alpine || docker start coraline-rabbit

# run celery worker
.PHONY: run-worker
run-worker:
	docker stop coraline-worker && docker rm coraline-worker || true
	docker run \
		-d --name coraline-worker --env-file=docker/backend.env \
		--link=coraline-rabbit:rabbit --link=coraline-postgres:postgres $(image_name) worker

# run all coraline containers (always delete & rerun ours)
.PHONY: run
run: run-3rdparty run-worker
	docker stop coraline && docker rm coraline || true
	docker run \
		-d --name coraline --env-file=docker/backend.env \
		--link=coraline-rabbit:rabbit --link=coraline-postgres:postgres \
		--publish=8000:80 $(image_name)

# run for backend development
# runs django dev server and does not detach its process from shell
# also plugs in source code into container
.PHONY: devrun-backend
devrun-backend: run-3rdparty run-worker
	docker stop coraline && docker rm coraline || true
	docker run \
		--name coraline --env-file=docker/backend.env \
		-v `pwd`:/coraline \
		--link=coraline-rabbit:rabbit --link=coraline-postgres:postgres \
		--publish=8000:80 $(image_name) devserver

.PHONY: test
test: run-3rdparty
	docker stop coraline && docker rm coraline || true
	docker run \
		--name coraline --env-file=docker/test.env \
		--link=coraline-rabbit:rabbit --link=coraline-postgres:postgres \
		$(image_name) test

.PHONY: lint
lint:
	docker stop coraline && docker rm coraline || true
	docker run \
		--name coraline --env-file=docker/test.env \
		$(image_name) lint

# Plug in source code folder inside container and just run shell
# e.g. for making migrations or creating superuser
.PHONY: devrun-shell
devrun-shell: run-3rdparty
	docker stop coraline && docker rm coraline || true
	docker run -it \
		--name coraline --env-file=docker/backend.env \
		-v `pwd`:/coraline \
		--link=coraline-postgres:postgres \
		--publish=8000:80 $(image_name) shell

# Plug in source code folder inside container and just run shell (but with test.env)
# e.g. to run tests interactively, dont forget to install test requirements
.PHONY: devrun-shell-test
devrun-shell-test: run-3rdparty
	docker stop coraline && docker rm coraline || true
	docker run -it \
		--name coraline --env-file=docker/test.env \
		-v `pwd`:/coraline \
		--link=coraline-rabbit:rabbit --link=coraline-postgres:postgres \
		--publish=8000:80 $(image_name) shelltest

.PHONY: push
push:
	docker push $(image_name)

# stop all coraline containers
.PHONY: stop
stop:
	docker stop coraline coraline-worker
	docker stop coraline-postgres coraline-rabbit
