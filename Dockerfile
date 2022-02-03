ARG LUET_VERSION=0.22.4

FROM quay.io/luet/base:$LUET_VERSION AS luet

FROM fedora:35 as base 

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

RUN luet install -y meta/cos-verify

RUN luet install --plugin luet-cosign -y \
    meta/cos-core \
    system/kernel \
    utils/k9s \

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
