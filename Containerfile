FROM scratch AS ctx

COPY ./packages /packages
COPY ./files /files

FROM cgr.dev/chainguard/wolfi-base AS builder

# This allows using this container to make a deployment.
RUN ln -s sysroot/ostree /ostree

# We need the ostree hook.
RUN install -d /mnt/etc
COPY --from=ctx /files/ostree.conf /mnt/etc/dracut.conf.d/
COPY --from=ctx /files/module-setup.sh /mnt/etc/dracut.conf.d/

RUN --mount=type=bind,from=ctx,source=/,target=/ctx apk add -X https://packages.wolfi.dev/os --allow-untrusted -U --initdb -p /mnt \
    /ctx/packages/$(arch)/ostree*.apk \
    /ctx/packages/$(arch)/composefs*.apk \
    /ctx/packages/$(arch)/boot*.apk \
    /ctx/packages/$(arch)/dracut*.apk \
    wolfi-base \
    libselinux \
    findmnt \
    podman \
    btrfs-progs
    # /ctx/packages/$(arch)/linux*.apk \

# Add ostree tmpfile
COPY --from=ctx files/ostree-0-integration.conf /mnt/usr/lib/tmpfiles.d/
COPY --from=ctx files/prepare-root.conf /mnt/usr/lib/ostree/

RUN --mount=type=bind,from=ctx,source=/,target=/ctx apk add --allow-untrusted \
    /ctx/packages/$(arch)/composefs*.apk \
    /ctx/packages/$(arch)/ostree*.apk

RUN mkdir -p /mnt/sysroot/ostree && ostree init --repo /mnt/sysroot/ostree/repo --verbose

RUN ostree commit --repo /mnt/sysroot/ostree/repo --branch latest --no-xattrs --bootable /mnt

# Turn the pacstrapped rootfs into a container image.
FROM scratch
COPY --from=builder /mnt /

# Generate initramfs
# RUN --mount=tmpfs,dst=/var/tmp /usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v -f

# Alter root file structure a bit for ostree
RUN mkdir -p /sysroot/ostree /efi /boot && \
    rm -rf /boot/* /var/log /home /root /usr/local /srv && \
    ln -s sysroot/ostree /ostree && \
    ln -s var/home /home && \
    ln -s var/roothome /root && \
    ln -s var/usrlocal /usr/local && \
    ln -s var/srv /srv

RUN ostree commit --repo /sysroot/ostree/repo --branch latest --no-xattrs

# Necessary labels
LABEL containers.bootc 1
