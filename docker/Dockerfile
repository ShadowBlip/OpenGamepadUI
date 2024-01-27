FROM archlinux:base-devel
LABEL org.opencontainers.image.title="OpenGamepadUI Builder"
LABEL org.opencontainers.image.description="Build container for OpenGamepadUI"
LABEL org.opencontainers.image.source="https://github.com/ShadowBlip/OpenGamepadUI"
LABEL org.opencontainers.image.version="4.2.1"

RUN sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

# Install dependencies
RUN echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" >> /etc/pacman.conf
RUN pacman --noconfirm -Syyu && pacman -S --needed --noconfirm \
  scons \
  pkgconf \
  gcc \
  gcc-libs \
  libxcursor \
  libxinerama \
  libxi \
  libxrandr \
  mesa \
  glu \
  libglvnd \
  alsa-lib \
  make \
  cmake \
  unzip \
  wget \
  git \
  libevdev \
  libxau \
  libxcb \
  libxdmcp \
  libxext \
  libxres \
  libxtst \
  squashfs-tools \
  rpm-tools \
  fontconfig \
  zip \
  jq

# Download and install the appropriate version of Godot
ARG GODOT_VERSION=4.2.1
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
