#
# Copyright (c) 2019-2020 SRI International.
# All rights reserved.
#

# Try to find the GMP librairies
# GMP_FOUND - system has GMP lib
# GMP_INCLUDE_DIRS - the GMP include directory
# GMP_LIBRARIES - Libraries needed to use GMP

include(ExternalProject)

if(IOS)
    set(CMAKE_SYSTEM_NAME iOS)
    set(CMAKE_OSX_ARCHITECTURES arm64)
    if(NOT CMAKE_OSX_SYSROOT)
        execute_process(
            COMMAND xcrun --sdk iphoneos --show-sdk-path
            OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif()
    ExternalProject_Add(gmp_external
        URL https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
        PREFIX ${CMAKE_BINARY_DIR}/external/gmp
        CONFIGURE_COMMAND ./configure
            --prefix=${CMAKE_BINARY_DIR}/external/gmp
            --host=aarch64-apple-darwin
            --disable-shared
            --enable-static
            CC=${CMAKE_C_COMPILER}
            "CFLAGS=-arch arm64 -isysroot ${CMAKE_OSX_SYSROOT} -mios-version-min=12.0 -include ${CMAKE_CURRENT_SOURCE_DIR}/include/gmp_rename.h"
        BUILD_COMMAND make
        BUILD_IN_SOURCE 1
    )
    ExternalProject_Add_Step(gmp_external rename_symbols
        DEPENDEES build
        DEPENDERS install
        WORKING_DIRECTORY <BINARY_DIR>/.libs
        COMMAND sh -c "nm libgmp.a | grep -e '\\s___gmp' | awk '{print $NF}' | sort | uniq | awk '{print $1, \"_bfibe\" $1}' > renames.txt"
        COMMAND llvm-objcopy --redefine-syms=renames.txt libgmp.a libgmp.a
    )

    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/external/gmp/include)
    add_library(gmp STATIC IMPORTED GLOBAL)
    add_dependencies(gmp gmp_external)
    set_target_properties(gmp PROPERTIES
        IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/external/gmp/lib/libgmp.a
        INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/external/gmp/include
    )
elseif(ANDROID)
    ExternalProject_Add(gmp_external
        URL https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
        PREFIX ${CMAKE_BINARY_DIR}/external/gmp
        CONFIGURE_COMMAND ./configure
            --prefix=${CMAKE_BINARY_DIR}/external/gmp
            --host=aarch64-linux-android
            --disable-shared
            --enable-static
            CC=${CMAKE_C_COMPILER}
        BUILD_COMMAND make
        BUILD_IN_SOURCE 1
    )

    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/external/gmp/include)
    add_library(gmp STATIC IMPORTED GLOBAL)
    add_dependencies(gmp gmp_external)
    set_target_properties(gmp PROPERTIES
        IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/external/gmp/lib/libgmp.a
        INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_BINARY_DIR}/external/gmp/include
    )
else()
    find_library(GMP_LIBRARY gmp)
    find_path(GMP_INCLUDE_DIR gmp.h)

    message(STATUS "Found GMP library: ${GMP_LIBRARY} ||| Found GMP include dir: ${GMP_INCLUDE_DIR}")
    # ExternalProject_Add(gmp_external
    #     URL https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
    #     PREFIX ${CMAKE_BINARY_DIR}/external/gmp
    #     CONFIGURE_COMMAND ./configure
    #         --prefix=${CMAKE_BINARY_DIR}/external/gmp
    #         --host=aarch64-apple-darwin
    #         CC=${CMAKE_C_COMPILER}
    #     BUILD_COMMAND make
    #     BUILD_IN_SOURCE 1
    # )
endif(IOS)
set(GMP_ROOT ${CMAKE_BINARY_DIR}/external/gmp)

# if (GMP_INCLUDE_DIRS AND GMP_LIBRARIES)
#         # Already in cache, be silent
#         set(GMP_FIND_QUIETLY TRUE)
# endif (GMP_INCLUDE_DIRS AND GMP_LIBRARIES)

# find_path(GMP_INCLUDE_DIRS NAMES gmp.h
#     HINTS $ENV{GMP_INC})
# find_library(GMP_LIBRARIES NAMES gmp libgmp libgmp-10
#     HINTS $ENV{GMP_LIB})

# include(FindPackageHandleStandardArgs)
# FIND_PACKAGE_HANDLE_STANDARD_ARGS(GMP DEFAULT_MSG GMP_INCLUDE_DIRS GMP_LIBRARIES)

# mark_as_advanced(GMP_INCLUDE_DIRS GMP_LIBRARIES)