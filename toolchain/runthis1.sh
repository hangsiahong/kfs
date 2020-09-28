#!/bin/bash
# Author HangsiaHONG <hangsia@koompi.org>
source config

#CWD=$PWD
bash $PWD/toolchain/01-binutils_pass_1 && echo 'Success Build 01' &&
bash $PWD/toolchain/02-gcc_pass_1 && echo 'Success Build 02' &&
bash $PWD/toolchain/03-linux-api-headers && echo 'Success Build 03' &&
bash $PWD/toolchain/04-glibc && echo 'Success Build 04' &&
bash $PWD/toolchain/05-libstdc++ && echo 'Success Build 05' &&
bash $PWD/toolchain/06-m4 && echo 'Success Build 06' &&
bash $PWD/toolchain/07-ncurses && echo 'Success Build 07' &&
bash $PWD/toolchain/08-bash && echo 'Success Build 08' &&
bash $PWD/toolchain/09-coreutils && echo 'Success Build 09' &&
bash $PWD/toolchain/10-diffutils && echo 'Success Build 10' &&
bash $PWD/toolchain/11-file && echo 'Success Build 11' &&
bash $PWD/toolchain/12-findutils && echo 'Success Build 12' &&
bash $PWD/toolchain/13-gawk && echo 'Success Build 13' &&
bash $PWD/toolchain/14-grep && echo 'Success Build 14' &&
bash $PWD/toolchain/15-gzip && echo 'Success Build 15' &&
bash $PWD/toolchain/16-make && echo 'Success Build 16' &&
bash $PWD/toolchain/17-patch && echo 'Success Build 17' &&
bash $PWD/toolchain/18-sed && echo 'Success Build 18' &&
bash $PWD/toolchain/18-tar && echo 'Success Build 18' &&
bash $PWD/toolchain/19-xz && echo 'Success Build 19' &&
bash $PWD/toolchain/20-binutils_pass_2 && echo 'Success Build 20' &&
bash $PWD/toolchain/21-gcc_pass_2 && echo 'Success Build 21' 