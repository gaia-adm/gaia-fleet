FROM alpine:3.2
MAINTAINER Alexei Ledenev <alexei.led@gmail.com>

ENV FLEET_VERSION 0.11.5

ENV gaia /home/gaia
RUN mkdir -p ${gaia}

WORKDIR ${gaia}
COPY *.service ./
COPY deploy.sh ./
RUN chmod +x deploy.sh

# install packages and fleetctl client
RUN apk update && \
    apk add curl openssl bash && \
    rm -rf /var/cache/apk/* && \
    curl -L "https://github.com/coreos/fleet/releases/download/v${FLEET_VERSION}/fleet-v${FLEET_VERSION}-linux-amd64.tar.gz" | tar xz && \
    mv fleet-v${FLEET_VERSION}-linux-amd64/fleetctl /usr/local/bin/ && \
    rm -rf fleet-v${FLEET_VERSION}-linux-amd64

CMD ["/bin/bash", "deploy.sh"]
