# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.18.3 AS builder

RUN apk add --no-cache \
  coreutils \
  openssl \
  wget \
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

# retry dns and some http codes that might be transient errors
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503"

# bump: gm /GM_VERSION=([\d.]+)/ fetch:http://hg.code.sf.net/p/graphicsmagick/code/raw-file/GraphicsMagick-1_3/.hgtags|/.* GraphicsMagick-(\d+_\d+_\d+).*/|/_/./|^1
# bump: gm after ./hashupdate Dockerfile GM $LATEST
# bumo: gm link "NEWS" http://www.graphicsmagick.org/NEWS.html
ARG GM_VERSION=1.3.41
ARG GM_URL="https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick/$GM_VERSION/GraphicsMagick-$GM_VERSION.tar.xz/download"
ARG GM_SHA256=b741b11ba86162db4d4ec1b354989a773f73c40722d1148239f6c69c9f04a6aa
# bump: libpng /LIBPNG_VERSION=([\d.]+)/ https://github.com/glennrp/libpng.git|/^\d+.\d+.\d+/|~1
# bump: libpng after ./hashupdate Dockerfile LIBPNG $LATEST
# bump: libpng link "CHANGES" https://github.com/glennrp/libpng/blob/libpng16/CHANGES
# bump: libpng link "Source diff $CURRENT..$LATEST" https://github.com/glennrp/libpng/compare/v$CURRENT..v$LATEST
ARG LIBPNG_VERSION=1.6.40
ARG LIBPNG_URL="https://sourceforge.net/projects/libpng/files/libpng16/$LIBPNG_VERSION/libpng-$LIBPNG_VERSION.tar.gz/download"
ARG LIBPNG_SHA256=8f720b363aa08683c9bf2a563236f45313af2c55d542b5481ae17dd8d183bb42
# bump: jpeg /JPEG_VERSION=([\d.a-z]+)/ fetch:http://www.ijg.org|/The current version is release (.*) of/
# bump: jpeg after ./hashupdate Dockerfile JPEG $LATEST
ARG JPEG_VERSION=9e
ARG JPEG_URL="http://www.ijg.org/files/jpegsrc.v$JPEG_VERSION.tar.gz"
ARG JPEG_SHA256=4077d6a6a75aeb01884f708919d25934c93305e49f7e3f36db9129320e6f4f3d
# bump: jasper /JASPER_VERSION=([\d.]+)/ https://github.com/mdadams/jasper.git|^2
# bump: jasper after ./hashupdate Dockerfile JASPER $LATEST
# bump: jasper link "NEWS" https://github.com/jasper-software/jasper/blob/master/NEWS
# bump: jasper link "Source diff $CURRENT..$LATEST" https://github.com/jasper-software/jasper/compare/version-$CURRENT..version-$LATEST
ARG JASPER_VERSION=2.0.33
ARG JASPER_URL="https://github.com/mdadams/jasper/archive/version-$JASPER_VERSION.tar.gz"
ARG JASPER_SHA256=38b8f74565ee9e7fec44657e69adb5c9b2a966ca5947ced5717cde18a7d2eca6
# bump: libwebp /LIBWEBP_VERSION=([\d.]+)/ https://github.com/webmproject/libwebp.git|*
# bump: libwebp after ./hashupdate Dockerfile LIBWEBP $LATEST
# bump: libwebp link "Release notes" https://github.com/webmproject/libwebp/releases/tag/v$LATEST
# bump: libwebp link "Source diff $CURRENT..$LATEST" https://github.com/webmproject/libwebp/compare/v$CURRENT..v$LATEST
ARG LIBWEBP_VERSION=1.3.2
ARG LIBWEBP_URL="https://github.com/webmproject/libwebp/archive/v$LIBWEBP_VERSION.tar.gz"
ARG LIBWEBP_SHA256=c2c2f521fa468e3c5949ab698c2da410f5dce1c5e99f5ad9e70e0e8446b86505
# bump: libtiff /LIBTIFF_VERSION=([\d.]+)/ https://gitlab.com/libtiff/libtiff.git|^4
# bump: libtiff after ./hashupdate Dockerfile LIBTIFF $LATEST
# bump: libtiff link "ChangeLog" https://gitlab.com/libtiff/libtiff/-/blob/master/ChangeLog
ARG LIBTIFF_VERSION=4.6.0
ARG LIBTIFF_URL="http://download.osgeo.org/libtiff/tiff-$LIBTIFF_VERSION.tar.gz"
ARG LIBTIFF_SHA256=88b3979e6d5c7e32b50d7ec72fb15af724f6ab2cbf7e10880c360a77e4b5d99a
# bump: lcms2 /LCMS2_VERSION=([\d.]+)/ https://github.com/mm2/Little-CMS.git|^2
# bump: lcms2 after ./hashupdate Dockerfile LCMS2 $LATEST
# bump: lcms2 link "Release" https://github.com/mm2/Little-CMS/releases/tag/lcms$LATEST
ARG LCMS2_VERSION=2.15
ARG LCMS2_URL="https://github.com/mm2/Little-CMS/releases/download/lcms$LCMS2_VERSION/lcms2-$LCMS2_VERSION.tar.gz"
ARG LCMS2_SHA256=b20cbcbd0f503433be2a4e81462106fa61050a35074dc24a4e356792d971ab39

