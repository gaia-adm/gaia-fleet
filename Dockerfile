FROM alpine:3.2
MAINTAINER Alexei Ledenev <alexei.led@gmail.com>

ENV FLEET_VERSION 0.11.5

COPY setup.sh /home/
COPY proxy.list /home/

COPY *.service /home/
COPY deploy.sh /home/
RUN chmod +x /home/deploy.sh

# run everything in one RUN command to keep proxy setting between shell commands
# this will not work if split into multiple RUN commands
RUN sh /home/setup.sh < /home/proxy.list && source /etc/profile.d/proxy.sh && echo "PROXY=${http_proxy}" \
  && apk update \
  && apk add curl openssl \
  && rm -rf /var/cache/apk/* \
  && curl -L "https://github.com/coreos/fleet/releases/download/v${FLEET_VERSION}/fleet-v${FLEET_VERSION}-linux-amd64.tar.gz" | tar xz \
  && mv fleet-v${FLEET_VERSION}-linux-amd64/fleetctl /usr/local/bin/ \
  && rm -rf fleet-v${FLEET_VERSION}-linux-amd64

CMD ["/bin/sh", "/home/deploy.sh"]
