# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
FROM alpine:3.12.3 AS builder

RUN apk add --no-cache \
  coreutils \
  openssl \
  bash \
  patch \
  build-base \
  autoconf \
  automake \
  libtool \
  diffutils \
  cmake \
  git \
  yasm \
  nasm \
  zlib-dev \
  zlib-static

# bump: gm /GM_VERSION=([\d.]+)/ fetch:http://hg.code.sf.net/p/graphicsmagick/code/raw-file/GraphicsMagick-1_3/.hgtags|/.* GraphicsMagick-(\d+_\d+_\d+).*/|/_/./|^1
ARG GM_VERSION=1.3.35
ARG GM_URL="https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick/$GM_VERSION/GraphicsMagick-$GM_VERSION.tar.gz/download"
ARG GM_SHA256=d96d5ce2ef7e0e90166551e38742713728bfd33d6f18495a9ddda938700fc055
# bump: libpng /LIBPNG_VERSION=([\d.]+)/ https://github.com/glennrp/libpng.git|/^\d+.\d+.\d+/|~1
ARG LIBPNG_VERSION=1.6.37
ARG LIBPNG_URL="https://sourceforge.net/projects/libpng/files/libpng16/$LIBPNG_VERSION/libpng-$LIBPNG_VERSION.tar.gz/download"
ARG LIBPNG_SHA256=daeb2620d829575513e35fecc83f0d3791a620b9b93d800b763542ece9390fb4
# bump: jpeg /JPEG_VERSION=([\d.a-z]+)/ fetch:http://www.ijg.org|/The current version is release (.*) of/
ARG JPEG_VERSION=9d
ARG JPEG_URL="http://www.ijg.org/files/jpegsrc.v$JPEG_VERSION.tar.gz"
ARG JPEG_SHA256=99cb50e48a4556bc571dadd27931955ff458aae32f68c4d9c39d624693f69c32
# bump: jasper /JASPER_VERSION=([\d.]+)/ https://github.com/mdadams/jasper.git|^2
ARG JASPER_VERSION=2.0.23
ARG JASPER_URL="https://github.com/mdadams/jasper/archive/version-$JASPER_VERSION.tar.gz"
ARG JASPER_SHA256=20facc904bd9d38c20e0c090b1be3ae02ae5b2703b803013be2ecad586a18927
# bump: libwebp /WEBP_VERSION=([\d.]+)/ https://github.com/webmproject/libwebp.git|*
ARG LIBWEBP_VERSION=1.1.0
ARG LIBWEBP_URL="https://github.com/webmproject/libwebp/archive/v$LIBWEBP_VERSION.tar.gz"
ARG LIBWEBP_SHA256=424faab60a14cb92c2a062733b6977b4cc1e875a6398887c5911b3a1a6c56c51
# bump: libtiff /TIFF_VERSION=([\d.]+)/ https://gitlab.com/libtiff/libtiff.git|^4
ARG TIFF_VERSION=4.1.0
ARG TIFF_URL="http://download.osgeo.org/libtiff/tiff-$TIFF_VERSION.tar.gz"
ARG TIFF_SHA256=5d29f32517dadb6dbcd1255ea5bbc93a2b54b94fbf83653b4d65c7d6775b8634

ARG CFLAGS="-O3 -fno-strict-overflow -fstack-protector-all -fPIE"
ARG CXXFLAGS="-O3 -fno-strict-overflow -fstack-protector-all -fPIE"
ARG LDFLAGS="-Wl,-z,relro -Wl,-z,now -fPIE -pie"

RUN \
  wget -O libpng.tar.gz "$LIBPNG_URL" && \
  echo "$LIBPNG_SHA256  libpng.tar.gz" | sha256sum --status -c - && \
  tar xfz libpng.tar.gz && \
  cd libpng-* && \
  ./configure \
  --enable-static \
  --disable-shared \
  && \
  make -j$(nproc) install

RUN \
  wget -O jpeg.tar.gz "$JPEG_URL" && \
  echo "$JPEG_SHA256  jpeg.tar.gz" | sha256sum --status -c - && \
  tar xfz jpeg.tar.gz && \
  cd jpeg-* && \
  ./configure \
  --enable-static \
  --disable-shared \
  && \
  make -j$(nproc) install

RUN \
  wget -O jasper.tar.gz "$JASPER_URL" && \
  echo "$JASPER_SHA256  jasper.tar.gz" | sha256sum --status -c - && \
  tar xfz jasper.tar.gz && \
  cd jasper-* && \
  mkdir tmp && \
  cd tmp && \
  cmake -G "Unix Makefiles" -DJAS_ENABLE_SHARED=OFF -H.. -B. && \
  make -j$(nproc) install

RUN \
  wget -O libwebp.tar.gz "$LIBWEBP_URL" && \
  echo "$LIBWEBP_SHA256  libwebp.tar.gz" | sha256sum --status -c - && \
  tar xfz libwebp.tar.gz && \
  cd libwebp-* && \
  ./autogen.sh && \
  ./configure \
  --enable-static \
  --disable-shared \
  --enable-libwebpmux \
  --enable-libwebpdemux \
  --enable-libwebpdecoder \
  && \
  make -j$(nproc) install

RUN \
  wget -O tiff.tar.gz "$TIFF_URL" && \
  echo "$TIFF_SHA256  tiff.tar.gz" | sha256sum --status -c - && \
  tar xfz tiff.tar.gz && \
  cd tiff-* && \
  ./autogen.sh && \
  ./configure \
  --enable-static \
  --disable-shared \
  --disable-webp \
  && \
  make -j$(nproc) install

RUN \
  wget -O gm.tar.gz "$GM_URL" && \
  echo "$GM_SHA256  gm.tar.gz" | sha256sum --status -c - && \
  tar xfz gm.tar.gz && \
  cd GraphicsMagick-* && \
  ./configure \
  --enable-static \
  --disable-shared \
  --disable-dependency-tracking \
  --with-quantum-depth=16 \
  && \
  make -j$(nproc) install LDFLAGS="-all-static"

# make sure binary have no dependencies
RUN test $(ldd /usr/local/bin/gm | wc -l) -eq 1

FROM scratch
COPY --from=builder /usr/local/bin/gm /
# sanity test binary
RUN ["/gm" ,"version"]
# test some format creation, convert and identify
RUN ["/gm" ,"convert", "xc:#000000", "input.png"]
RUN ["/gm" ,"convert", "input.png", "test_png.png"]
RUN ["/gm" ,"convert", "input.png", "test_png.jpg"]
RUN ["/gm" ,"convert", "input.png", "test_png.tiff"]
RUN ["/gm" ,"identify", "test_png.png"]
RUN ["/gm" ,"identify", "test_png.jpg"]
RUN ["/gm" ,"identify", "test_png.tiff"]

FROM scratch
COPY --from=builder /usr/local/bin/gm /
ENTRYPOINT ["/gm"]
