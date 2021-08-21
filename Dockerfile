ARG LUET_VERSION=0.17.8

FROM quay.io/luet/base:$LUET_VERSION AS luet

FROM fedora:34 as base 
ARG ARCH=amd6
ARG TARGETARCH
ENV ARCH=${ARCH}
ENV LUET_NOLOCK=true

# Copy the luet config file pointing to the upgrade repository
COPY conf/luet.yaml /etc/luet/luet.yaml

# Copy luet from the official images
COPY --from=luet /usr/bin/luet /usr/bin/luet

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

RUN if [[ TARGETARCH == "amd64" ]]; then dnf install -y grub2-pc grub2-efi-x64 grub2-efi-x64-modules; fi

RUN luet install -y \
    meta/cos-minimal \
    utils/k9s \
    utils/nerdctl

COPY files/ /
RUN dracut --regenerate-all -f
RUN kernel=$(ls /boot/vmlinuz-* | head -n1) && \
    ln -sf "${kernel#/boot/}" /boot/vmlinuz

RUN kernel=$(ls /lib/modules | head -n1) && \
    cd /boot && \
    ln -sf *.img initrd

FROM base as master
RUN curl -sfL https://get.k3s.io > installer.sh
RUN INSTALL_K3S_SKIP_START="true" INSTALL_K3S_SKIP_ENABLE="true" sh installer.sh
RUN rm -rf installer.sh
COPY k3s/master.yaml /

FROM base as agent
RUN curl -sfL https://get.k3s.io > installer.sh
RUN INSTALL_K3S_SKIP_START="true" INSTALL_K3S_SKIP_ENABLE="true" sh installer.sh agent
RUN rm -rf installer.sh
COPY k3s/agent.yaml /
