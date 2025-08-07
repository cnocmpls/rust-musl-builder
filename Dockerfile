# Rust Musl Builder
# This image provides a complete environment for building static Rust binaries
# with musl libc and vendored OpenSSL for maximum portability

FROM rust:1.88-slim-bullseye

# Set environment variables for static builds
ENV RUSTFLAGS="-C target-feature=+crt-static" \
    OPENSSL_STATIC=1 \
    OPENSSL_VENDORED=1 \
    PKG_CONFIG_ALLOW_CROSS=1 \
    CC_x86_64_unknown_linux_musl=x86_64-linux-musl-gcc \
    CC_aarch64_unknown_linux_musl=aarch64-linux-musl-gcc

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    pkg-config \
    git \
    curl \
    # Musl toolchain for x86_64
    musl-tools \
    musl-dev \
    # Cross compilation tools
    gcc-multilib \
    # SSL development libraries (backup for system linking if needed)
    libssl-dev \
    # Common build dependencies
    cmake \
    make \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Install musl cross-compilation toolchains
RUN curl -L https://musl.cc/x86_64-linux-musl-cross.tgz | tar xz -C /opt/ && \
    curl -L https://musl.cc/aarch64-linux-musl-cross.tgz | tar xz -C /opt/

# Add musl toolchains to PATH
ENV PATH="/opt/x86_64-linux-musl-cross/bin:/opt/aarch64-linux-musl-cross/bin:${PATH}"

# Add Rust musl targets
RUN rustup target add x86_64-unknown-linux-musl && \
    rustup target add aarch64-unknown-linux-musl

# Configure cargo for cross-compilation
RUN mkdir -p /usr/local/cargo && \
    echo '[target.x86_64-unknown-linux-musl]' > /usr/local/cargo/config.toml && \
    echo 'linker = "x86_64-linux-musl-gcc"' >> /usr/local/cargo/config.toml && \
    echo '' >> /usr/local/cargo/config.toml && \
    echo '[target.aarch64-unknown-linux-musl]' >> /usr/local/cargo/config.toml && \
    echo 'linker = "aarch64-linux-musl-gcc"' >> /usr/local/cargo/config.toml

# Set CARGO_HOME to use our config
ENV CARGO_HOME=/usr/local/cargo

# Create a non-root user for building
RUN groupadd -r builder && useradd -r -g builder -m -s /bin/bash builder
USER builder
WORKDIR /workspace

# Verify installation by building a simple test program
RUN echo 'fn main() { println!("Musl builder ready!"); }' > test.rs && \
    rustc --target x86_64-unknown-linux-musl test.rs -o test-x86_64 && \
    rustc --target aarch64-unknown-linux-musl test.rs -o test-aarch64 && \
    rm test.rs test-x86_64 test-aarch64

# Default command
CMD ["bash"]
