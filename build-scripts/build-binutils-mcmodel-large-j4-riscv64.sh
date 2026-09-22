#!/bin/bash

here="`pwd`"
topdir="`dirname ${here}`"
srcdir="${topdir}/binutils-2.46.1"
target_platform="`uname -m`"
njobs=4
outfile="${here}/build-binutils-mcmodel-large-j${njobs}.out"
rc=0

prefix="/opt/riscv/gnu-toolchain"
bindir="${prefix}/bin"
libdir="${prefix}/lib64"
libexecdir="${prefix}/libexec"
localstatedir="/var"
cross_toolchain="/opt/riscv"
sysroot="${cross_toolchain}/sysroot/"

march="-march=rv64gcv_zvfbfmin_zvfbfwma_zvfh_zvl128b"
mabi="-mabi=lp64d"

export CC="${cross_toolchain}/bin/riscv64-unknown-linux-gnu-gcc"
export CXX="${cross_toolchain}/bin/riscv64-unknown-linux-gnu-g++"
export LD="${cross_toolchain}/bin/riscv64-unknown-linux-gnu-ld.bfd"
export AR="${cross_toolchain}/bin/riscv64-unknown-linux-gnu-ar"
export NM="${cross_toolchain}/bin/riscv64-unknown-linux-gnu-nm"
export OBJCOPY="${cross_toolchain}/bin/riscv64-unknown-linux-gnu-objcopy"
export OBJDUMP="${cross_toolchain}/bin/riscv64-unknown-linux-gnu-obdump"
export RANLIB="${cross_toolchain}/bin/riscv64-unknown-linux-gnu-ranlib"
export READELF="${cross_toolchain}/bin/riscv64-unknown-linux-gnu-readelf"
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
export CFLAGS="-g -O2 -std=gnu11 -${march} ${mabi} -fPIC -I${cross_toolchain}/include"
export CXXFLAGS="-g -O2 -std=c++17 ${march} ${mabi} -fPIC -I${cross_toolchain}include"
export CPPFLAGS="-D_GNU_SOURCE -D_XOPEN_SOURCE=700"
export LDFLAGS="-Wl,--enable-new-dtags -Wl,-L -Wl,${cross_toolchain}/lib64"
export LDFLAGS="${LDFLAGS} -Wl,-L -Wl,${cross_toolchain}/sysroot/lib64/lp64d"
export LDFLAGS="${LDFLAGS} -Wl,-rpath -Wl,${cross_toolchain}/lib64"
export LDFLAGS="${LDFLAGS} -Wl,-rpath -Wl,${cross_toolchain}/sysroot/lib64/lp64d"
export PATH="${cross_toolchain}/bin:${PATH}"
export PKG_CONFIG_PATH="${cross_toolchain}/lib64/pkgconfig:${PKG_CONFIG_PATH}"

export QEMU_LD_PREFIX="${cross_toolchain}/lib64/"
export QEMU_CPU="rv64,v=true"
export LD_LIBRARY_PATH="${cross_toolchain}/lib64:${cross_toolchain}/sysroot/lib64/lp64d"

cat /dev/null > ${outfile}

echo "gmake -k -j${njobs} >> ${outfile} 2>&1"
gmake -k -j${njobs} >> ${outfile} 2>&1
rc=$?

if [ ${rc} -eq 0 ] ; then
  echo "Binutils build OK."
else
  echo "Binutils build FAILED."
  exit 1
fi

