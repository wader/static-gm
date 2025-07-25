# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.22.1 AS builder

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

# -static-libgcc is needed to make gcc not include gcc_s as "as-needed" shared library which
# cmake will include as a implicit library.
ARG CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIC"
ARG CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIC"
ARG LDFLAGS="-Wl,-z,relro -Wl,-z,now"

# bump: libpng /LIBPNG_VERSION=([\d.]+)/ https://github.com/glennrp/libpng.git|/^\d+.\d+.\d+/|~1
# bump: libpng after ./hashupdate Dockerfile LIBPNG $LATEST
# bump: libpng link "CHANGES" https://github.com/glennrp/libpng/blob/libpng16/CHANGES
# bump: libpng link "Source diff $CURRENT..$LATEST" https://github.com/glennrp/libpng/compare/v$CURRENT..v$LATEST
ARG LIBPNG_VERSION=1.6.49
ARG LIBPNG_URL="https://sourceforge.net/projects/libpng/files/libpng16/$LIBPNG_VERSION/libpng-$LIBPNG_VERSION.tar.gz/download"
ARG LIBPNG_SHA256=d173dada6181ef1638bcdb9526dd46a0f5eee08e3be9615e628ae54f888f17f9
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
ARG LIBWEBP_VERSION=1.4.0
ARG LIBWEBP_URL="https://github.com/webmproject/libwebp/archive/v$LIBWEBP_VERSION.tar.gz"
ARG LIBWEBP_SHA256=12af50c45530f0a292d39a88d952637e43fb2d4ab1883c44ae729840f7273381
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
ARG LIBTIFF_VERSION=4.7.0
ARG LIBTIFF_URL="http://download.osgeo.org/libtiff/tiff-$LIBTIFF_VERSION.tar.gz"
ARG LIBTIFF_SHA256=67160e3457365ab96c5b3286a0903aa6e78bdc44c4bc737d2e486bcecb6ba976
RUN wget $WGET_OPTS -O tiff.tar.gz "$LIBTIFF_URL"
RUN echo "$LIBTIFF_SHA256  tiff.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS tiff.tar.gz && \
  cd tiff-* && \
  ./configure \
  --enable-static \
  --disable-shared \
  --disable-webp \
  && \
  make -j$(nproc) install

# bump: lcms2 /LCMS2_VERSION=([\d.]+)/ https://github.com/mm2/Little-CMS.git|^2
# bump: lcms2 after ./hashupdate Dockerfile LCMS2 $LATEST
# bump: lcms2 link "Release" https://github.com/mm2/Little-CMS/releases/tag/lcms$LATEST
ARG LCMS2_VERSION=2.17
ARG LCMS2_URL="https://github.com/mm2/Little-CMS/releases/download/lcms$LCMS2_VERSION/lcms2-$LCMS2_VERSION.tar.gz"
ARG LCMS2_SHA256=d11af569e42a1baa1650d20ad61d12e41af4fead4aa7964a01f93b08b53ab074
RUN wget $WGET_OPTS -O lcms2.tar.gz "$LCMS2_URL"
RUN echo "$LCMS2_SHA256  lcms2.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS lcms2.tar.gz && \
  cd lcms2-* && \
  ./configure \
  --enable-static \
  --disable-shared \
  && \
  make -j$(nproc) install

# bump: libjxl /LIBJXL_VERSION=([\d.]+)/ https://github.com/libjxl/libjxl.git|^0
# bump: libjxl after ./hashupdate Dockerfile LIBJXL $LATEST
# bump: libjxl link "Changelog" https://github.com/libjxl/libjxl/blob/main/CHANGELOG.md
# use bundled highway library as its static build is not available in alpine
ARG LIBJXL_VERSION=0.11.1
ARG LIBJXL_URL="https://github.com/libjxl/libjxl/archive/refs/tags/v${LIBJXL_VERSION}.tar.gz"
ARG LIBJXL_SHA256=1492dfef8dd6c3036446ac3b340005d92ab92f7d48ee3271b5dac1d36945d3d9
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
    -DJPEGXL_ENABLE_TOOLS=OFF \
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

