#! /bin/sh

# based on scripts found at:
#   http://nic-nac-project.de/~schwinge/tmp/cross-gnu-env
#   http://nic-nac-project.de/~schwinge/tmp/cross-gnu

ROOT=~/hurd
HOST=i686-pc-linux-gnu
TARGET=i586-pc-gnu

BINUTILS_VER=2.19.1
GCC_VER=4.1.2
GLIBC_VER=2.7


prepare()
{
  # clear system variables
  export LC_ALL=C
  unset ASFLAGS CFLAGS CPPFLAGS CXXFLAGS LDFLAGS MAKEFLAGS

  # prepare directories
  mkdir -p $ROOT
  export SOURCE_DIR=$ROOT/source
  export BUILD_DIR=$ROOT/build
  export INSTALL_DIR=$ROOT/install
  mkdir -p $SOURCE_DIR $BUILD_DIR $INSTALL_DIR
  rm -rf $BUILD_DIR/* $INSTALL_DIR/*

  mkdir -p $INSTALL_DIR/{bin,$TARGET}
  export PATH=$INSTALL_DIR/bin:$PATH

  export SYS_ROOT=$INSTALL_DIR/sys_root
  mkdir -p $SYS_ROOT/{include,lib}
  ln -sfn $SYS_ROOT/{include,lib} $INSTALL_DIR/$TARGET/
}

get_source()
{
  cd $SOURCE_DIR
  
  if [ ! -f binutils-$BINUTILS_VER.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VER.tar.bz2
  fi
  rm -rf binutils-$BINUTILS_VER
  tar -xf binutils-$BINUTILS_VER.tar.bz2
  
  if [ ! -f gcc-core-$GCC_VER.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VER/gcc-core-$GCC_VER.tar.bz2
  fi
  if [ ! -f gcc-g++-$GCC_VER.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VER/gcc-g++-$GCC_VER.tar.bz2
  fi
  rm -rf gcc-$GCC_VER
  tar -xf gcc-core-$GCC_VER.tar.bz2
  tar -xf gcc-g++-$GCC_VER.tar.bz2

  if [ ! -f glibc-$GLIBC_VER.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/glibc/glibc-$GLIBC_VER.tar.bz2
  fi
  rm -rf glibc-$GLIBC_VER
  tar -xf glibc-$GLIBC_VER.tar.bz2
  patch_glibc
  
  # git sources
  GIT_ROOT=git://git.sv.gnu.org/hurd/
  
  for pkg in gnumach mig hurd; do
    if [ -d $SOURCE_DIR/$pkg ] ; then
      cd $SOURCE_DIR/$pkg && git pull origin
    else
      git clone $GIT_ROOT/$pkg.git
    fi
  done
  
  cd $SOURCE_DIR/hurd
  if [ -d libpthread ] ; then
    cd libpthread && git pull origin
  else
    git clone $GIT_ROOT/$libpthread.git
  fi 
  
  for pkg in gnumach mig hurd; do
    cd $SOURCE_DIR/$pkg
    autoreconf -vif
  done  
}

patch_glibc()
{
  PATCH1=(0003-2007-09-13-H.J.-Lu-hongjiu.lu-intel.com.patch
          0005-Hurd-specific-kernel-features.h.patch
          0007-2007-10-05-version-of-stat.patch
          0008-r2425-of-debian-patches-hurd-i386-local-atomic-no-mu.patch
          0010-r2425-of-debian-patches-hurd-i386-local-gscope.diff.patch
          0012-r2425-of-debian-patches-hurd-i386-local-no-strerror_.patch
          0013-r2626-of-debian-patches-hurd-i386-local-tls-support.patch
          0014-r2591-of-debian-patches-hurd-i386-local-tls.diff.patch
          0015-r2630-of-debian-patches-hurd-i386-submitted-libc_onc.patch
          0016-Include-stdint.h.patch
          0017-r2598-of-debian-patches-any-local-stdio-lock.diff.patch
          0018-r2650-of-debian-patches-hurd-i386-submitted-strtoul.patch
          0019-2007-11-12-Aurelien-Jarno-aurelien-aurel32.net-Tho.patch
          0020-r2656-of-debian-patches-any-submitted-sched_h.diff.patch
          0022-2007-11-18-Roland-McGrath-roland-frob.com.patch
          0024-2007-03-18-Joseph-Myers-joseph-codesourcery.com.patch)

  PATCH0=(0009-2007-07-22-version-of-init-first.c_vs._GCC_4.1.patch
          0011-2007-02-08-version-of-resolv_res_send.c.patch.patch
          new-needed-1.patch)

  PATCH_SOURCE=http://www.schwinge.homeip.net/~thomas/tmp/glibc-patches/

  cd $SOURCE_DIR/patches

  for p in ${PATCH1[@]} ${PATCH0[@]}; do
    if [ ! -f $p ]; then
      wget $PATCH_SOURCE/$p
    fi
  done
  
  cd $SOURCE_DIR/glibc-$GLIBC_VER
  for p in ${PATCH1[@]}; do
    patch -p1 < ../patches/$p
  done
  for p in ${PATCH0[@]}; do
    patch -p0 < ../patches/$p
  done
  
  # fix for binutils>=2.20
  #sed -i "s#2.1\[3-9\]\*#2.2\[0-9\]\*#" configure
  
  cd $SOURCE_DIR
}

binutils()
{
  mkdir -p $BUILD_DIR/binutils
  cd $BUILD_DIR/binutils
  
  $SOURCE_DIR/binutils-$BINUTILS_VER/configure \
    --target=$TARGET \
    --prefix=$INSTALL_DIR \
    --with-sysroot=$SYS_ROOT \
    --disable-nls

  make all install
}

gcc_pass1()
{
  mkdir -p $BUILD_DIR/gcc
  cd $BUILD_DIR/gcc
  
  $SOURCE_DIR/gcc-$GCC_VER/configure \
    --target=$TARGET \
    --prefix=$INSTALL_DIR \
    --with-sysroot=$SYS_ROOT \
    --disable-nls \
    --disable-shared \
    --disable-threads \
    --without-headers \
    --with-newlib \
    --enable-languages=c \
    --with-arch=i586
    # this is craptastic!
    # setting i686 causes glibc-2.7 build failures, as does not setting this
    # so we need to set either i486 or i586 or deal with CFLAGS instead
    
  make all-gcc install-gcc
  # for gcc>=4.3
  #make all-target-libgcc install-target-libgcc
  
  # glibc tries to link to this
  echo '/* Empty.  */' > "$SYS_ROOT"/lib/libgcc_eh.a
  
  # prepare for pass 2
  rm -f config.status config.cache */config.cache */*/config.cache
}

gnumach_headers()
{
  mkdir -p $BUILD_DIR/gnumach
  cd $BUILD_DIR/gnumach
  
  CC=gcc \
  $SOURCE_DIR/gnumach/configure \
    --host=$TARGET \
    --prefix=
  
  make DESTDIR=$SYS_ROOT install-data
}

mig()
{
  mkdir -p $BUILD_DIR/mig
  cd $BUILD_DIR/mig
  
  $SOURCE_DIR/mig/configure \
    --target=$TARGET \
    --prefix=$INSTALL_DIR

  make all install
}

hurd_headers()
{
  mkdir -p $BUILD_DIR/hurd
  cd $BUILD_DIR/hurd
  
  CC=gcc \
  $SOURCE_DIR/hurd/configure \
    --host=$TARGET \
    --prefix= \
    --disable-profile
  
  make prefix=$SYS_ROOT no_deps=t install-headers
  
  # prepare for libpthread build
  rm config.status
}

glibc_pass1()
{
  mkdir -p $BUILD_DIR/glibc
  cd $BUILD_DIR/glibc

  $SOURCE_DIR/glibc-$GLIBC_VER/configure \
    --without-cvs \
    --build=$HOST \
    --host=$TARGET \
    --prefix= \
    --with-headers=$SYS_ROOT/include \
    --disable-profile
  
  make install_root=$SYS_ROOT all install
  ln -sf ld.so.1 $SYS_ROOT/lib/ld.so
  
  # prepare for pass 2
  rm -f $SOURCE_DIR/glibc/config.status
}

libpthread()
{
  cd $BUILD_DIR/hurd

  $SOURCE_DIR/hurd/configure \
    --host=$TARGET \
    --prefix= \
    --disable-profile

  make libpthread
  make prefix=$SYS_ROOT libihash-install libpthread-install
}

gcc_pass2()
{
  cd $BUILD_DIR/gcc
  
  $SOURCE_DIR/gcc-$GCC_VER/configure \
    --target=$TARGET \
    --prefix=$INSTALL_DIR \
    --with-sysroot=$SYS_ROOT \
    --disable-nls \
    --enable-threads=posix \
    --enable-languages=c,c++ \
    --with-arch=i586
  
  make all
  
  # clean up files installed in pass 1
  rm -f $SYS_ROOT/lib/libgcc_eh.a $INSTALL_DIR/lib/gcc/$TARGET/$GCC_VER/{libgcc.a,libgcov.a}

  make install
}

glibc_pass2()
{
  cd $BUILD_DIR/glibc

  $SOURCE_DIR/glibc-$GLIBC_VER/configure \
    --without-cvs \
    --build=$HOST \
    --host=$TARGET \
    --prefix= \
    --with-headers=$SYS_ROOT/include \
    --disable-profile
  
  make install_root=$SYS_ROOT all install
}


prepare
get_source
binutils
gcc_pass1
gnumach_headers
mig
hurd_headers
glibc_pass1
libpthread
gcc_pass2
glibc_pass2
