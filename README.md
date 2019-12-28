## static-gm

Image with graphicsmagick binary built as hardened static PIE binaries with no
external dependencies. Can be used with any base image even scratch.

Built with quantum-depth=16,
libpng,
ijg jpeg,
jasper,
libwebp and
libtiff

### Usage
```Dockerfile
COPY --from=mwader/static-gm:1.3.34 /gm /usr/local/bin/
```
```sh
docker run --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-gm:1.3.34 identify test.png
```

### Files in the image
`/gm` graphicsmagick binary  

### Security

Binary is built with various hardening features but it's probably still a good idea to run
them as non-root even when used inside a container, especially so if running on input files
that you don't control.

Also see http://www.graphicsmagick.org/security.html and consider exporting
`MAGICK_CODER_STABILITY` to be `PRIMARY` or `STABLE`.
