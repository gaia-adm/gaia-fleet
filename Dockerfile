# (!) IMPORTANT
# Use frolvlad/alpine-glibc Alpine image: it contains glibc (not only musl)
# glibc is required to run mounted host binaries, like: docker, fleetctl, etcdctl
FROM frolvlad/alpine-glibc:alpine-3.3_glibc-2.23
MAINTAINER Alexei Ledenev <alexei.led@gmail.com>

ENV gaia /home/gaia
RUN mkdir -p ${gaia}

WORKDIR ${gaia}
COPY *.service ./
COPY *.timer ./
COPY deploy.sh ./
COPY profile.sh ./
RUN chmod +x deploy.sh
RUN chmod +x profile.sh

# install bash
RUN apk --update add bash \
    && rm -rf /var/lib/apt/lists/* \
    && rm /var/cache/apk/*

CMD ["/bin/bash", "deploy.sh"]
