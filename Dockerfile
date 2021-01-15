# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.13.0 AS builder

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
# bump: gm after ./hashupdate Dockerfile GM $LATEST
# bumo: gm link "NEWS" http://www.graphicsmagick.org/NEWS.html
ARG GM_VERSION=1.3.36
ARG GM_URL="https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick/$GM_VERSION/GraphicsMagick-$GM_VERSION.tar.gz/download"
ARG GM_SHA256=1e6723c48c4abbb31197fadf8396b2d579d97e197123edc70a4f057f0533d563
# bump: libpng /LIBPNG_VERSION=([\d.]+)/ https://github.com/glennrp/libpng.git|/^\d+.\d+.\d+/|~1
# bump: libpng after ./hashupdate Dockerfile LIBPNG $LATEST
# bump: libpng link "CHANGES" https://github.com/glennrp/libpng/blob/libpng16/CHANGES
# bump: libpng link "Source diff $CURRENT..$LATEST" https://github.com/glennrp/libpng/compare/v$CURRENT..v$LATEST
ARG LIBPNG_VERSION=1.6.37
ARG LIBPNG_URL="https://sourceforge.net/projects/libpng/files/libpng16/$LIBPNG_VERSION/libpng-$LIBPNG_VERSION.tar.gz/download"
ARG LIBPNG_SHA256=daeb2620d829575513e35fecc83f0d3791a620b9b93d800b763542ece9390fb4
# bump: jpeg /JPEG_VERSION=([\d.a-z]+)/ fetch:http://www.ijg.org|/The current version is release (.*) of/
# bump: jpeg after ./hashupdate Dockerfile JPEG $LATEST
ARG JPEG_VERSION=9d
ARG JPEG_URL="http://www.ijg.org/files/jpegsrc.v$JPEG_VERSION.tar.gz"
ARG JPEG_SHA256=6c434a3be59f8f62425b2e3c077e785c9ce30ee5874ea1c270e843f273ba71ee
# bump: jasper /JASPER_VERSION=([\d.]+)/ https://github.com/mdadams/jasper.git|^2
# bump: jasper after ./hashupdate Dockerfile JASPER $LATEST
# bump: jasper link "NEWS" https://github.com/jasper-software/jasper/blob/master/NEWS
# bump: jasper link "Source diff $CURRENT..$LATEST" https://github.com/jasper-software/jasper/compare/version-$CURRENT..version-$LATEST
ARG JASPER_VERSION=2.0.24
ARG JASPER_URL="https://github.com/mdadams/jasper/archive/version-$JASPER_VERSION.tar.gz"
ARG JASPER_SHA256=d2d28e115968d38499163cf8086179503668ce0d71b90dd33855b3de96a1ca1d
# bump: libwebp /LIBWEBP_VERSION=([\d.]+)/ https://github.com/webmproject/libwebp.git|*
# bump: libwebp after ./hashupdate Dockerfile LIBWEBP $LATEST
# bump: libwebp link "Release notes" https://github.com/webmproject/libwebp/releases/tag/v$LATEST
# bump: libwebp link "Source diff $CURRENT..$LATEST" https://github.com/webmproject/libwebp/compare/v$CURRENT..v$LATEST
ARG LIBWEBP_VERSION=1.1.0
ARG LIBWEBP_URL="https://github.com/webmproject/libwebp/archive/v$LIBWEBP_VERSION.tar.gz"
ARG LIBWEBP_SHA256=424faab60a14cb92c2a062733b6977b4cc1e875a6398887c5911b3a1a6c56c51
# bump: libtiff /LIBTIFF_VERSION=([\d.]+)/ https://gitlab.com/libtiff/libtiff.git|^4
# bump: libtiff after ./hashupdate Dockerfile LIBTIFF $LATEST
# bump: libtiff link "ChangeLog" https://gitlab.com/libtiff/libtiff/-/blob/master/ChangeLog
ARG LIBTIFF_VERSION=4.2.0
ARG LIBTIFF_URL="http://download.osgeo.org/libtiff/tiff-$LIBTIFF_VERSION.tar.gz"
ARG LIBTIFF_SHA256=eb0484e568ead8fa23b513e9b0041df7e327f4ee2d22db5a533929dfc19633cb

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
  wget -O tiff.tar.gz "$LIBTIFF_URL" && \
  echo "$LIBTIFF_SHA256  tiff.tar.gz" | sha256sum --status -c - && \
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

# make sure binary is static
RUN file ldd /usr/local/bin/gm | grep "statically linked"

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
