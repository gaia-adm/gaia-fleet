FROM alpine:3.3
MAINTAINER Alexei Ledenev <alexei.led@gmail.com>

ENV gaia /home/gaia
RUN mkdir -p ${gaia}

WORKDIR ${gaia}
COPY *.service ./
COPY deploy.sh ./
RUN chmod +x deploy.sh

# install bash
RUN apk --update add bash \
    && rm -rf /var/lib/apt/lists/* \
    && rm /var/cache/apk/*

CMD ["/bin/bash", "deploy.sh"]
