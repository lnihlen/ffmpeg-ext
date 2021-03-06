#!/bin/sh

if [ $CROSS_WINDOWS = true ]; then
    mkdir $TRAVIS_BUILD_DIR/build/install-ext
    # libpng and others not necessary in final build as they are statically
    # linked. Furthermore there seems to be some issue in compressing them
    # so we put them in an intermediate build directory.
    mkdir $TRAVIS_BUILD_DIR/build/pre

    # build zlib for libpng
    cd $TRAVIS_BUILD_DIR/build
    git clone https://github.com/madler/zlib zlib
    cd zlib
    git checkout v1.2.11
    # spot of wisdom from https://wiki.openttd.org/Cross-compiling_for_Windows#libpng. The main makefile seems broken
    # for the cross-compilation use case. Modify the win32 makefile to use the mingw setup.
    sed -e s/"PREFIX ="/"PREFIX = x86_64-w64-mingw32-"/ -i win32/Makefile.gcc
    BINARY_PATH=${TRAVIS_BUILD_DIR}/build/pre/bin INCLUDE_PATH=${TRAVIS_BUILD_DIR}/build/pre/include                   \
        LIBRARY_PATH=${TRAVIS_BUILD_DIR}/build/pre/lib make -f win32/Makefile.gcc install

    # build libpng for png encodes
    cd $TRAVIS_BUILD_DIR/build
    git clone https://github.com/glennrp/libpng libpng
    cd libpng
    git checkout libpng16
    ./configure --prefix=$TRAVIS_BUILD_DIR/pre --host=x86_64-w64-mingw32 --enable-shared=no                            \
        CC=x86_64-w64-mingw32-gcc                                                                                      \
        CPPFLAGS="-I${TRAVIS_BUILD_DIR}/build/pre/include"                                                             \
        LDFLAGS="-L${TRAVIS_BUILD_DIR}/build/pre/lib"
    make || exit 1
    make install || exit 2

    # configure ffmpeg
    cd $TRAVIS_BUILD_DIR/build
    git clone $FFMPEG_GIT_REPO ffmpeg
    cd ffmpeg
    git checkout $FFMPEG_GIT_TAG
    ./configure --enable-gpl --arch=x86_64 --target-os=mingw32 --cross-prefix=x86_64-w64-mingw32-                      \
        --pkg-config=pkg-config --prefix=$TRAVIS_BUILD_DIR/build/install-ext --disable-programs --enable-shared        \
        --extra-cflags="-I${TRAVIS_BUILD_DIR}/build/pre/include"                                                       \
        --extra-ldflags="-L${TRAVIS_BUILD_DIR}/build/pre/lib"
else
    cmake -DSCIN_FFMPEG_GIT_REPO=$FFMPEG_GIT_REPO -DSCIN_FFMPEG_GET_TAG=$FFMPEG_GIT_TAG ..
fi