# bump: libde265 /LIBDE265_VERSION=([\d.a-z]+)/ https://github.com/strukturag/libde265.git|^1
# bump: libde265 after ./hashupdate Dockerfile LIBDE265 $LATEST
ARG LIBDE265_VERSION=1.0.16
ARG LIBDE265_URL="https://github.com/strukturag/libde265/releases/download/v$LIBDE265_VERSION/libde265-$LIBDE265_VERSION.tar.gz"
ARG LIBDE265_SHA256=b92beb6b53c346db9a8fae968d686ab706240099cdd5aff87777362d668b0de7
RUN wget $WGET_OPTS -O libde265.tar.gz "$LIBDE265_URL"
RUN echo "$LIBDE265_SHA256  libde265.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libde265.tar.gz && \
  cd libde265-* && \
  ./configure \
  --enable-static \
  --disable-shared \
  --disable-sherlock265 \
  && \
  make -j$(nproc) install
# hack for https://github.com/strukturag/libde265/pull/439
RUN sed -i 's/@LIBS_PRIVATE@/-lstdc++ /' /usr/local/lib/pkgconfig/libde265.pc

# bump: x265 /X265_VERSION=([\d.]+)/ https://bitbucket.org/multicoreware/x265_git.git|*
# bump: x265 after ./hashupdate Dockerfile X265 $LATEST
# bump: x265 link "Source diff $CURRENT..$LATEST" https://bitbucket.org/multicoreware/x265_git/branches/compare/$LATEST..$CURRENT#diff
ARG X265_VERSION=4.1
ARG X265_SHA256=a31699c6a89806b74b0151e5e6a7df65de4b49050482fe5ebf8a4379d7af8f29
ARG X265_URL="https://bitbucket.org/multicoreware/x265_git/downloads/x265_$X265_VERSION.tar.gz"
# CMAKEFLAGS issue
# https://bitbucket.org/multicoreware/x265_git/issues/620/support-passing-cmake-flags-to-multilibsh
RUN \
  wget $WGET_OPTS -O x265_git.tar.bz2 "$X265_URL" && \
  echo "$X265_SHA256  x265_git.tar.bz2" | sha256sum -c - && \
  tar $TAR_OPTS x265_git.tar.bz2 && cd x265_*/build/linux && \
  sed -i '/^cmake / s/$/ -G "Unix Makefiles" ${CMAKEFLAGS}/' ./multilib.sh && \
  sed -i 's/ -DENABLE_SHARED=OFF//g' ./multilib.sh && \
  MAKEFLAGS="-j$(nproc)" \
  CMAKEFLAGS="-DENABLE_SHARED=OFF -DCMAKE_VERBOSE_MAKEFILE=ON -DENABLE_AGGRESSIVE_CHECKS=ON -DENABLE_NASM=ON -DCMAKE_BUILD_TYPE=Release" \
  ./multilib.sh && \
  make -C 8bit -j$(nproc) install

# bump: aom /AOM_VERSION=([\d.]+)/ git:https://aomedia.googlesource.com/aom|*
# bump: aom after ./hashupdate Dockerfile AOM $LATEST
# bump: aom after COMMIT=$(git ls-remote https://aomedia.googlesource.com/aom v$LATEST^{} | awk '{print $1}') && sed -i -E "s/^ARG AOM_COMMIT=.*/ARG AOM_COMMIT=$COMMIT/" Dockerfile
# bump: aom link "CHANGELOG" https://aomedia.googlesource.com/aom/+/refs/tags/v$LATEST/CHANGELOG
ARG AOM_VERSION=3.12.1
ARG AOM_URL="https://aomedia.googlesource.com/aom"
ARG AOM_COMMIT=10aece4157eb79315da205f39e19bf6ab3ee30d0
RUN git clone --depth 1 --branch v$AOM_VERSION "$AOM_URL"
RUN cd aom && test $(git rev-parse HEAD) = $AOM_COMMIT
RUN \
  cd aom && \
  mkdir build_tmp && cd build_tmp && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_EXAMPLES=NO \
    -DENABLE_DOCS=NO \
    -DENABLE_TESTS=NO \
    -DENABLE_TOOLS=NO \
    -DENABLE_NASM=ON \
    -DCMAKE_INSTALL_LIBDIR=lib \
    .. && \
  make -j$(nproc) install

