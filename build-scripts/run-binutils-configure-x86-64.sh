#!/bin/bash

here="`pwd`"
topdir="`dirname ${here}`"
srcdir="${topdir}/binutils-2.46.1"
target_platform="`uname -m`-linux-gnu"

prefix="/opt"
bindir="${prefix}/bin"
libdir="${prefix}/lib64"
libexecdir="${prefix}/libexec"
localstatedir="/var"

export CC="/usr/bin/gcc"
export CXX="/usr/bin/g++"
export CFLAGS="-g -O2 -std=gnu11 -fPIC"
export CXXFLAGS="-g -O2 -std=c++17 -fPIC"
export CPPFLAGS="-D_GNU_SOURCE -D_XOPEN_SOURCE=700"
export LDFLAGS="-Wl,--enable-new-dtags"

echo "chmod 0755 ${srcdir}/configure"
chmod 0755 ${srcdir}/configure

${srcdir}/configure \
  --prefix=${prefix} \
  --bindir=${bindir} \
  --libdir=${libdir} \
  --libexecdir=${libexecdir} \
  --localstatedir=${localstatedir} \
  --build=${target_platform} \
  --host=${target_platform} \
  --enable-ld \
  --enable-gold=default \
  --enable-shared \
  --enable-plugins \
  --enable-64-bit-bfd \
  --enable-default-hash-style=gnu \
  --enable-jansson=yes \
  --enable-host-pie \
  --enable-gprofng=no \
  --with-system-zlib=yes \
  --with-xxhash=yes \
  --with-zstd=yes \
  --enable-compressed-debug-sections=all \
  --enable-generate-build-notes=yes \
  --enable-relro=yes \
  --enable-deterministic-archives \
  --enable-warn-execstack=yes \
  --enable-warn-rwx-segments=no \
  --enable-lto \
  --enable-host-shared \
  --enable-new-dtags --disable-rpath \
  --enable-separate-code=yes \
  --enable-rosegment=yes \
  --enable-threads=yes \
  --enable-textrel-check=error \
  --enable-werror=no
