ARG LUET_VERSION=0.20.10

FROM quay.io/luet/base:$LUET_VERSION AS luet

FROM fedora:35 as base 

ARG ARCH=amd64
ARG NODE=agent
ENV COSIGN_EXPERIMENTAL=1
ENV COSIGN_REPOSITORY=raccos/releases-blue

RUN dnf install -y \
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

# Copy the luet config file pointing to the upgrade repository
COPY conf/luet.yaml /etc/luet/luet.yaml
RUN curl -L https://github.com/mudler/luet/releases/download/0.20.10/luet-0.20.10-linux-${ARCH} --output /usr/bin/luet

RUN chmod +x /usr/bin/luet
RUN luet install -y meta/cos-verify

RUN luet install -y \
    meta/cos-minimal \
    utils/k9s \
    utils/nerdctl

COPY files/ /

RUN curl -sfL https://get.k3s.io > installer.sh
RUN INSTALL_K3S_SKIP_START="true" INSTALL_K3S_SKIP_ENABLE="true" sh installer.sh ${NODE}
RUN rm -rf installer.sh
COPY k3s/${NODE}.yaml /

RUN dracut --regenerate-all -f
RUN kernel=$(ls /boot/vmlinuz-* | head -n1) && \
    ln -sf "${kernel#/boot/}" /boot/vmlinuz

RUN kernel=$(ls /lib/modules | head -n1) && \
    cd /boot && \
    ln -sf *.img initrd

FROM base as k3s-amd64
RUN dnf install -y \ 
         grub2-pc \
         grub2-efi-x64 \
         grub2-efi-x64-modules

FROM base as k3s-arm64
RUN dnf install -y \ 
         grub2-arm64-efi \
         raspberrypi-eeprom \
         bcm43xx-firmware \
         systemd-sysvinit \
