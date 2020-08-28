#!/bin/bash

# First build patched qt4 static lib
cd wkhtmltopdf/qt

# We're linking openssl statically with the -openssl-linked argument
# to qt's configure. So we need libopenssl-static. We also need the
# headers from openssl. But if we add those packages to requirements
# in meta.yml as normal, there will be conflicts and we can't do the
# following hack to remove the .so files to force it to be linked
# statically.
conda create -y --prefix "${SRC_DIR}/openssl_hack" -c conda-forge  \
      --no-deps --yes --copy --prefix "${SRC_DIR}/openssl_hack"  \
      libopenssl-static=1.1.* openssl=1.1.*
export OPENSSL_LIBS="-L${SRC_DIR}/openssl_hack/lib -lssl -lcrypto"
# Remove the .so files so the linker will actually do static linking.
rm ${SRC_DIR}/openssl_hack/lib/libcrypto.so*
rm ${SRC_DIR}/openssl_hack/lib/libssl.so*
#rm -rf ${PREFIX}/include/openssl

# Remainder of this setup before ./configure is cribbed from the qt4 branch of qt-feedstock.
compiler_mkspec=mkspecs/common/g++-base.conf
flag_mkspec=mkspecs/linux-g++/qmake.conf

# The Anaconda gcc7 compiler flags specify -std=c++17 by default, which
# activates features that break compilation. Begone!
CXXFLAGS=$(echo $CXXFLAGS | sed -E 's@\-std=[^ ]+@@')
# Deviation from qt-feedstock: wkhtmltopdf uses some gnu extensions.
export CXXFLAGS="$CXXFLAGS -std=gnu++11"

# This warning causes a huge amount of spew in the build logs.
if [ "$cxx_compiler" = gxx ] ; then
export CXXFLAGS="$CXXFLAGS -Wno-expansion-to-defined"
fi

export LDFLAGS="$LDFLAGS -Wl,-rpath-link,$PREFIX/lib"
export LDFLAGS="$LDFLAGS -Wl,-rpath-link,${BUILD_PREFIX}/${HOST}/sysroot"
export CPPFLAGS="$CPPFLAGS -DXK_dead_currency=0xfe6f -DXK_ISO_Level5_Lock=0xfe13"
export CPPFLAGS="$CPPFLAGS -DFC_WEIGHT_EXTRABLACK=215 -DFC_WEIGHT_ULTRABLACK=FC_WEIGHT_EXTRABLACK"
export CPPFLAGS="$CPPFLAGS -DGLX_GLXEXT_PROTOTYPES"


# If we don't $(basename) here, when $CC contains an absolute path it will
# point into the *build* environment directory, which won't get replaced when
# making the package -- breaking the mkspec for downstream consumers.
sed -i -e "s|^QMAKE_CC.*=.*|QMAKE_CC = $(basename $CC)|" $compiler_mkspec
sed -i -e "s|^QMAKE_CXX.*=.*|QMAKE_CXX = $(basename $CXX)|" $compiler_mkspec

# The mkspecs only append to QMAKE_*FLAGS, so if we set them at the very top
# of the main mkspec file, the settings will be honored.

cp $flag_mkspec $flag_mkspec.orig
cat <<EOF >$flag_mkspec
QMAKE_CFLAGS = $CFLAGS $CPPFLAGS
QMAKE_CXXFLAGS = $CXXFLAGS $CPPFLAGS
QMAKE_LFLAGS = $LDFLAGS
EOF
cat $flag_mkspec.orig >>$flag_mkspec

# The main Qt build does eventually honor $LD, but it calls it like a
# compiler, not like the straight `ld` program as in the conda toolchain
# variables.
export LD="$CXX"

# If we leave these variables set, they will override our work during the main
# build.
unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS

# Most of these configure options are replicating the wkhtmltopdf
# build's options. We add some include and library paths and make it
# link with iconv.
./configure \
    -v \
    -I ${SRC_DIR}/openssl_hack/include \
    -I ${PREFIX}/include \
    -L ${PREFIX}/lib \
    -L ${BUILD_PREFIX}/${HOST}/sysroot/usr/lib64 \
    -liconv \
    -opensource \
    -confirm-license \
    -fast \
    -release \
    -static \
    -graphicssystem raster \
    -webkit \
    -exceptions \
    -xmlpatterns \
    -system-zlib \
    -system-libpng \
    -system-libjpeg \
    -no-libmng \
    -no-libtiff \
    -no-accessibility \
    -no-stl \
    -no-qt3support \
    -no-phonon \
    -no-phonon-backend \
    -no-opengl \
    -no-declarative \
    -no-script \
    -no-scripttools \
    -no-sql-db2 \
    -no-sql-ibase \
    -no-sql-mysql \
    -no-sql-oci \
    -no-sql-odbc \
    -no-sql-psql \
    -no-sql-sqlite \
    -no-sql-sqlite2 \
    -no-sql-tds \
    -no-mmx \
    -no-3dnow \
    -no-sse \
    -no-sse2 \
    -no-multimedia \
    -nomake demos \
    -nomake docs \
    -nomake examples \
    -nomake tools \
    -nomake tests \
    -nomake translations \
    -xrender \
    -largefile \
    -iconv \
    -openssl-linked \
    -no-javascript-jit \
    -no-rpath \
    -no-dbus \
    -no-nis \
    -no-cups \
    -no-pch \
    -no-gtkstyle \
    -no-nas-sound \
    -no-sm \
    -no-xshape \
    -no-xinerama \
    -no-xcursor \
    -no-xfixes \
    -no-xrandr \
    -no-mitshm \
    -no-xinput \
    -no-xkb \
    -no-glib \
    -no-gstreamer \
    -no-icu \
    -no-openvg \
    -no-xsync \
    -no-audio-backend \
    -no-sse3 \
    -no-ssse3 \
    -no-sse4.1 \
    -no-sse4.2 \
    -no-avx \
    -no-neon \
    --prefix=${PWD}
make -j ${CPU_COUNT}

cd ..

QMAKESPEC=${PWD}/qt/mkspecs/linux-g++
PATH=${PATH}:/qt/bin
export QMAKESPEC PATH
qt/bin/qmake wkhtmltopdf.pro CONFIG+=silent
make -j ${CPU_COUNT} install INSTALL_ROOT=$PREFIX
