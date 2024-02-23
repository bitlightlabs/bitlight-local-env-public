PWD := $(shell pwd)

export BITCOIN_COMPOSE_PROJECT_NAME=bitlight-local-env-bitcoin
export LND_COMPOSE_PROJECT_NAME=bitlight-local-env-lnd
export NETWORK_NAME=regtest
export NETWORK_SUBNET=10.200.10.0/24
export PATH=$(PWD)/scripts:$(shell echo $$PATH)

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
	cd docker && docker-compose build

.PHONY: up
up: network
	@echo "$@ services... in detached mode"
	docker-compose -p bitlight-local-env up -d

up-lnd: up
	@echo "$@ services... in detached mode"
	docker-compose -p bitlight-local-env-lnd -f docker-compose-lnd.yml up -d

down-lnd:
	@echo "$@ services..."
	docker-compose -p bitlight-local-env-lnd -f docker-compose-lnd.yml down -v

.PHONY: up-foreground
up-foreground: network
	@echo "$@ services... in foreground mode"
	docker-compose -p bitlight-local-env up

.PHONY: stop
stop:
	@echo "$@ services..."
	docker-compose -p bitlight-local-env $@

.PHONY:down
down:
	@echo "$@ services..."
	docker-compose -p bitlight-local-env $@ -v

.PHONY: restart
restart: down up full-logs

.PHONY: recreate
recreate: clean up full-logs

.PHONY: logs
logs:
	docker-compose -p bitlight-local-env logs -f --tail=20

.PHONY: full-logs
full-logs:
	docker-compose -p bitlight-local-env logs -f

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
	docker-compose -p bitlight-local-env exec -it -w /cli bitcoin-core /cli/active.sh

.PHONY: alice-cli
alice-cli:
	docker-compose -p bitlight-local-env exec -it  wallet-alice /start-wallet.sh repl

.PHONY: bob-cli
bob-cli:
	docker-compose -p bitlight-local-env exec -it  wallet-alice /start-wallet.sh repl

wallet-%-cli:
	echo "Starting wallet $* cli..."
	docker-compose -p bitlight-local-env exec -it  wallet-$* /start-wallet.sh repl

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

build-esplora-api-docker:
	@echo "Releasing docker image for $*"
	@cd docker/esplora-api && \
		docker buildx build --platform linux/amd64,linux/arm64 -t bitlightlabs/esplora-api:latest .