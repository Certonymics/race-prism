#
# Copyright (c) 2019-2020 SRI International.
# All rights reserved.
#

# Try to find the PBC librairies
# PBC_FOUND - system has PBC lib
# PBC_INCLUDE_DIRS - the PBC include directory
# PBC_LIBRARIES - Libraries needed to use PBC

include(ExternalProject)

if(NOT GMP_ROOT)
    message(FATAL_ERROR "GMP_ROOT is not set. Please set GMP_ROOT to the GMP installation root directory.")
endif()

if(IOS)
    set(CMAKE_SYSTEM_NAME iOS)
    set(CMAKE_OSX_ARCHITECTURES arm64)
    if (NOT CMAKE_OSX_SYSROOT)
        if(IOS_SIMULATOR)
            set(SDK iphonesimulator)
        else()
            set(SDK iphoneos)
        endif()
        execute_process(
            COMMAND xcrun --sdk ${SDK} --show-sdk-path
            OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif()
    set(IOS_VERSION_FLAG $<IF:$<BOOL:${IOS_SIMULATOR}>,-mios-simulator-version-min=12.0,-mios-version-min=12.0>)
    set(TIMESTAMP_OPTION "")
    if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.24")
        set(TIMESTAMP_OPTION DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
    endif()
    ExternalProject_Add(pbc_external
        URL https://crypto.stanford.edu/pbc/files/pbc-1.0.0.tar.gz
        ${TIMESTAMP_OPTION}
        PREFIX ${CMAKE_BINARY_DIR}/external/pbc
        DEPENDS gmp_external
        CONFIGURE_COMMAND ./configure
            --prefix=${CMAKE_BINARY_DIR}/external/pbc
            --host=aarch64-apple-darwin
            $<$<BOOL:${IOS_SIMULATOR}>:--build=x86_64-apple-darwin> # Just need to be diff from host to trigger cross compilation without configure running tests to determine it. conftest hangs forever.
            --build=x86_64-apple-darwin
            --disable-shared
            --enable-static
            "CC=${CMAKE_C_COMPILER} -arch arm64 -isysroot ${CMAKE_OSX_SYSROOT} ${IOS_VERSION_FLAG} -include ${CMAKE_CURRENT_SOURCE_DIR}/include/gmp_rename.h"
            "CFLAGS=-I${GMP_ROOT}/include"
            "CPPFLAGS=-I${GMP_ROOT}/include"
            "LDFLAGS=-arch arm64 -L${GMP_ROOT}/lib -isysroot ${CMAKE_OSX_SYSROOT}"
            LIBS=-lgmp
            ac_cv_lib_gmp___gmpz_init=yes
            LEXLIB=
        BUILD_COMMAND make
        BUILD_IN_SOURCE 1
    )

    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/external/pbc/include)
    add_library(pbc STATIC IMPORTED GLOBAL)
    set_target_properties(pbc PROPERTIES
        IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/external/pbc/lib/libpbc.a
        INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/external/pbc/include
    )
    add_dependencies(pbc pbc_external)
elseif(ANDROID)
    ExternalProject_Add(pbc_external
        URL https://crypto.stanford.edu/pbc/files/pbc-1.0.0.tar.gz
        PREFIX ${CMAKE_BINARY_DIR}/external/pbc
        BUILD_BYPRODUCTS ${CMAKE_BINARY_DIR}/external/pbc/lib/libpbc.a
        DEPENDS gmp_external
        CONFIGURE_COMMAND ./configure
            --prefix=${CMAKE_BINARY_DIR}/external/pbc
            --host=${CMAKE_LIBRARY_ARCHITECTURE}
            --disable-shared # Otherwise we get `ld64.lld: error: unknown argument '-soname'`
            --enable-static
            --with-pic # PIC is required for Android
            "CC=${CMAKE_C_COMPILER}"
            "AR=${CMAKE_AR}"
            "RANLIB=${CMAKE_RANLIB}"
            "STRIP=${CMAKE_STRIP}"
            "CFLAGS=-I${GMP_ROOT}/include -include ${CMAKE_CURRENT_SOURCE_DIR}/include/gmp_rename.h --target=${CMAKE_C_COMPILER_TARGET} --sysroot=${CMAKE_SYSROOT}"
            "CPPFLAGS=-I${GMP_ROOT}/include -include ${CMAKE_CURRENT_SOURCE_DIR}/include/gmp_rename.h --target=${CMAKE_C_COMPILER_TARGET} --sysroot=${CMAKE_SYSROOT}" # Required for .y files (e.g. pbc/parser.y)
            "LDFLAGS=-L${GMP_ROOT}/lib --target=${CMAKE_C_COMPILER_TARGET} --sysroot=${CMAKE_SYSROOT}"
            LIBS=-lgmp
            ac_cv_lib_gmp___gmpz_init=yes
            LEXLIB=
        BUILD_COMMAND make
        BUILD_IN_SOURCE 1
    )

    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/external/pbc/include)
    add_library(pbc STATIC IMPORTED GLOBAL)
    set_target_properties(pbc PROPERTIES
        IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/external/pbc/lib/libpbc.a
        INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/external/pbc/include
    )
    add_dependencies(pbc pbc_external)
elseif(EMSCRIPTEN)
    ExternalProject_Add(pbc_external
        URL https://crypto.stanford.edu/pbc/files/pbc-1.0.0.tar.gz
        PREFIX ${CMAKE_BINARY_DIR}/external/pbc
        DEPENDS gmp_external
        CONFIGURE_COMMAND emconfigure ./configure
            --prefix=${CMAKE_BINARY_DIR}/external/pbc
            --host=wasm32-unknown-emscripten
            --disable-shared
            --enable-static
            "CFLAGS=-I${GMP_ROOT}/include"
            "CPPFLAGS=-I${GMP_ROOT}/include" # Required for .y files (e.g. pbc/parser.y)
            "LDFLAGS=-L${GMP_ROOT}/lib"
            LIBS=-lgmp
            ac_cv_lib_gmp___gmpz_init=yes
            LEXLIB=
        BUILD_COMMAND emmake make
        BUILD_IN_SOURCE 1
    )

    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/external/pbc/include)
    add_library(pbc STATIC IMPORTED GLOBAL)
    set_target_properties(pbc PROPERTIES
        IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/external/pbc/lib/libpbc.a
        INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/external/pbc/include
    )
    add_dependencies(pbc pbc_external)
else()
    find_library(PBC_LIBRARY pbc)
    find_path(PBC_INCLUDE_DIR pbc/pbc.h)

    message(STATUS "Found PBC library at ${PBC_LIBRARY} ||| ${PBC_INCLUDE_DIR}")
endif()

# if (PBC_INCLUDE_DIRS AND PBC_LIBRARIES)
#         # Already in cache, be silent
#         set(PBC_FIND_QUIETLY TRUE)
# endif (PBC_INCLUDE_DIRS AND PBC_LIBRARIES)

# find_path(PBC_INCLUDE_DIRS NAMES pbc.h
#     HINTS $ENV{PBC_INC} pbc
#     PATH_SUFFIXES pbc)
# find_library(PBC_LIBRARIES NAMES pbc libpbc
#     HINTS $ENV{PBC_LIB})

# include(FindPackageHandleStandardArgs)
# FIND_PACKAGE_HANDLE_STANDARD_ARGS(PBC DEFAULT_MSG PBC_INCLUDE_DIRS PBC_LIBRARIES)

# mark_as_advanced(PBC_INCLUDE_DIRS PBC_LIBRARIES)