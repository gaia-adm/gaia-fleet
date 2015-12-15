FROM alpine:3.2
MAINTAINER Alexei Ledenev <alexei.led@gmail.com>

ENV FLEET_VERSION 0.11.5

COPY setup.sh /
COPY proxy.list /

COPY *.service /
COPY deploy.sh /
RUN chmod +x /deploy.sh

# run everything in one RUN command to keep proxy setting between shell commands
# this will not work if split into multiple RUN commands
RUN sh /setup.sh < /proxy.list && source /etc/profile.d/proxy.sh && echo "PROXY=${http_proxy}" \
  && apk add --update shadow \
  && apk add curl openssl \
  && rm -rf /var/cache/apk/* \
  && curl -L "https://github.com/coreos/fleet/releases/download/v${FLEET_VERSION}/fleet-v${FLEET_VERSION}-linux-amd64.tar.gz" | tar xz \
  && mv fleet-v${FLEET_VERSION}-linux-amd64/fleetctl /usr/local/bin/ \
  && rm -rf fleet-v${FLEET_VERSION}-linux-amd64

CMD ["/bin/sh", "deploy.sh"]
