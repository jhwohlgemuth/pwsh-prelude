FROM mcr.microsoft.com/powershell:lts-ubuntu-18.04@sha256:b093384397cd45dbceb89bcaa65744ba0b3bdfce488bf89b339bb98f0563fd45

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils 2>&1 \
    && apt-get -y install --no-install-recommends git procps lsb-release zsh \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=dialog