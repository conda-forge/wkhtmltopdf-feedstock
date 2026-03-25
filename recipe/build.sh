#!/bin/bash
set -ex

# Extract the RPM using bsdtar (from libarchive)
bsdtar -xf *.rpm

mkdir -p $PREFIX/bin
mkdir -p $PREFIX/include
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/share/man/man1/

mv usr/local/bin/* $PREFIX/bin/
mv usr/local/include/wkhtmltox/ $PREFIX/include/
mv usr/local/lib/* $PREFIX/lib/
mv usr/local/share/man/man1/* $PREFIX/share/man/man1/
