# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Watchman Build ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
FROM ubuntu:22.04 AS builder

ENV WATCHMAN_VERSION="2024.08.26.00"

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
      -o Dpkg::Options::="--force-confdef" \
      -o Dpkg::Options::="--force-confold" \
      --yes \
  && DEBIAN_FRONTEND=noninteractive apt-get install \
      -o Dpkg::Options::="--force-confdef" \
      -o Dpkg::Options::="--force-confold" \
      --yes \
    build-essential \
    docker \
    cmake \
    curl \
    git \
    libsodium-dev \
    libssl-dev \
    libz-dev \
    m4 \
    pkg-config \
    python3 \
    sudo \
    wget \
  && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly --profile complete -y

RUN mkdir -p /tmp/watchman && cd /tmp/watchman \
  && wget "https://github.com/facebook/watchman/archive/v${WATCHMAN_VERSION}.tar.gz" \
  && tar -xf v${WATCHMAN_VERSION}.tar.gz -C . --strip-components=1 \
  && . "$HOME/.cargo/env" \
  && ./autogen.sh



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Watchman Binaries ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
FROM ubuntu:22.04 AS watchman

COPY --from=builder /tmp/watchman/built/bin/* /usr/local/bin/
COPY --from=builder /tmp/watchman/built/lib/* /usr/local/lib/
RUN mkdir -p /usr/local/var/run/watchman
