FROM rust:1.92
LABEL org.opencontainers.image.title="OpenGamepadUI Builder Container"
LABEL org.opencontainers.image.description="Build container for OpenGamepadUI"
LABEL org.opencontainers.image.source="https://github.com/ShadowBlip/OpenGamepadUI"
LABEL org.opencontainers.image.version="4.6.1"

RUN dpkg --add-architecture arm64
RUN apt-get update && apt-get install -y \
  fontconfig \
  git \
  jq \
  libclang-dev \
  make \
  pkgconf \
  rpm \
  squashfs-tools \
  unzip \
  wget \
  zip \
  zstd

RUN apt-get install -y \
  g++-aarch64-linux-gnu \
  libc6-dev-arm64-cross

RUN rustup target add aarch64-unknown-linux-gnu
RUN rustup toolchain install --force-non-host stable-aarch64-unknown-linux-gnu
RUN rustup component add clippy

ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
ENV CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc
ENV CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-g++

# Download and install the appropriate version of Godot
ARG GODOT_VERSION=4.6.1
ARG GODOT_RELEASE=stable
RUN mkdir /tmp/godot && \
  wget -q https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64.zip -O /tmp/godot/godot.zip && \
  cd /tmp/godot && \
  unzip godot.zip && \
  mv Godot_v*.x86_64 /usr/bin/godot

# Create a home directory for the builder
RUN mkdir -p /home/build/.local/share/godot/export_templates && chmod -R 777 /home/build

# Download the Godot export template
RUN export TEMPLATE_DIR=/home/build/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE} && \
  export URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_export_templates.tpz" && \
  wget "${URL}" -O /home/build/.local/share/godot/export_templates/templates.zip && \
  unzip /home/build/.local/share/godot/export_templates/templates.zip -d /home/build/.local/share/godot/export_templates/ && \
  rm /home/build/.local/share/godot/export_templates/templates.zip && \
  mv /home/build/.local/share/godot/export_templates/templates ${TEMPLATE_DIR}
