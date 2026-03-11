#
# Copyright (c) 2019-2020 SRI International.
# All rights reserved.
#

# Try to find the GMP librairies
# GMP_FOUND - system has GMP lib
# GMP_INCLUDE_DIRS - the GMP include directory
# GMP_LIBRARIES - Libraries needed to use GMP

include(ExternalProject)

if(IOS OR ANDROID OR EMSCRIPTEN)
    set(GMP_PREFIX ${CMAKE_BINARY_DIR}/external/gmp)
    if(IOS)
        set(CONFIGURE_COMMAND ./configure)
        set(MAKE_COMMAND make)
        set(GMP_CONFIGURE_OPTIONS
            --host=aarch64-apple-darwin
            $<$<BOOL:${IOS_SIMULATOR}>:--build=x86_64-apple-darwin> # Just need to be diff from host to trigger cross compilation without configure running tests to determine it. conftest hangs forever.
            --disable-shared
            --enable-static
        )
        set(CMAKE_SYSTEM_NAME iOS)
        set(CMAKE_OSX_ARCHITECTURES arm64)
        if(NOT CMAKE_OSX_SYSROOT)
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
        set(GMP_ENV
            CC=${CMAKE_C_COMPILER}
            "CFLAGS=-arch arm64 -isysroot ${CMAKE_OSX_SYSROOT} ${IOS_VERSION_FLAG} -include ${CMAKE_CURRENT_SOURCE_DIR}/include/gmp_rename.h"
        )
    elseif(ANDROID)
        set(CONFIGURE_COMMAND ./configure)
        set(MAKE_COMMAND make)
        set(GMP_CONFIGURE_OPTIONS
            # CMAKE_LIBRARY_ARCHITECTURE is populated by the toolchain file
            --host=${CMAKE_LIBRARY_ARCHITECTURE}
            --disable-shared
            --enable-static
            --with-pic
        )
        set(GMP_ENV
            CC=${CMAKE_C_COMPILER}
            AR=${CMAKE_AR}
            RANLIB=${CMAKE_RANLIB}
            STRIP=${CMAKE_STRIP}
            "CFLAGS=-include ${CMAKE_CURRENT_SOURCE_DIR}/include/gmp_rename.h --target=${CMAKE_C_COMPILER_TARGET}"
        )
    elseif(EMSCRIPTEN)
        set(CONFIGURE_COMMAND emconfigure ./configure)
        set(MAKE_COMMAND emmake make)
        set(GMP_CONFIGURE_OPTIONS
                --host=wasm32-unknown-emscripten
                --disable-shared
                --enable-static
        )
        set(GMP_ENV
            CC_FOR_BUILD=cc
        )
    endif()
    set(TIMESTAMP_OPTION "")
    if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.24")
        set(TIMESTAMP_OPTION DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
    endif()
    ExternalProject_Add(gmp_external
        URL https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
        ${TIMESTAMP_OPTION}
        PREFIX ${GMP_PREFIX} 
        BUILD_BYPRODUCTS ${GMP_PREFIX}/lib/libgmp.a
        CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
            --prefix=${GMP_PREFIX}
            ${GMP_CONFIGURE_OPTIONS}
            ${GMP_ENV}
        BUILD_COMMAND ${MAKE_COMMAND}
        BUILD_IN_SOURCE 1
    )
    # Rename symbols for iOS and Android
    if(IOS OR ANDROID)
        if(IOS)
            set(SYMBOL_RENAME_GMP_PREFIX "___gmp")
            set(SYMBOL_RENAME_BFIBE_PREFIX "_bfibe")
        else()
            # !!!Note NO underscore prefix for input and output symbols!!!
            set(SYMBOL_RENAME_GMP_PREFIX "__gmp")
            set(SYMBOL_RENAME_BFIBE_PREFIX "bfibe_")
        endif()
        ExternalProject_Add_Step(gmp_external rename_symbols
            DEPENDEES build
            DEPENDERS install
            WORKING_DIRECTORY <BINARY_DIR>/.libs
            COMMAND sh -c "nm libgmp.a | grep -e '\\s${SYMBOL_RENAME_GMP_PREFIX}' | awk '{print $NF}' | sort | uniq | awk '{print $1, \"${SYMBOL_RENAME_BFIBE_PREFIX}\" $1}' > renames.txt"
            COMMAND llvm-objcopy --redefine-syms=renames.txt libgmp.a libgmp.a
        )
    endif()
    file(MAKE_DIRECTORY ${GMP_PREFIX}/include)
    add_library(gmp STATIC IMPORTED GLOBAL)
    add_dependencies(gmp gmp_external)
    set_target_properties(gmp PROPERTIES
        IMPORTED_LOCATION ${GMP_PREFIX}/lib/libgmp.a
        INTERFACE_INCLUDE_DIRECTORIES ${GMP_PREFIX}/include
    )
else()
    find_library(GMP_LIBRARY gmp)
    find_path(GMP_INCLUDE_DIR gmp.h)

    message(STATUS "Found GMP library: ${GMP_LIBRARY} ||| Found GMP include dir: ${GMP_INCLUDE_DIR}")
endif()
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