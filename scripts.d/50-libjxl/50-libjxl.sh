#!/bin/bash

JXL_REPO="https://github.com/libjxl/libjxl.git"
JXL_COMMIT="bd48652dba3469244af489e48c645307191cc039"

ffbuild_enabled() {
    [[ $ADDINS_STR == *4.4* ]] && return -1
    [[ $ADDINS_STR == *5.0* ]] && return -1
    return 0
}

ffbuild_dockerbuild() {
    git-mini-clone "$JXL_REPO" "$JXL_COMMIT" jxl
    cd jxl
    git submodule update --init --recursive --depth 1 --recommend-shallow third_party/{highway,skcms}

    mkdir build && cd build

    if [[ $TARGET == linux* ]]; then
        # our glibc is too old(<2.25), and their detection fails for some reason
        export CXXFLAGS="$CXXFLAGS -DVQSORT_GETRANDOM=0 -DVQSORT_SECURE_SEED=0"
    fi

#    export CXXFLAGS="$CXXFLAGS -DHWY_COMPILE_ONLY_SCALAR"
#    export CFLAGS="$CFLAGS -DHWY_COMPILE_ONLY_SCALAR"

    cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DBUILD_SHARED_LIBS=OFF -DJPEGXL_STATIC=OFF -DJPEGXL_ENABLE_TOOLS=OFF -DJPEGXL_ENABLE_VIEWERS=OFF -DJPEGXL_EMSCRIPTEN=OFF -DJPEGXL_ENABLE_DOXYGEN=OFF \
        -DBUILD_TESTING=OFF -DJPEGXL_ENABLE_EXAMPLES=OFF -DJPEGXL_ENABLE_MANPAGES=OFF -DJPEGXL_ENABLE_JNI=OFF -DJPEGXL_ENABLE_PLUGINS=OFF \
        -DJPEGXL_ENABLE_DEVTOOLS=OFF -DJPEGXL_ENABLE_BENCHMARK=OFF -DJPEGXL_BUNDLE_LIBPNG=OFF -DJPEGXL_ENABLE_SJPEG=OFF -DJPEGXL_FORCE_SYSTEM_BROTLI=ON ..
    ninja -j$(nproc)
    ninja install

    echo "Cflags.private: -DJXL_STATIC_DEFINE=1" >> "${FFBUILD_PREFIX}"/lib/pkgconfig/libjxl.pc
    echo "Libs.private: -lstdc++" >> "${FFBUILD_PREFIX}"/lib/pkgconfig/libjxl.pc

    echo "Cflags.private: -DJXL_STATIC_DEFINE=1" >> "${FFBUILD_PREFIX}"/lib/pkgconfig/libjxl_threads.pc
    echo "Libs.private: -lstdc++" >> "${FFBUILD_PREFIX}"/lib/pkgconfig/libjxl_threads.pc

    if [[ $TARGET == win* ]]; then
        echo "Libs.private: -ladvapi32" >> "${FFBUILD_PREFIX}"/lib/pkgconfig/libjxl.pc
        echo "Libs.private: -ladvapi32" >> "${FFBUILD_PREFIX}"/lib/pkgconfig/libjxl_threads.pc

        mv "${FFBUILD_PREFIX}"/lib/libjxl{-static,}.a
        mv "${FFBUILD_PREFIX}"/lib/libjxl_dec{-static,}.a
        mv "${FFBUILD_PREFIX}"/lib/libjxl_threads{-static,}.a
    fi
}

ffbuild_configure() {
    echo --enable-libjxl
}

ffbuild_unconfigure() {
    [[ $ADDINS_STR == *4.4* ]] && return 0
    [[ $ADDINS_STR == *5.0* ]] && return 0
    echo --disable-libjxl
}
