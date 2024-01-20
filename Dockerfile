# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.19.1 AS builder

RUN apk add --no-cache \
  coreutils \
  openssl \
  wget \
  curl \
  tar \
  xz \
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
  zlib-static \
  brotli-dev brotli-static

# retry dns and some http codes that might be transient errors
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503"
# --no-same-owner as we don't care about uid/gid even if we run as root. fixes invalid gid/uid issue.
ARG TAR_OPTS="--no-same-owner --extract --file"

ARG CFLAGS="-O3 -fno-strict-overflow -fstack-protector-all -fPIC"
ARG CXXFLAGS="-O3 -fno-strict-overflow -fstack-protector-all -fPIC"
ARG LDFLAGS="-Wl,-z,relro -Wl,-z,now"

# bump: libpng /LIBPNG_VERSION=([\d.]+)/ https://github.com/glennrp/libpng.git|/^\d+.\d+.\d+/|~1
# bump: libpng after ./hashupdate Dockerfile LIBPNG $LATEST
# bump: libpng link "CHANGES" https://github.com/glennrp/libpng/blob/libpng16/CHANGES
# bump: libpng link "Source diff $CURRENT..$LATEST" https://github.com/glennrp/libpng/compare/v$CURRENT..v$LATEST
ARG LIBPNG_VERSION=1.6.43
ARG LIBPNG_URL="https://sourceforge.net/projects/libpng/files/libpng16/$LIBPNG_VERSION/libpng-$LIBPNG_VERSION.tar.gz/download"
ARG LIBPNG_SHA256=e804e465d4b109b5ad285a8fb71f0dd3f74f0068f91ce3cdfde618180c174925
RUN wget $WGET_OPTS -O libpng.tar.gz "$LIBPNG_URL"
RUN echo "$LIBPNG_SHA256  libpng.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libpng.tar.gz && \
  cd libpng-* && \
  ./configure \
  --enable-static \
  --disable-shared \
  && \
  make -j$(nproc) install

# bump: jpeg /JPEG_VERSION=([\d.a-z]+)/ fetch:http://www.ijg.org|/The current version is release (.*) of/
# bump: jpeg after ./hashupdate Dockerfile JPEG $LATEST
ARG JPEG_VERSION=9f
ARG JPEG_URL="http://www.ijg.org/files/jpegsrc.v$JPEG_VERSION.tar.gz"
ARG JPEG_SHA256=04705c110cb2469caa79fb71fba3d7bf834914706e9641a4589485c1f832565b
RUN wget $WGET_OPTS -O jpeg.tar.gz "$JPEG_URL"
RUN echo "$JPEG_SHA256  jpeg.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS jpeg.tar.gz && \
  cd jpeg-* && \
  ./configure \
  --enable-static \
  --disable-shared \
  && \
  make -j$(nproc) install

# bump: jasper /JASPER_VERSION=([\d.]+)/ https://github.com/mdadams/jasper.git|^2
# bump: jasper after ./hashupdate Dockerfile JASPER $LATEST
# bump: jasper link "NEWS" https://github.com/jasper-software/jasper/blob/master/NEWS
# bump: jasper link "Source diff $CURRENT..$LATEST" https://github.com/jasper-software/jasper/compare/version-$CURRENT..version-$LATEST
ARG JASPER_VERSION=2.0.33
ARG JASPER_URL="https://github.com/mdadams/jasper/archive/version-$JASPER_VERSION.tar.gz"
ARG JASPER_SHA256=38b8f74565ee9e7fec44657e69adb5c9b2a966ca5947ced5717cde18a7d2eca6
RUN wget $WGET_OPTS -O jasper.tar.gz "$JASPER_URL"
RUN echo "$JASPER_SHA256  jasper.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS jasper.tar.gz && \
  cd jasper-* && \
  mkdir tmp && \
  cd tmp && \
  cmake -G "Unix Makefiles" -DJAS_ENABLE_SHARED=OFF -H.. -B. && \
  make -j$(nproc) install

