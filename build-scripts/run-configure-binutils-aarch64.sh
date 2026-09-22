#!/bin/bash

here="`pwd`"
topdir="`dirname ${here}`"
srcdir="${topdir}/binutils-2.46.1"
host_platform="x86_64-linux-gnu"
target_platform="aarch64-linux-gnu"

prefix="/opt/aarch64/gnu-toolchain"
bindir="${prefix}/bin"
libdir="${prefix}/lib"
libexecdir="${prefix}/libexec"
localstatedir="/var"
cross_toolchain="/opt/aarch64"
sysroot="${cross_toolchain}/aarch64-buildroot-linux-gnu/sysroot/"

export CC="${cross_toolchain}/bin/aarch64-linux-gcc"
export CXX="${cross_toolchain}/bin/aarch64-linux-g++"
export LD="${cross_toolchain}/bin/aarch64-linux-ld.bfd"
export AR="${cross_toolchain}/bin/aarch64-linux-ar"
export NM="${cross_toolchain}/bin/aarch64-linux-nm"
export OBJCOPY="${cross_toolchain}/bin/aarch64-linux-objcopy"
export OBJDUMP="${cross_toolchain}/bin/aarch64-linux-obdump"
export RANLIB="${cross_toolchain}/bin/aarch64-linux-ranlib"
export READELF="${cross_toolchain}/bin/aarch64-linux-readelf"
export AS="${CC}"
export CC_FOR_TARGET=${CC}
export CXX_FOR_TARGET=${CXX}
export GCC_FOR_TARGET=${CC}
export AR_FOR_TARGET=${AR}
export AS_FOR_TARGET=${AS}
export LD_FOR_TARGET=${LD}
export NM_FOR_TARGET=${NM}
export OBJCOPY_FOR_TARGET=${OBJCOPY}
export OBJDUMP_FOR_TARGET=${OBJDUMP}
export RANLIB_FOR_TARGET=${RANLIB}
export READELF_FOR_TARGET=${READELF}
export CFLAGS="-g -O2 -std=gnu11 -fPIC -I${cross_toolchain}/include"
export CXXFLAGS="-g -O2 -std=c++17 -fPIC -I${cross_toolchain}/include"
export CPPFLAGS="-D_GNU_SOURCE -D_XOPEN_SOURCE=700"
export LDFLAGS="-Wl,--enable-new-dtags -Wl,-L -Wl,${cross_toolchain}/lib"
export LDFLAGS="${LDFLAGS} -Wl,-rpath -Wl,${cross_toolchain}/lib"
export MAKE="/usr/bin/gmake"
export PATH="${cross_toolchain}/bin:${PATH}"
export PKG_CONFIG_PATH="${cross_toolchain}/lib/pkgconfig:${PKG_CONFIG_PATH}"

echo "chmod 0755 ${srcdir}/configure"
chmod 0755 ${srcdir}/configure

${srcdir}/configure \
  --prefix=${prefix} \
  --bindir=${bindir} \
  --libdir=${libdir} \
  --libexecdir=${libexecdir} \
  --localstatedir=${localstatedir} \
  --host=${host_platform} \
  --target=${target_platform} \
  --with-sysroot=${sysroot} \
  --with-build-sysroot=${sysroot} \
  --enable-ld=default \
  --enable-gold=yes \
  --enable-shared \
  --enable-plugins \
  --enable-64-bit-bfd \
  --enable-default-hash-style=gnu \
  --enable-jansson=no \
  --enable-host-pie \
  --enable-gprofng=no \
  --with-system-zlib=yes \
  --with-xxhash=no \
  --with-zstd=no \
  --enable-compressed-debug-sections=zlib \
  --enable-default-compressed-debug-sections-algorithm=zlib \
  --enable-generate-build-notes=yes \
  --enable-serial-target-configure \
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
