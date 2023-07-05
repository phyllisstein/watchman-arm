FROM ubuntu:jammy as builder

ENV WATCHMAN_VERSION="2023.07.03.00" \
  GOOGLETEST_VERSION="1.10.0" \
  FOLLY_VERSION="2022.01.10.00"

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install \
      -o Dpkg::Options::="--force-confold" \
      -o Dpkg::Options::="--force-confnew" \
      --yes \
    ca-certificates \
    cmake \
    curl \
    git \
    build-essential \
    libdouble-conversion3 \
    libdouble-conversion-dev \
    libevent-2.1-7 \
    libevent-dev \
    libfmt-dev \
    libgoogle-glog0v5 \
    libgoogle-glog-dev \
    libssl1.1 \
    libssl-dev \
    libpcre3 \
    libpcre3-dev \
    pkg-config \
    python3 \
    ruby \
    wget \
  && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
  && . "$HOME/.cargo/env" \
  && rustup install nightly \
  && rustup default nightly \
  && gem install fpm

RUN cd /tmp \
  && wget -O boost.tar.gz https://boostorg.jfrog.io/artifactory/main/release/1.67.0/source/boost_1_67_0.tar.gz \
  && tar -xf boost.tar.gz \
  && cd boost_1_67_0 \
  && ./bootstrap.sh --prefix=/usr/local \
  && ./b2 install --prefix=/usr/local link=static runtime-link=static

RUN cd /tmp \
  && wget -O gflags.tar.gz https://github.com/gflags/gflags/archive/refs/tags/v2.2.2.tar.gz \
  && tar -xf gflags.tar.gz \
  && cd gflags-2.2.2 \
  && mkdir build \
  && cd build \
  && cmake .. \
  && make install

RUN cd /tmp \
  && git clone --branch=v${FOLLY_VERSION} --depth=1 https://github.com/facebook/folly \
  && cd folly \
  && ./folly/build/build-debs-ubuntu-18.04.sh

RUN cd /tmp \
  && wget "https://github.com/google/googletest/archive/release-${GOOGLETEST_VERSION}.tar.gz" \
  && tar xf release-${GOOGLETEST_VERSION}.tar.gz \
  && cd googletest-release-${GOOGLETEST_VERSION} \
  && cmake . \
    -DCMAKE_INSTALL_PREFIX="/tmp/googletest" \
  && make install

ENV CMAKE_CXX_FLAGS="-static -fPIC" \
  CMAKE_C_FLAGS="-static -fPIC" \
  CMAKE_SHARED_LINKER_FLAGS="-static -fPIC" \
  CFLAGS="-static -fPIC" \
  CXXFLAGS="-static -fPIC" \
  LDFLAGS="-static -fPIC" \
  CC="/usr/bin/gcc-9" \
  CXX="/usr/bin/g++-9" \
  CMAKE_CXX_COMPILER="/usr/bin/g++-9" \
  CMAKE_C_COMPILER="/usr/bin/gcc-9"

RUN mkdir -p /tmp/watchman && cd /tmp/watchman \
  && wget "https://github.com/facebook/watchman/archive/v${WATCHMAN_VERSION}.tar.gz" \
  && tar xf v${WATCHMAN_VERSION}.tar.gz \
  && cd watchman-${WATCHMAN_VERSION} \
  && cd /tmp/watchman/watchman-${WATCHMAN_VERSION} \
  && . "$HOME/.cargo/env" \
  && GTest_DIR="/tmp/googletest" GMock_DIR="/tmp/googletest" cmake -S . -B build \
    -DENABLE_EDEN_SUPPORT=OFF \
    -DWATCHMAN_VERSION_OVERRIDE="v${WATCHMAN_VERSION}" \
    -DWATCHMAN_STATE_DIR=/var/run/watchman \
    -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS}" \
    -DCMAKE_SHARED_LINKER_FLAGS="${CMAKE_SHARED_LINKER_FLAGS}" \
  && cmake --build build \
  && cmake --install build

FROM ubuntu:focal as watchman

COPY --from=builder /usr/local/bin/watchman* /usr/local/bin/
RUN mkdir -p /var/run/watchman
