FROM archlinux:base-devel
LABEL org.opencontainers.image.title="OpenGamepadUI Builder"
LABEL org.opencontainers.image.description="Build container for OpenGamepadUI"
LABEL org.opencontainers.image.source="https://github.com/ShadowBlip/OpenGamepadUI"
LABEL org.opencontainers.image.version="4.1.2"

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
	fontconfig \
	zip \
	godot

# Create a home directory for the builder
RUN mkdir -p /home/build/.local/share/godot/export_templates && chmod -R 777 /home/build

# Download the Godot export template
RUN export GODOT_VERSION=$(godot --version) && \
	export RELEASE=$(echo ${GODOT_VERSION} | cut -d'.' -f 3) && \
	export VERSION=$(echo ${GODOT_VERSION} | cut -d'.' -f 1,2) && \
	export TEMPLATE_DIR=/home/build/.local/share/godot/export_templates/${VERSION}.${RELEASE} && \
	export URL="https://github.com/godotengine/godot/releases/download/${VERSION}-${RELEASE}/Godot_v${VERSION}-${RELEASE}_export_templates.tpz" && \
	wget "${URL}" -O /home/build/.local/share/godot/export_templates/templates.zip && \
	unzip /home/build/.local/share/godot/export_templates/templates.zip -d /home/build/.local/share/godot/export_templates/ && \
	rm /home/build/.local/share/godot/export_templates/templates.zip && \
	mv /home/build/.local/share/godot/export_templates/templates ${TEMPLATE_DIR}
