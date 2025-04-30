build $package="":
    podman run \
        --rm -it -v "${PWD}:/work:Z" --privileged \
        cgr.dev/chainguard/melange build "packages/${package}.yaml" --arch host --signing-key melange.rsa

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
        -v /dev:/dev \
        -t wolfi-bootc:latest .

bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev \
        -v .:/run/host:Z \
        --security-opt label=type:unconfined_t \
        wolfi-bootc:latest bootc {{ARGS}}
    
