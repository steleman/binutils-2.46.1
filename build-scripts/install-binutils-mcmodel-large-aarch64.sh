#!/bin/bash

here="`pwd`"
topdir="`dirname ${here}`"
srcdir="${topdir}/binutils-2.46.1"
target_platform="`uname -m`"
outfile="${here}/install-binutils-mcmodel-large.out"
rc=0

prefix="/opt/aarch64/gnu-toolchain"
bindir="${prefix}/bin"
libdir="${prefix}/lib"
libexecdir="${prefix}/libexec"
localstatedir="/var"
cross_toolchain="/opt/aarch64"
sysroot="${cross_toolchain}/aarch64-buildroot-linux-gnu/sysroot/"
destdir="${topdir}/install-binutils-mcmodel-large-aarch64"

if [ ! -d ${destdir} ] ; then
  mkdir -p ${destdir}
fi

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

export QEMU_LD_PREFIX="${cross_toolchain}/lib/"
export QEMU_CPU="cortex-a76"
export LD_LIBRARY_PATH="${cross_toolchain}/lib"

cat /dev/null > ${outfile}

echo "gmake DESTDIR=${destdir} install >> ${outfile} 2>&1"
gmake DESTDIR=${destdir} install >> ${outfile} 2>&1
rc=$?

if [ ${rc} -eq 0 ] ; then
  echo "Binutils install OK."
else
  echo "Binutils install FAILED."
  exit 1
fi

