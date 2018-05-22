FROM debian:stretch

MAINTAINER crito <crito@blizzlike.org>

ENV APP_DIR /home/blizzlike

RUN apt-get update && \
  apt-get install -y lua5.2 lua-cjson lua-sec \
    lua-socket lua-luaossl \
    openssl mariadb-client xz-utils

RUN useradd \
  -m -d ${APP_DIR} \
  -s /bin/bash \
  -U blizzlike

COPY --chown=blizzlike ./src ${APP_DIR}/bkp2gdrive
WORKDIR ${APP_DIR}
USER blizzlike

RUN install -d ${APP_DIR}/bkp2gdrive/config

VOLUME ["${APP_DIR}/bkp2gdrive/config"]
CMD ["tail", "-f", "/dev/null"]
