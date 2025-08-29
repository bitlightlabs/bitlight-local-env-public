FROM rust:1.65 as builder

# This is the commit hash of the version of electrs we want to build
# It is from https://github.com/Blockstream/esplora/commit/b6439901f0823933782d82f2c9fba3ba81c308e4
ARG ESPLORA_BUILD_CHECKOUT="fd35014283c7d3a7a85c77b9fd647c9f09de12c9"

# Update and install build-essential
RUN apt-get update && apt-get install -y clang cmake build-essential

# Clone the electrs repository and checkout the commit we want to build
WORKDIR /app
RUN git clone https://github.com/Blockstream/electrs.git
WORKDIR /app/electrs
RUN git checkout $ESPLORA_BUILD_CHECKOUT

# Build electrs
RUN CARGO_NET_GIT_FETCH_WITH_CLI=true \
    cargo build --release --locked


FROM debian:bullseye-slim

LABEL maintainer="BitLight"
LABEL description="Bitlight Local Env Esplora API Server Image, powerby Blockstream/electrs"
LABEL VERSION=${ESPLORA_BUILD_CHECKOUT}

COPY --from=builder /app/electrs/target/release/electrs /usr/local/bin/electrs

ENTRYPOINT ["electrs"]