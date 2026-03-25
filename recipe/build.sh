#!/bin/bash
set -ex

# conda-build extracts the RPM automatically into SRC_DIR
# It strips the top-level "usr/" directory, so files are at local/...

mkdir -p $PREFIX/bin
mkdir -p $PREFIX/include
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/share/man/man1/

mv local/bin/* $PREFIX/bin/
mv local/include/wkhtmltox/ $PREFIX/include/
mv local/lib/* $PREFIX/lib/
mv local/share/man/man1/* $PREFIX/share/man/man1/
