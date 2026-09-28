# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Watchman Build ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
FROM ubuntu:24.04 AS builder

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
        cmake \
        curl \
        git \
        # getdeps builds every other third-party dep from source, but the
        # libaio manifest's pagure.io tarball URL is dead; its [debs] entry
        # lets --allow-system-packages use this instead.
        libaio-dev \
        libffi-dev \
        libsodium-dev \
        libssl-dev \
        libstdc++-11-dev \
        libz-dev \
        m4 \
        pkg-config \
        python3 \
        sudo \
        wget \
    && apt-get autoremove --yes \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly --profile complete -y

ENV PATH="/root/.cargo/bin:${PATH}"

ARG WATCHMAN_VERSION
ENV WATCHMAN_VERSION_OVERRIDE=${WATCHMAN_VERSION}

WORKDIR /tmp/watchman

RUN wget "https://github.com/facebook/watchman/archive/v${WATCHMAN_VERSION}.tar.gz" \
    && tar -xf v${WATCHMAN_VERSION}.tar.gz -C . --strip-components=1 \
    && sed -i \
        -e 's/add_executable(${NAME}.t /&EXCLUDE_FROM_ALL /' \
        -e 's/add_library(testsupport STATIC /&EXCLUDE_FROM_ALL /' \
        CMakeLists.txt \
    && [ "$(grep -c 'EXCLUDE_FROM_ALL' CMakeLists.txt)" -eq 2 ]

# What autogen.sh does, one project per layer. Every call must pass identical
# flags: they feed the per-project hash stored in .built-by-getdeps, and a
# matching hash is what lets later layers skip projects built by earlier ones.
# Without --no-deps, each step still builds anything missing, so a stale list
# here only shifts work between layers.
ENV GETDEPS="python3 build/fbcode_builder/getdeps.py"
ENV GETDEPS_FLAGS="--allow-system-packages --no-tests --scratch-path=/tmp/getdeps --src-dir=watchman:. --project-install-prefix=watchman:/usr/local"

RUN $GETDEPS build $GETDEPS_FLAGS --only-deps folly
RUN $GETDEPS build $GETDEPS_FLAGS folly
RUN $GETDEPS build $GETDEPS_FLAGS fizz
RUN $GETDEPS build $GETDEPS_FLAGS mvfst
RUN $GETDEPS build $GETDEPS_FLAGS wangle
RUN $GETDEPS build $GETDEPS_FLAGS fbthrift
RUN $GETDEPS build $GETDEPS_FLAGS fb303
RUN $GETDEPS build $GETDEPS_FLAGS edencommon
RUN $GETDEPS build $GETDEPS_FLAGS watchman
RUN $GETDEPS fixup-dyn-deps $GETDEPS_FLAGS --final-install-prefix /usr/local watchman built


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Watchman Binaries ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
FROM ubuntu:24.04 AS watchman

COPY --from=builder /tmp/watchman/built/bin/ /usr/local/bin/
COPY --from=builder /tmp/watchman/built/lib /usr/local/lib/
