# Rust Musl Builder
# This image provides a complete environment for building static Rust binaries
# with musl libc and vendored OpenSSL for maximum portability

FROM rust:1.88-slim-bookworm

# Set environment variables for static builds
ENV RUSTFLAGS="-C target-feature=+crt-static" \
    OPENSSL_STATIC=1 \
    OPENSSL_VENDORED=1 \
    PKG_CONFIG_ALLOW_CROSS=1 \
    CC_x86_64_unknown_linux_musl=/opt/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc \
    CC_aarch64_unknown_linux_musl=/opt/aarch64-linux-musl-cross/bin/aarch64-linux-musl-gcc \
    CARGO_HOME=/usr/local/cargo \
    CARGO_TARGET_DIR=/workspace/target

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    git \
    curl \
    musl-tools \
    musl-dev \
    gcc-multilib \
    libssl-dev \
    cmake \
    make \
    && rm -rf /var/lib/apt/lists/*

# Install musl cross-compilation toolchains
RUN curl -L https://musl.cc/x86_64-linux-musl-cross.tgz | tar xz -C /opt/ && \
    curl -L https://musl.cc/aarch64-linux-musl-cross.tgz | tar xz -C /opt/

# Add musl toolchains to PATH
ENV PATH="/opt/x86_64-linux-musl-cross/bin:/opt/aarch64-linux-musl-cross/bin:${PATH}"

# Add Rust musl targets
RUN rustup target add x86_64-unknown-linux-musl && \
    rustup target add aarch64-unknown-linux-musl

# Configure cargo for cross-compilation using absolute linker paths
RUN mkdir -p /usr/local/cargo && \
    echo '[target.x86_64-unknown-linux-musl]' > /usr/local/cargo/config.toml && \
    echo 'linker = "/opt/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc"' >> /usr/local/cargo/config.toml && \
    echo '' >> /usr/local/cargo/config.toml && \
    echo '[target.aarch64-unknown-linux-musl]' >> /usr/local/cargo/config.toml && \
    echo 'linker = "/opt/aarch64-linux-musl-cross/bin/aarch64-linux-musl-gcc"' >> /usr/local/cargo/config.toml

# Create a non-root user for building
RUN groupadd -r builder && useradd -r -g builder -m -s /bin/bash builder

# Switch to non-root user
USER builder
WORKDIR /workspace

# Verify installation by building a simple test program using cargo (respects config)
RUN cd /tmp && \
    cargo new --bin test-build && \
    cd test-build && \
    echo 'fn main() { println!("Musl builder ready!"); }' > src/main.rs && \
    cargo build --target x86_64-unknown-linux-musl --release && \
    cargo build --target aarch64-unknown-linux-musl --release && \
    rm -rf /tmp/test-build

# Default command
CMD ["bash"]
