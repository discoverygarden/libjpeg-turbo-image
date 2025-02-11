# XXX: jdk is required for (at least) our build stages. Final run could possibly
# swap over to jre, but probably not worth the complexity.
ARG BASE_IMAGE=eclipse-temurin:11.0.26_4-jdk-focal

# renovate: datasource=github-releases depName=libjpeg-turbo/libjpeg-turbo
ARG LIBJPEGTURBO_VERSION=2.1.5.1

FROM $BASE_IMAGE

ARG TARGETARCH
ARG TARGETVARIANT

ARG LIBJPEGTURBO_VERSION

WORKDIR /tmp

# NOTE: can leave out this piece if you don't need the TurboJpegProcessor
# https://cantaloupe-project.github.io/manual/5.0/processors.html#TurboJpegProcessor
RUN \
  --mount=type=cache,target=/var/lib/apt/lists,sharing=locked,id=debian-apt-lists-$TARGETARCH$TARGETVARIANT \
  --mount=type=cache,target=/var/cache/apt/archives,sharing=locked,id=debian-apt-archives-$TARGETARCH$TARGETVARIANT \
  <<EOS
set -eux
apt-get update -qqy
apt-get install -qqy cmake g++ make nasm checkinstall
EOS

ADD --link https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${LIBJPEGTURBO_VERSION}/libjpeg-turbo-${LIBJPEGTURBO_VERSION}.tar.gz ./

RUN tar -xpf libjpeg-turbo-${LIBJPEGTURBO_VERSION}.tar.gz

WORKDIR libjpeg-turbo-${LIBJPEGTURBO_VERSION}

RUN cmake \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_INSTALL_LIBDIR=/usr/lib \
  -DBUILD_SHARED_LIBS=True \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DWITH_JPEG8=1 \
  -DWITH_JAVA=1

RUN make

RUN checkinstall --default --install=no

WORKDIR /tmp

RUN ln libjpeg-turbo-${LIBJPEGTURBO_VERSION}/libjpeg-turbo_${LIBJPEGTURBO_VERSION}-1_${TARGETARCH}.deb libjpeg-turbo_$TARGETARCH-$TARGETVARIANT.deb
