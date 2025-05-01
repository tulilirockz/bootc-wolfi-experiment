build $package="":
    podman run \
        --rm -it -v "${PWD}:/work:Z" --privileged \
        cgr.dev/chainguard/melange \
        --workspace-dir /work \
        build "packages/${package}.yaml" --arch host --signing-key melange.rsa

build-container $package="" $import="1":
    #!/usr/bin/env bash
    podman run \
        --rm -it --workdir /work -v "${PWD}:/work:Z" \
        cgr.dev/chainguard/apko build "containers/${package}.yaml" "${package}:latest" "${package}.tar" --arch host

    if [ "${import}" == "1" ] ; then
        podman load < "${package}.tar"
    fi

renovate:
    #!/usr/bin/env bash
    GITHUB_COM_TOKEN=$(cat ~/.ssh/gh_renovate) LOG_LEVEL=${LOG_LEVEL:-debug} renovate --platform=local

build-image:
    sudo podman build \
        -t wolfi-bootc:latest .

bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev \
        -v .:/data:Z \
        --security-opt label=type:unconfined_t \
        --entrypoint /bin/sh \
        wolfi-bootc:latest {{ARGS}}
    
