#!/bin/bash

cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > ~/.bashrc << "EOF"
set +h
umask 022
KFS=/mnt/kfs
LC_ALL=POSIX
KFS_TGT=$(uname -m)-kfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$KFS/tools/bin:$PATH
export KFS LC_ALL KFS_TGT PATH
EOF

source ~/.bash_profile
