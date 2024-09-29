#!/usr/bin/env bash
docker run --mount type=bind,source=.,target=/src --pull always --platform linux/amd64 -it ghcr.io/stephtr/libqalculate-wasm:main emcc -I /opt/include -L /opt/lib -lqalculate -lgmp -lmpfr -lxml2 --bind /src/src/libqalculate.cc -o /src/src/libqalculate.js -O2 -s MODULARIZE -s ENVIRONMENT=web -s FILESYSTEM=0 -s ERROR_ON_UNDEFINED_SYMBOLS=0 --closure 1
