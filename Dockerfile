# Use a slim Rust image as a base
FROM rust:1.88.0-slim-bullseye

# Install musl-tools, a C/C++ compiler, and other necessary packages.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    musl-tools \
    build-essential \
    pkg-config \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Add the x86_64-unknown-linux-musl target to Rustup
RUN rustup target add x86_64-unknown-linux-musl

# Set the CC environment variable for the musl target to ensure the correct compiler is used
ENV CC_x86_64_unknown_linux_musl=musl-gcc

# Set the working directory inside the container
WORKDIR /usr/src/app

# Set the default command for the container
CMD ["bash"]
