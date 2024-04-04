## static-gm

Image with graphicsmagick binary built as hardened static PIE binaries with no
external dependencies. Can be used with any base image even scratch.

Built with:
- ijg jpeg
- jasper (JPEG2000)
- lcms2
- libpng
- libtiff
- libwebp
- libjxl (JPEG XL)
- libheif (HEIF and AVIF decode only)
- quantum-depth=16,

### Usage
```Dockerfile
COPY --from=mwader/static-gm:1.3.43 /gm /usr/local/bin/
```
```sh
docker run --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-gm:1.3.43 identify test.png
```

### Files in the image
`/gm` graphicsmagick binary  
`/icc-profiles` ICC profiles  
`/delegates.mgk` Empty delegates configuration file that can be used to prevent graphicsmagick from failing due to missing delegates configuration

### Delegates configuration
If you're copying the binary to an image you might also want to copy `/delegates.mgk` and set then envinonment variable `MAGICK_CONFIGURE_PATH` to the directory where `delegates.mgk` can be found. This will prevent graphicsmagick from trying and failing to use an external delegate.

### Security
Binary is built with various hardening features but it's probably still a good idea to run
them as non-root even when used inside a container, especially so if running on input files
that you don't control.

Also see http://www.graphicsmagick.org/security.html and consider exporting
`MAGICK_CODER_STABILITY` to be `PRIMARY` or `STABLE`.
