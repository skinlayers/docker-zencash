FROM buildpack-deps:bionic as zencash-builder
LABEL maintainer="skinlayers@gmail.com"

ARG BUILD_DEPENDENCIES=" \
        autoconf \
        automake \
        bsdmainutils \
        build-essential \
        g++-multilib \
        pkg-config \
        libc6-dev \
        libtool \
        m4 \
        ncurses-dev \
        python \
        unzip \
        wget \
        zlib1g-dev \
        libzmq5-dev \
"

RUN apt-get update && \
    apt-get -y install $BUILD_DEPENDENCIES

ARG GIT_URL=https://github.com/ZencashOfficial/zen.git
ARG GIT_BRANCH=master
ARG GIT_COMMIT=9116ad51b2489ea36a48c786d9a39acb24e23264

RUN git clone -b "$GIT_BRANCH" --single-branch "$GIT_URL" && \
    cd zen && \
    git reset --hard "$GIT_COMMIT" && \
    ./zcutil/build.sh


FROM ubuntu:bionic
LABEL maintainer="skinlayers@gmail.com"

ARG RUNTIME_DEPENDENCIES=" \
        libgomp1 \
        libzmq5 \
"

COPY --from=zencash-builder /sprout-proving.key /
COPY --from=zencash-builder /sprout-verifying.key /
COPY ./docker-entrypoint.sh /

ARG BUILDER_PATH=/zen/src
COPY --from=zencash-builder $BUILDER_PATH/zen-cli /usr/local/bin
COPY --from=zencash-builder $BUILDER_PATH/zend /usr/local/bin

RUN set -eu && \
    adduser --system -u 400 --group --home /data zencash && \
    mkdir -m 0700 /data/.zen && \
    chmod +x /docker-entrypoint.sh && \
    apt-get update && \
    apt-get -y install $RUNTIME_DEPENDENCIES && \
    rm -r /var/lib/apt/lists/*

COPY --from=zencash-builder /zen/contrib/debian/examples/zen.conf /data/.zen

RUN { \
        echo ''; \
        echo '# Required for backuping up the wallet'; \
        echo ''; \
        echo 'exportdir=/data'; \
    } >> /data/.zen/zen.conf && \
    chmod 0600 /data/.zen/zen.conf && \
    chown -R zencash:zencash /data/.zen

USER zencash

WORKDIR /data

RUN mkdir -m 0700 .zcash-params && \
    ln -s /sprout-proving.key .zcash-params/sprout-proving.key && \
    ln -s /sprout-verifying.key .zcash-params/sprout-verifying.key

VOLUME ["/data"]

EXPOSE 8231 9033

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/local/bin/zend", "-printtoconsole"]
