# 使用Rust官方镜像作为基础镜像
FROM rust:1.76

# 安装jq
RUN apt-get update && apt-get install -y jq

# 安装bdk-cli
RUN cargo install bdk-cli --features electrum

COPY start-wallet.sh .
RUN chmod +x ./start-wallet.sh

entrypoint ["./start-wallet.sh"]