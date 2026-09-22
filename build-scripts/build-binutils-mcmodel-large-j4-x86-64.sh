#!/bin/bash

here="`pwd`"
topdir="`dirname ${here}`"
srcdir="${topdir}/binutils-2.46.1"
target_platform="`uname -m`"
njobs=4
outfile="${here}/build-binutils-mcmodel-large-j${njobs}.out"
rc=0

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
export MAKE="/usr/bin/gmake"

cat /dev/null > ${outfile}

echo "gmake -j${njobs} >> ${outfile} 2>&1"
gmake -j${njobs} >> ${outfile} 2>&1
rc=$?

if [ ${rc} -eq 0 ] ; then
  echo "Binutils build OK."
else
  echo "Binutils build FAILED."
  exit 1
fi

