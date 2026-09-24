# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Watchman Build ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
FROM ubuntu:24.04 AS builder

ARG WATCHMAN_VERSION

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            --yes \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            --yes \
        autoconf \
        automake \
        binutils-$(dpkg --print-architecture | sed 's/amd64/x86-64/;s/arm64/aarch64/')-linux-gnu \
        build-essential \
        cmake \
        curl \
        git \
        libaio-dev \
        libboost-all-dev \
        libclang-dev \
        libdouble-conversion-dev \
        libdwarf-dev \
        libevent-dev \
        libfast-float-dev \
        libffi-dev \
        libgflags-dev \
        libgmock-dev \
        libgtest-dev \
        liblz4-dev \
        libpcre2-dev \
        libsnappy-dev \
        libsodium-dev \
        libssl-dev \
        libstdc++-11-dev \
        libtool \
        libxxhash-dev \
        libz-dev \
        libzstd-dev \
        m4 \
        ninja-build \
        pkg-config \
        python3 \
        python3-setuptools \
        sudo \
        wget \
        xxhash \
        zstd \
    && apt-get autoremove --yes \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly --profile complete -y

RUN mkdir -p /tmp/watchman && cd /tmp/watchman \
    && wget "https://github.com/facebook/watchman/archive/v${WATCHMAN_VERSION}.tar.gz" \
    && tar -xf v${WATCHMAN_VERSION}.tar.gz -C . --strip-components=1 \
    && . "$HOME/.cargo/env" \
    && sed -i 's/--allow-system-packages/& --no-tests/' autogen.sh \
    && sed -i \
        -e 's/add_executable(${NAME}.t /&EXCLUDE_FROM_ALL /' \
        -e 's/add_library(testsupport STATIC /&EXCLUDE_FROM_ALL /' \
        CMakeLists.txt \
    && [ "$(grep -c 'EXCLUDE_FROM_ALL' CMakeLists.txt)" -eq 2 ] \
    && [ "$(grep -c -- '--no-tests' autogen.sh)" -eq 2 ] \
    && ./autogen.sh


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Watchman Binaries ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
FROM ubuntu:24.04 AS watchman

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
            -o Dpkg::Options::="--force-confdef" \
            -o Dpkg::Options::="--force-confold" \
            --yes \
        libboost-context1.83.0 \
        libdouble-conversion3 \
        libevent-2.1-7t64 \
        libgflags2.2 \
        libsnappy1v5 \
    && apt-get autoremove --yes \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/watchman/built/bin/ /usr/local/bin/
COPY --from=builder /tmp/watchman/built/lib /usr/local/lib/