ARG CFLAGS="-O3 -fno-strict-overflow -fstack-protector-all -fPIE"
ARG CXXFLAGS="-O3 -fno-strict-overflow -fstack-protector-all -fPIE"
ARG LDFLAGS="-Wl,-z,relro -Wl,-z,now -fPIE -pie"

RUN \
  wget $WGET_OPTS -O libpng.tar.gz "$LIBPNG_URL" && \
  echo "$LIBPNG_SHA256  libpng.tar.gz" | sha256sum --status -c - && \
  tar xfz libpng.tar.gz && \
  cd libpng-* && \
  ./configure \
  --enable-static \
  --disable-shared \
  && \
  make -j$(nproc) install

RUN \
  wget $WGET_OPTS -O jpeg.tar.gz "$JPEG_URL" && \
  echo "$JPEG_SHA256  jpeg.tar.gz" | sha256sum --status -c - && \
  tar xfz jpeg.tar.gz && \
  cd jpeg-* && \
  ./configure \
  --enable-static \
  --disable-shared \
  && \
  make -j$(nproc) install

RUN \
  wget $WGET_OPTS -O jasper.tar.gz "$JASPER_URL" && \
  echo "$JASPER_SHA256  jasper.tar.gz" | sha256sum --status -c - && \
  tar xfz jasper.tar.gz && \
  cd jasper-* && \
  mkdir tmp && \
  cd tmp && \
  cmake -G "Unix Makefiles" -DJAS_ENABLE_SHARED=OFF -H.. -B. && \
  make -j$(nproc) install

RUN \
  wget $WGET_OPTS -O libwebp.tar.gz "$LIBWEBP_URL" && \
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
  wget $WGET_OPTS -O tiff.tar.gz "$LIBTIFF_URL" && \
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
  wget $WGET_OPTS -O lcms2.tar.gz "$LCMS2_URL" && \
  echo "$LCMS2_SHA256  lcms2.tar.gz" | sha256sum --status -c - && \
  tar xfz lcms2.tar.gz && \
  cd lcms2-* && \
  ./autogen.sh && \
  ./configure \
  --enable-static \
  --disable-shared \
  && \
  make -j$(nproc) install

RUN \
  wget $WGET_OPTS -O gm.tar.gz "$GM_URL" && \
  echo "$GM_SHA256  gm.tar.gz" | sha256sum --status -c - && \
  tar xf gm.tar.gz && \
  cd GraphicsMagick-* && \
  LDFLAGS="-static-pie" CFLAGS="-fPIE" ./configure \
  --enable-static \
  --disable-shared \
  --disable-dependency-tracking \
  --with-quantum-depth=16 \
  --with-png \
  --with-jpeg \
  --with-jp2 \
  --with-webp \
  --with-tiff \
  --with-lcms2 \
  --with-webp \
  && \
  make -j$(nproc) install

# make sure binaries has no dependencies, is relro, pie and stack nx
COPY checkelf /
RUN /checkelf /usr/local/bin/gm

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
COPY icc-profiles /icc-profiles
ENTRYPOINT ["/gm"]
