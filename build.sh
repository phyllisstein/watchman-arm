apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y \
    autoconf \
    automake \
    build-essential \
    cmake \
    curl \
    git \
    libpcre2-dev \
    libsodium-dev \
    libssl-dev \
    libtool \
    libz-dev \
    python3 \
    sudo \
    wget

apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y \
    build-essential \
    curl \
    git \
    libssl-dev \
    python3 \
    sudo

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly -y

source "$HOME/.cargo/env"

git clone https://github.com/facebook/watchman

# ae4b38f5a4ccab86f429b615efed00d50ee32d97
