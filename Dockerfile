# Use a slim Rust image as a base for a smaller footprint
FROM rust:1.88.0-slim-bullseye

# Install musl-tools and other necessary build dependencies
# musl-tools provides the musl-gcc compiler and related utilities
# pkg-config is often required by build scripts of C libraries
# build-essential provides essential build tools like make, gcc, etc.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    musl-tools \
    pkg-config \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add the x86_64-unknown-linux-musl target to Rustup
# This ensures the Rust toolchain can compile for musl
RUN rustup target add x86_64-unknown-linux-musl

# Set environment variables for OpenSSL to help openssl-sys find it
# When openssl-sys builds with 'vendored' feature, it compiles OpenSSL from source.
# The musl-tools provide the necessary C toolchain for this.
# These variables ensure the build system knows where to look for musl-compatible libraries.
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_SYSROOT_DIR=/usr/lib/x86_64-linux-musl
ENV OPENSSL_STATIC=1
ENV OPENSSL_DIR=/usr/local/musl # This is a common convention for musl-compiled OpenSSL

# Set the working directory inside the container
WORKDIR /usr/src/app

# Set the default command for the container (optional, but good practice)
CMD ["bash"]