# bump: libwebp /LIBWEBP_VERSION=([\d.]+)/ https://github.com/webmproject/libwebp.git|*
# bump: libwebp after ./hashupdate Dockerfile LIBWEBP $LATEST
# bump: libwebp link "Release notes" https://github.com/webmproject/libwebp/releases/tag/v$LATEST
# bump: libwebp link "Source diff $CURRENT..$LATEST" https://github.com/webmproject/libwebp/compare/v$CURRENT..v$LATEST
ARG LIBWEBP_VERSION=1.3.2
ARG LIBWEBP_URL="https://github.com/webmproject/libwebp/archive/v$LIBWEBP_VERSION.tar.gz"
ARG LIBWEBP_SHA256=c2c2f521fa468e3c5949ab698c2da410f5dce1c5e99f5ad9e70e0e8446b86505
RUN wget $WGET_OPTS -O libwebp.tar.gz "$LIBWEBP_URL"
RUN echo "$LIBWEBP_SHA256  libwebp.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libwebp.tar.gz && \
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

# bump: libtiff /LIBTIFF_VERSION=([\d.]+)/ https://gitlab.com/libtiff/libtiff.git|^4
# bump: libtiff after ./hashupdate Dockerfile LIBTIFF $LATEST
# bump: libtiff link "ChangeLog" https://gitlab.com/libtiff/libtiff/-/blob/master/ChangeLog
ARG LIBTIFF_VERSION=4.6.0
ARG LIBTIFF_URL="http://download.osgeo.org/libtiff/tiff-$LIBTIFF_VERSION.tar.gz"
ARG LIBTIFF_SHA256=88b3979e6d5c7e32b50d7ec72fb15af724f6ab2cbf7e10880c360a77e4b5d99a
RUN wget $WGET_OPTS -O tiff.tar.gz "$LIBTIFF_URL"
RUN echo "$LIBTIFF_SHA256  tiff.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS tiff.tar.gz && \
  cd tiff-* && \
  ./autogen.sh && \
  ./configure \
  --enable-static \
  --disable-shared \
  --disable-webp \
  && \
  make -j$(nproc) install

# bump: lcms2 /LCMS2_VERSION=([\d.]+)/ https://github.com/mm2/Little-CMS.git|^2
# bump: lcms2 after ./hashupdate Dockerfile LCMS2 $LATEST
# bump: lcms2 link "Release" https://github.com/mm2/Little-CMS/releases/tag/lcms$LATEST
ARG LCMS2_VERSION=2.16
ARG LCMS2_URL="https://github.com/mm2/Little-CMS/releases/download/lcms$LCMS2_VERSION/lcms2-$LCMS2_VERSION.tar.gz"
ARG LCMS2_SHA256=d873d34ad8b9b4cea010631f1a6228d2087475e4dc5e763eb81acc23d9d45a51
RUN wget $WGET_OPTS -O lcms2.tar.gz "$LCMS2_URL"
RUN echo "$LCMS2_SHA256  lcms2.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS lcms2.tar.gz && \
  cd lcms2-* && \
  ./autogen.sh && \
  ./configure \
  --enable-static \
  --disable-shared \
  && \
  make -j$(nproc) install

