# Use a slim Rust image as a base
FROM rust:1.88.0-slim-bullseye

# Install musl-tools and other necessary build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    musl-tools \
    pkg-config \
    build-essential \
    ca-certificates \
    perl \
    wget \
    tar \
    git \
    && rm -rf /var/lib/apt/lists/*

# Add the x86_64-unknown-linux-musl target to Rustup
RUN rustup target add x86_64-unknown-linux-musl

# --- Compile OpenSSL from Source for MUSL ---
# This step is the key to solving your issue.
# We'll download OpenSSL, configure it for musl, and build it statically.
# Note: Using no-asm can often fix issues with platform-specific headers and assembly.
# We also simplify the Configure script to rely on the musl-gcc compiler to do the work.
RUN set -ex; \
    export OPENSSL_VERSION="3.0.12"; \
    export OPENSSL_DIR="/usr/local/musl"; \
    export CC="musl-gcc"; \
    mkdir -p /usr/local/musl; \
    wget -qO- "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" | tar -xzf -; \
    cd "openssl-$OPENSSL_VERSION"; \
    ./Configure no-shared no-zlib no-asm \
    --prefix=$OPENSSL_DIR \
    --openssldir=$OPENSSL_DIR; \
    make -j$(nproc); \
    make install; \
    cd ..; \
    rm -rf "openssl-$OPENSSL_VERSION"; \
    
# Set environment variables for the OpenSSL build
ENV OPENSSL_STATIC=1
ENV OPENSSL_DIR=/usr/local/musl
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_PATH=/usr/local/musl/lib/pkgconfig
ENV CC="musl-gcc"
ENV CFLAGS="-fPIC -DOPENSSL_NO_ASM"
ENV LDFLAGS="-static"

# Set the working directory inside the container
WORKDIR /usr/src/app

# Set the default command for the container
CMD ["bash"]
