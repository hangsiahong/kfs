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
  `dirname $($KFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h

cd $KFS/sources
rm -rf gcc-10.2.0   

}

03-linux() {
    cd $KFS/sources
    tar -xf linux-5.8.3.tar.xz
    cd linux-5.8.3
    make mrproper
    make headers
    find usr/include -name '.*' -delete
    rm usr/include/Makefile
    cp -rv usr/include $KFS/usr
    cd $KFS/sources
    rm -rf linux-5.8.3
}

04-glibc() {
    cd $KFS/sources
    tar -xf glibc-2.32.tar.xz
    cd glibc-2.32

case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $KFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $KFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $KFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac

patch -Np1 -i ../glibc-2.32-fhs-1.patch

mkdir -v build
cd       build

../configure                             \
      --prefix=/usr                      \
      --host=$KFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=$KFS/usr/include    \
      libc_cv_slibdir=/lib

make
make DESTDIR=$KFS install
$KFS/tools/libexec/gcc/$KFS_TGT/10.2.0/install-tools/mkheaders

cd $KFS/sources
rm -rf glibc-2.32
}

05-libstdc() {
    cd $KFS/sources
    tar -xvf gcc-10.2.0.tar.xz
    cd gcc-10.2.0

mkdir -v build
cd       build
../libstdc++-v3/configure           \
    --host=$KFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$KFS_TGT/include/c++/10.2.0

make
make DESTDIR=$KFS install
cd $KFS/sources
rm -rf gcc-10.2.0
}

06-m4() {
    cd $KFS/sources
    tar -xvf m4-1.4.18.tar.xz
    cd m4-1.4.18

    sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
    echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/usr   \
            --host=$KFS_TGT \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$KFS install

cd $KFS/sources
rm -rf m4-1.4.18
}

07-ncurses() {
    cd $KFS/sources
    tar -xvf ncurses-6.2.tar.gz
    cd ncurses-6.2

    sed -i s/mawk// configure

mkdir build
pushd build
  ../configure
  make -C include
  make -C progs tic
popd

./configure --prefix=/usr                \
            --host=$KFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-debug              \
            --without-ada                \
            --without-normal             \
            --enable-widec



make
make DESTDIR=$KFS TIC_PATH=$(pwd)/build/progs/tic install
echo "INPUT(-lncursesw)" > $KFS/usr/lib/libncurses.so

mv -v $KFS/usr/lib/libncursesw.so.6* $KFS/lib
ln -sfv ../../lib/$(readlink $KFS/usr/lib/libncursesw.so) $KFS/usr/lib/libncursesw.so

cd $KFS/sources
rm -rf ncurses-6.2

}

08-bash() {
    cd $KFS/sources
    tar -xvf bash-5.0.tar.gz
    cd bash-5.0

./configure --prefix=/usr                   \
            --build=$(support/config.guess) \
            --host=$KFS_TGT                 \
            --without-bash-malloc


make
make DESTDIR=$KFS install

mv $KFS/usr/bin/bash $KFS/bin/bash
ln -sv bash $KFS/bin/sh

cd $KFS/sources
rm -rf bash-5.0

}

09-coreutils() {
    cd $KFS/sources
    tar -xf coreutils-8.32.tar.xz
    cd coreutils-8.32

./configure --prefix=/usr                     \
            --host=$KFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

make
make DESTDIR=$KFS install
mv -v $KFS/usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} $KFS/bin
mv -v $KFS/usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm}        $KFS/bin
mv -v $KFS/usr/bin/{rmdir,stty,sync,true,uname}               $KFS/bin
mv -v $KFS/usr/bin/{head,nice,sleep,touch}                    $KFS/bin
mv -v $KFS/usr/bin/chroot                                     $KFS/usr/sbin
mkdir -pv $KFS/usr/share/man/man8
mv -v $KFS/usr/share/man/man1/chroot.1                        $KFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                                           $KFS/usr/share/man/man8/chroot.8

cd $KFS/sources
rm -rf coreutils-8.32
}

10-diffutils() {
    cd $KFS/sources
    tar -xf diffutils-3.7.tar.xz
    cd diffutils-3.7

./configure --prefix=/usr --host=$KFS_TGT
make
make DESTDIR=$KFS install

cd $KFS/sources
rm -rf diffutils-3.7
}

11-file() {
    cd $KFS/sources
    tar -xvf file-5.39.tar.gz
    cd file-5.39

./configure --prefix=/usr --host=$KFS_TGT
make
make DESTDIR=$KFS install

cd $KFS/sources
rm -rf file-5.39
}

12-findutils() {
    cd $KFS/sources
    tar -xf findutils-4.7.0.tar.xz
    cd findutils-4.7.0

./configure --prefix=/usr   \
            --host=$KFS_TGT \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$KFS install

mv -v $KFS/usr/bin/find $KFS/bin
sed -i 's|find:=${BINDIR}|find:=/bin|' $KFS/usr/bin/updatedb

cd $KFS/sources
rm -rf findutils-4.7.0
}

13-gawk() {
    cd $KFS/sources
    tar -xf gawk-5.1.0.tar.xz 
    cd gawk-5.1.0

    sed -i 's/extras//' Makefile.in
    
./configure --prefix=/usr   \
        --host=$KFS_TGT \
        --build=$(./config.guess)
    
make
make DESTDIR=$KFS install

cd $KFS/sources
rm -rf gawk-5.1.0
}

14-grep() {
    cd $KFS/sources
    tar -xf grep-3.4.tar.xz
    cd grep-3.4

./configure --prefix=/usr   \
            --host=$KFS_TGT \
            --bindir=/bin

make
make DESTDIR=$KFS install

cd $KFS/sources
rm -rf grep-3.4
}

15-gzip() {
    cd $KFS/sources
    tar -xf gzip-1.10.tar.xz
    cd gzip-1.10

./configure --prefix=/usr --host=$KFS_TGT
make
make DESTDIR=$KFS install
mv -v $kFS/usr/bin/gzip $KFS/bin

cd $KFS/sources
rm -rf gzip-1.10
}

16-make() {
    cd $KFS/sources
    tar -xvf make-4.3.tar.gz 
    cd make-4.3

./configure --prefix=/usr   \
            --without-guile \
            --host=$KFS_TGT \
            --build=$(build-aux/config.guess)

make
make DESTDIR=$KFS install

cd $KFS/sources
rm -rf make-4.3
}

17-patch() {
    cd $KFS/sources
    tar -xvf patch-2.7.6.tar.xz
    cd patch-2.7.6

./configure --prefix=/usr   \
            --host=$KFS_TGT \
            --build=$(build-aux/config.guess)    

make
make DESTDIR=$KFS install

cd $KFS/sources
rm -rf patch-2.7.6
}

18-sed() {
    cd $KFS/sources
    tar -xvf sed-4.8.tar.xz
    cd sed-4.8

./configure --prefix=/usr   \
            --host=$KFS_TGT \
            --bindir=/bin

make
make DESTDIR=$KFS install

cd $KFS/sources
rm -rf sed-4.8
}

19-tar() {
    cd $KFS/sources
    tar -xvf tar-1.32.tar.xz
    cd tar-1.32

./configure --prefix=/usr                     \
            --host=$KFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --bindir=/bin

make
make DESTDIR=$KFS install

}

20-xz() {
    cd $KFS/sources
    tar -xvf xz-5.2.5.tar.xz
    cd xz-5.2.5

./configure --prefix=/usr                     \
            --host=$KFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.2.5    

make
make DESTDIR=$KFS install

mv -v $KFS/usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat}  $KFS/bin
mv -v $KFS/usr/lib/liblzma.so.*                       $KFS/lib
ln -svf ../../lib/$(readlink $KFS/usr/lib/liblzma.so) $KFS/usr/lib/liblzma.so

cd $KFS/sources
rm -rf xz-5.2.5
}

21-binutils_pass_2() {
    cd $KFS/sources
    tar -xvf binutils-2.35.tar.xz 
    cd binutils-2.35

    mkdir -v build
    cd       build

../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$KFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --disable-werror           \
    --enable-64-bit-bfd

make
make DESTDIR=$KFS install

cd $KFS/sources
rm -rf binutils-2.35
}

22-gcc_pass_2() {
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
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac   

mkdir -v build
cd       build

mkdir -pv $KFS_TGT/libgcc
ln -s ../../../libgcc/gthr-posix.h $KFS_TGT/libgcc/gthr-default.h

../configure                                       \
    --build=$(../config.guess)                     \
    --host=$KFS_TGT                                \
    --prefix=/usr                                  \
    CC_FOR_TARGET=$KFS_TGT-gcc                     \
    --with-build-sysroot=$KFS                      \
    --enable-initfini-array                        \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++

make
make DESTDIR=$KFS install
ln -sv gcc $KFS/usr/bin/cc

cd $KFS/sources
rm -rf gcc-10.2.0
}

main() {
    01-binutils_pass_1 &&
    02-gcc_pass_1 &&
    03-linux &&
    04-glic &&
    05-libstdc &&
    06-m4 &&
    07-ncurses &&
    08-bash &&
    09-coreutils &&
    10-diffutils &&
    11-file &&
    12-findutils &&
    13-gawk &&
    14-grep &&
    15-gzip &&
    16-make &&
    17-patch &&
    18-sed &&
    19-tar &&
    20-xz &&
    21-binutils_pass_2 &&
    22-gcc_pass_2
}

main