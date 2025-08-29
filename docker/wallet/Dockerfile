# Using the official Rust image as the base image
FROM rust:1.76

# install jq
RUN apt-get update && apt-get install -y jq

# install dk-cli
RUN cargo install bdk-cli --features electrum

COPY start-wallet.sh .
RUN chmod +x ./start-wallet.sh

entrypoint ["./start-wallet.sh"]