# bump: libjxl /LIBJXL_VERSION=([\d.]+)/ https://github.com/libjxl/libjxl.git|^0
# bump: libjxl after ./hashupdate Dockerfile LIBJXL $LATEST
# bump: libjxl link "Changelog" https://github.com/libjxl/libjxl/blob/main/CHANGELOG.md
# use bundled highway library as its static build is not available in alpine
ARG LIBJXL_VERSION=0.10.2
ARG LIBJXL_URL="https://github.com/libjxl/libjxl/archive/refs/tags/v${LIBJXL_VERSION}.tar.gz"
ARG LIBJXL_SHA256=95e807f63143856dc4d161c071cca01115d2c6405b3d3209854ac6989dc6bb91
RUN wget $WGET_OPTS -O libjxl.tar.gz "$LIBJXL_URL"
RUN echo "$LIBJXL_SHA256  libjxl.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libjxl.tar.gz && \
  cd libjxl-* && \
  sed -i 's/params.optimize_coding;/(boolean)params.optimize_coding;/' lib/extras/enc/jpg.cc && \
  sed -i 's/dparams->two_pass_quant;/(boolean)dparams->two_pass_quant;/' lib/extras/dec/jpg.cc && \
  ./deps.sh && \
  cmake -B build \
    -G"Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTING=OFF \
    -DJPEGXL_ENABLE_PLUGINS=OFF \
    -DJPEGXL_ENABLE_BENCHMARK=OFF \
    -DJPEGXL_ENABLE_COVERAGE=OFF \
    -DJPEGXL_ENABLE_EXAMPLES=OFF \
    -DJPEGXL_ENABLE_FUZZERS=OFF \
    -DJPEGXL_ENABLE_SJPEG=OFF \
    -DJPEGXL_ENABLE_SKCMS=OFF \
    -DJPEGXL_ENABLE_VIEWERS=OFF \
    -DJPEGXL_FORCE_SYSTEM_GTEST=ON \
    -DJPEGXL_FORCE_SYSTEM_BROTLI=ON \
    -DJPEGXL_FORCE_SYSTEM_HWY=OFF && \
  cmake --build build -j$(nproc) && \
  cmake --install build
RUN sed -i 's/-ljxl/-ljxl -lstdc++ /' /usr/local/lib/pkgconfig/libjxl.pc
RUN sed -i 's/-ljxl_cms/-ljxl_cms -lstdc++ /' /usr/local/lib/pkgconfig/libjxl_cms.pc
RUN sed -i 's/-ljxl_threads/-ljxl_threads -lstdc++ /' /usr/local/lib/pkgconfig/libjxl_threads.pc

# bump: gm /GM_VERSION=([\d.]+)/ fetch:http://hg.code.sf.net/p/graphicsmagick/code/raw-file/GraphicsMagick-1_3/.hgtags|/.* GraphicsMagick-(\d+_\d+_\d+).*/|/_/./|^1
# bump: gm after ./hashupdate Dockerfile GM $LATEST
# bumo: gm link "NEWS" http://www.graphicsmagick.org/NEWS.html
ARG GM_VERSION=1.3.43
ARG GM_URL="https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick/$GM_VERSION/GraphicsMagick-$GM_VERSION.tar.xz/download"
ARG GM_SHA256=2b88580732cd7e409d9e22c6116238bef4ae06fcda11451bf33d259f9cbf399f
RUN wget $WGET_OPTS -O gm.tar.gz "$GM_URL"
RUN echo "$GM_SHA256  gm.tar.gz" | sha256sum --status -c -
RUN \
  tar xf gm.tar.gz && \
  cd GraphicsMagick-* && \
  LDFLAGS="-static-pie" CFLAGS="-fPIE" \
  LIBJXL_CFLAGS="$(pkg-config --cflags libjxl)" \
  LIBJXL_LIBS="$(pkg-config --libs --static libjxl)" \
  ./configure \
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
  --with-jxl \
  && \
  make -j$(nproc) install

# make sure binaries has no dependencies, is relro, pie and stack nx
COPY checkelf /
RUN /checkelf /usr/local/bin/gm

# test some format creation, convert and identify
RUN ["/usr/local/bin/gm" ,"convert", "xc:#000000", "input.png"]
RUN ["/usr/local/bin/gm" ,"convert", "input.png", "test_png.png"]
RUN ["/usr/local/bin/gm" ,"convert", "input.png", "test_png.jpg"]
RUN ["/usr/local/bin/gm" ,"convert", "input.png", "test_png.tiff"]
RUN ["/usr/local/bin/gm" ,"convert", "input.png", "test_png.webp"]
RUN ["/usr/local/bin/gm" ,"convert", "input.png", "-define", "webp:lossless=true", "test_png.lossless.webp"]
RUN ["/usr/local/bin/gm" ,"convert", "input.png", "test_png.jxl"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.png"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.jpg"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.tiff"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.webp"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.lossless.webp"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.jxl"]

FROM scratch
COPY icc-profiles /icc-profiles
COPY --from=builder /usr/local/bin/gm /
# sanity test binary
RUN ["/gm" ,"version"]
ENTRYPOINT ["/gm"]
