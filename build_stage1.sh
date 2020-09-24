#!/bin/bash

export MAKEFLAGS='-j4'

01-binutils_pass_1() {
    cd $KFS/sources
    tar -xf binutils-2.35.tar.xz
    cd binutils-2.35

    mkdir -v build
    cd       build

../configure --prefix=$KFS/tools       \
             --with-sysroot=$KFS        \
             --target=$KFS_TGT          \
             --disable-nls              \
             --disable-werror

make
make install

cd $KFS/sources
rm -rf binutils-2.35
}

02-gcc_pass_1() {
    cd $KFS/sources
    tar -xf gcc-10.2.0.tar.xz
    cd gcc-10.2.0
    tar -xf ../mpfr-4.1.0.tar.xz
    mv -v mpfr-4.1.0 mpfr
    tar -xf ../gmp-6.2.0.tar.xz
    mv -v gmp-6.2.0 gmp
    tar -xf ../mpc-1.1.0.tar.gz
    mv -v mpc-1.1.0 mpc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac

mkdir -v build
cd       build

../configure                                       \
    --target=$KFS_TGT                              \
    --prefix=$KFS/tools                            \
    --with-glibc-version=2.11                      \
    --with-sysroot=$KFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --enable-initfini-array                        \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++

make
make install

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h

cd $KFS/sources
rm -rf gcc-10.2.0   

}























main() {
    01-binutils_pass_1 &&
    02-gcc_pass_1
}

main