# bump: libheif /LIBHEIF_VERSION=([\d.]+)/ https://github.com/strukturag/libheif.git|^1 
# bump: libheif after ./hashupdate Dockerfile LIBHEIF $LATEST
# bumo: libheif link "NEWS" http://www.graphicsmagick.org/NEWS.html
ARG LIBHEIF_VERSION=1.20.1
ARG LIBHEIF_URL="https://github.com/strukturag/libheif/releases/download/v$LIBHEIF_VERSION/libheif-$LIBHEIF_VERSION.tar.gz"
ARG LIBHEIF_SHA256=55cc76b77c533151fc78ba58ef5ad18562e84da403ed749c3ae017abaf1e2090
RUN wget $WGET_OPTS -O libheif.tar.gz "$LIBHEIF_URL"
RUN echo "$LIBHEIF_SHA256  libheif.tar.gz" | sha256sum --status -c -
RUN \
  tar xf libheif.tar.gz && \
  cd libheif-* && \
  cmake \
    -G "Unix Makefiles" \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_GDK_PIXBUF=NO \
    -DWITH_EXAMPLES=OFF \
    --preset=release-noplugins \
  && \
  make -j$(nproc) install

# bump: gm /GM_VERSION=([\d.]+)/ fetch:http://hg.code.sf.net/p/graphicsmagick/code/raw-file/GraphicsMagick-1_3/.hgtags|/.* GraphicsMagick-(\d+_\d+_\d+).*/|/_/./|^1
# bump: gm after ./hashupdate Dockerfile GM $LATEST
# bumo: gm link "NEWS" http://www.graphicsmagick.org/NEWS.html
ARG GM_VERSION=1.3.45
ARG GM_URL="https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick/$GM_VERSION/GraphicsMagick-$GM_VERSION.tar.xz/download"
ARG GM_SHA256=dcea5167414f7c805557de2d7a47a9b3147bcbf617b91f5f0f4afe5e6543026b
RUN wget $WGET_OPTS -O gm.tar.gz "$GM_URL"
RUN echo "$GM_SHA256  gm.tar.gz" | sha256sum --status -c -
RUN \
  tar xf gm.tar.gz && \
  cd GraphicsMagick-* && \
  LDFLAGS="-static-pie" CFLAGS="-fPIE" \
  LIBJXL_CFLAGS="$(pkg-config --cflags libjxl)" \
  LIBJXL_LIBS="$(pkg-config --libs --static libjxl)" \
  HEIF_CFLAGS="$(pkg-config --cflags libheif)" \
  HEIF_LIBS="$(pkg-config --libs --static libheif)" \
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
  --with-heif \
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
# TODO: gm heif and avif support is decode only as of writing
#RUN ["/usr/local/bin/gm" ,"convert", "input.png", "test_png.heif"]
#RUN ["/usr/local/bin/gm" ,"convert", "input.png", "test_png.avif"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.png"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.jpg"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.tiff"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.webp"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.lossless.webp"]
RUN ["/usr/local/bin/gm" ,"identify", "test_png.jxl"]
#RUN ["/usr/local/bin/gm" ,"identify", "test_png.heif"]
#RUN ["/usr/local/bin/gm" ,"identify", "test_png.avif"]

FROM scratch
COPY icc-profiles /icc-profiles
COPY delegates.mgk /
COPY --from=builder /usr/local/bin/gm /
# point to empty delegates.mgk to prevent confusing missing delegates error
ENV MAGICK_CONFIGURE_PATH=/
# sanity test binary
RUN ["/gm" ,"version"]
ENTRYPOINT ["/gm"]
