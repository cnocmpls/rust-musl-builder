# Use a slim Rust image as a base for a smaller footprint
FROM rust:1.88.0-slim-bullseye

# Install musl-tools, a C/C++ compiler, and a few other necessary packages.
# `musl-tools` provides the `musl-gcc` compiler and libc.
# `build-essential` contains the tools needed to build C libraries from source.
# `ca-certificates` is crucial for HTTPS requests.
# `git` is often a dependency of crates that pull from Git repos.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    musl-tools \
    build-essential \
    pkg-config \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Add the x86_64-unknown-linux-musl target to Rustup.
# This ensures the Rust toolchain can compile for musl.
RUN rustup target add x86_64-unknown-linux-musl

# Set environment variables to enable static linking for musl target.
# These hints guide the openssl-sys build script to compile OpenSSL itself.
ENV OPENSSL_DIR=/usr/local/musl
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV OPENSSL_STATIC=1
ENV CC=musl-gcc

# Set the working directory inside the container
WORKDIR /usr/src/app

# Set the default command for the container
CMD ["bash"]
