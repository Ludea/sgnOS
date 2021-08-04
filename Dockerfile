ARG LUET_VERSION=0.17.2

FROM quay.io/luet/base:$LUET_VERSION AS luet

FROM fedora:34
ARG ARCH=amd64
ENV ARCH=${ARCH}
ENV LUET_NOLOCK=true

# Copy the luet config file pointing to the upgrade repository
COPY conf/luet.yaml /etc/luet/luet.yaml

# Copy luet from the official images
COPY --from=luet /usr/bin/luet /usr/bin/luet

RUN dnf install -y \
    grub2-pc \
    grub2-efi-x64 \
    grub2-efi-x64-modules \
    NetworkManager \
    squashfs-tools \ 
    dracut-live \
    efibootmgr \
    audit \
    kernel \
    systemd \
    parted \
    dracut \
    e2fsprogs \
    dosfstools \
    coreutils \
    device-mapper \
    grub2 \
    which \
    curl \
    nano \
    gawk \
    haveged \
    tar \
    rsync 

RUN luet install -y \
    toolchain/yip \
    utils/installer \
    system/cos-setup \
    system/immutable-rootfs \
    system/grub-config \
    system/cloud-config \
    utils/k9s \
    utils/nerdctl

COPY files/ /
RUN dracut --regenerate-all -f
RUN kernel=$(ls /boot/vmlinuz-* | head -n1) && \
    ln -sf "${kernel#/boot/}" /boot/vmlinuz

RUN kernel=$(ls /lib/modules | head -n1) && \
    cd /boot && \
    ln -sf "initrd-${kernel}" initrd
