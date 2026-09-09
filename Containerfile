# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base Image (Pascal / GTX 1050 Ti Legacy NVIDIA Support)
FROM ghcr.io/ublue-os/bazzite-nvidia:stable

### MODIFICATIONS
# 1) Change Plymouth Boot Logo
COPY system_files/steamos-watermark.png /usr/share/plymouth/themes/spinner/watermark.png
COPY system_files/steamos-watermark.png /usr/share/plymouth/themes/bgrt/watermark.png
RUN \
  --mount=type=bind,from=ghcr.io/blue-build/modules:latest,src=/modules,dst=/tmp/modules,rw \
  --mount=type=bind,from=ghcr.io/blue-build/cli/build-scripts:latest,src=/scripts/,dst=/tmp/scripts/ \
  /tmp/scripts/run_module.sh 'initramfs' '{"type":"initramfs"}'

# 2) Disable Bazzite Steam Videos Script
RUN printf '#!/usr/bin/bash\nexit 0\n' > /usr/bin/bazzite-steam-brand && \
    chmod +x /usr/bin/bazzite-steam-brand

# 3) Replace OS Logos
COPY system_files/steamos-logo.png /usr/share/pixmaps/fedora_logo_med.png
COPY system_files/steamos-white-logo.png /usr/share/pixmaps/fedora_whitelogo_med.png
COPY system_files/steamos-logo.svg /usr/share/icons/hicolor/scalable/places/bazzite-logo.svg
COPY system_files/steamos-logo-white.svg /usr/share/icons/hicolor/scalable/places/bazzite-logo-white.svg
COPY system_files/steamos-logo-le.svg /usr/share/icons/hicolor/scalable/places/bazzite-logo-le.svg

# 4) Rename Bazzite across OS
RUN sed -i \
  -e 's/^NAME=.*/NAME="SteamOS"/' \
  -e 's/^PRETTY_NAME=.*/PRETTY_NAME="SteamOS"/' \
  /usr/lib/os-release

## Run build script logic
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
