PWD := $(shell pwd)

export PROJECT_NAME=bitlight-local-env
export BITCOIN_COMPOSE_PROJECT_NAME=$(PROJECT_NAME)-bitcoin
export LND_COMPOSE_PROJECT_NAME=$(PROJECT_NAME)-lnd
export NETWORK_NAME=regtest
export NETWORK_SUBNET=10.200.10.0/24
export PATH=$(PWD)/scripts:$(shell echo $$PATH)
export DOCKER_COMPOSE=docker compose

include .env
export $(shell sed 's/=.*//' .env)


.PHONY: check-env
check-env:
	./scripts/env.sh

.PHONY: start
start: up full-logs

.PHONY: network
network:
	./scripts/network-up.sh

clean-network:
	./scripts/network-down.sh

.PHONY: build-images
build-images:
	@echo "Building images..."
	cd docker && $(DOCKER_COMPOSE) build

.PHONY: up
up: network
	@echo "$@ services... in detached mode"
	$(DOCKER_COMPOSE) -p $(PROJECT_NAME) up -d

up-lnd: up
	@echo "$@ services... in detached mode"
	$(DOCKER_COMPOSE) -p $(LND_COMPOSE_PROJECT_NAME) -f docker-compose-lnd.yml up -d

down-lnd:
	@echo "$@ services..."
	$(DOCKER_COMPOSE) -p $(LND_COMPOSE_PROJECT_NAME) -f docker-compose-lnd.yml down -v

.PHONY: up-foreground
up-foreground: network
	@echo "$@ services... in foreground mode"
	$(DOCKER_COMPOSE) -p $(PROJECT_NAME) up

.PHONY: stop
stop:
	@echo "$@ services..."
	$(DOCKER_COMPOSE) -p $(PROJECT_NAME) $@

.PHONY:down
down:
	@echo "$@ services..."
	$(DOCKER_COMPOSE) -p $(PROJECT_NAME) $@ -v

.PHONY: restart
restart: down up full-logs

.PHONY: recreate
recreate: clean up full-logs

.PHONY: logs
logs:
	$(DOCKER_COMPOSE) -p $(PROJECT_NAME) logs -f --tail=20

.PHONY: full-logs
full-logs:
	$(DOCKER_COMPOSE) -p $(PROJECT_NAME) logs -f

.PHONY: clean
clean: down clean-bitcoin-data clean-network down-lnd

.PHONY: clean-data
clean-data: clean-bitcoin-data clean-lnd-data

.PHONY: clean-bitcoin-data
clean-bitcoin-data:
	@echo "Cleaning up bitcoin data..."
	rm -rf ./docker/bitcoin/data/*

.PHONY: clean-lnd-data
clean-lnd-data:
	@echo "Cleaning up lnd data..."
	rm -rf ./docker/lnd/data/*

.PHONY: cli core-cli
cli core-cli:
	$(DOCKER_COMPOSE) -p $(PROJECT_NAME) exec -it -w /cli bitcoin-core /cli/active.sh

.PHONY: alice-cli
alice-cli:
	$(DOCKER_COMPOSE) -p $(PROJECT_NAME) exec -it  wallet-alice /start-wallet.sh repl

.PHONY: bob-cli
bob-cli:
	$(DOCKER_COMPOSE) -p $(PROJECT_NAME) exec -it  wallet-bob /start-wallet.sh repl

wallet-%-cli:
	echo "Starting wallet $* cli..."
	$(DOCKER_COMPOSE) -p $(PROJECT_NAME) exec -it  wallet-$* /start-wallet.sh repl

active:
	@echo "Activating environment..."
	@source ./scripts/env.sh; $$SHELL -i

.PHONY: build
build:
	cargo build

.PHONY: run
run:
	cargo run

.PHONY: test
test:
	cargo test

.PHONY: clean-rust
clean-rust:
	cargo clean

.PHONY: test-e2e
test-e2e:
	cargo test --test e2e

.PHONY: format
format:
	rustfmt **/*.rs

.PHONY: lint
lint:
	cargo clippy

start-docs:
	cd docs && make serve

.PHONY: pull
pull-images: pull-image-esplora-api pull-image-bdk-cli

pull-image-%:
	@echo "Pull $* image"
	@docker pull bitlightlabs/$*:latest || echo "no pull $*"


build-esplora-api-docker:
	@echo "Releasing docker image for $*"
	@cd docker/esplora-api && \
		docker buildx build --platform linux/amd64,linux/arm64 -t bitlightlabs/esplora-api:latest .


build-wallet-docker:
	@echo "Releasing docker image for $*"
	docker build -t bitlightlabs/bdk-cli:latest docker/wallet