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
        curl \
        zlib1g-dev \
        libzmq5-dev \
"

RUN apt-get update && \
    apt-get -y install $BUILD_DEPENDENCIES

ARG GIT_URL=https://github.com/ZencashOfficial/zen.git

RUN git clone -b master --single-branch "$GIT_URL" && \
    cd zen && \
    ./zcutil/build.sh -j$(nproc)


FROM ubuntu:bionic
LABEL maintainer="skinlayers@gmail.com"

ARG RUNTIME_DEPENDENCIES=" \
        libgomp1 \
        libzmq5 \
"

COPY --from=skinlayers/docker-zcash-sprout-keys /sprout-proving.key /
COPY --from=skinlayers/docker-zcash-sprout-keys /sprout-verifying.key /
COPY --from=skinlayers/docker-zcash-sprout-keys /sapling-spend.params /
COPY --from=skinlayers/docker-zcash-sprout-keys /sapling-output.params /
COPY --from=skinlayers/docker-zcash-sprout-keys /sprout-groth16.params /
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
    ln -s /sprout-verifying.key .zcash-params/sprout-verifying.key && \
    ln -s /sapling-spend.params .zcash-params/sapling-spend.params && \
    ln -s /sapling-output.params .zcash-params/sapling-output.params && \
    ln -s /sprout-groth16.params .zcash-params/sprout-groth16.params

VOLUME ["/data"]

EXPOSE 9033 18231

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/local/bin/zend", "-printtoconsole"]
