FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04@sha256:f7723cb8cebc1a23a8198e2deb631fd1fb5e36cda68601fda65e5f503ce63f31

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils 2>&1 \
    && apt-get -y install --no-install-recommends git procps lsb-release zsh \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=dialog