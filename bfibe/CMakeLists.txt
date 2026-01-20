#
# Copyright (c) 2019-2020 SRI International.
# All rights reserved.
#

cmake_minimum_required(VERSION 3.10)

project(
  BFIBE VERSION 0.1
  DESCRIPTION "Boneh-Franklin Identity Based Encryption using the Weil pairing."
  LANGUAGES C)

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

# Dummy declarations to satisfy FindJNI when some parts of JNI
# aren't available on Android. "gmp" could be replaced with anything
# that doesn't blow the world up when passed to the compiler as a -l option.
if(ANDROID)
  set(CROSS_ANDROID ON)
elseif(IOS)
  set(CROSS ON)
  set(CROSS_TARGET "ios64-xcrun")
endif()

if(ANDROID)
  #set(JAVA_JVM_LIBRARY gmp)
  set(JAVA_INCLUDE_PATH2 NotNeeded)
else()
 if ("${TARGET_ARCHITECTURE}" STREQUAL "LINUX_arm64-v8a")
        list(APPEND LD_LIBRARY_PATH "/opt/homebrew/lib")
        include_directories("/opt/homebrew/include")
    else()
        message("appending /opt/homebrew/include")
        list(APPEND LD_LIBRARY_PATH "/opt/homebrew/lib")
        include_directories("/opt/homebrew/include")
    endif()
endif(ANDROID)
# set(JAVA_AWT_LIBRARY gmp)
# set(JAVA_AWT_INCLUDE_PATH NotNeeded)
# find_package(JNI REQUIRED)

find_package(GMP REQUIRED)
find_package(PBC REQUIRED)
find_package(OpenSSL REQUIRED)

add_library(bfibe STATIC
  src/bfibe.c src/hash.c src/base64.c
  src/api.c
  src/export.c src/security.c
  include/bfibe.h
  include/api.h)
target_include_directories(bfibe PUBLIC include)

if(IOS OR ANDROID)
  # Build OpenSSL from source for cross compilation
  set(BUILD_OPENSSL ON)
  set(OPENSSL_BUILD_VERSION "3.6.0")
  add_subdirectory(external/openssl-cmake)

  add_dependencies(bfibe gmp_external)
  add_dependencies(bfibe pbc_external)
  target_link_libraries(bfibe PUBLIC gmp)
  target_link_libraries(bfibe PUBLIC pbc)
  target_link_libraries(bfibe PRIVATE ssl crypto)
else()
  find_library(OPENSSL_CRYPTO_LIBRARY ssl)
  find_path(OPENSSL_INCLUDE_DIR openssl)

  target_link_libraries(bfibe ${GMP_LIBRARY})
  target_link_libraries(bfibe ${PBC_LIBRARY})
  target_link_libraries(bfibe ${OPENSSL_CRYPTO_LIBRARY})
  target_include_directories(bfibe SYSTEM PUBLIC ${GMP_INCLUDE_DIR})
  target_include_directories(bfibe SYSTEM PUBLIC ${PBC_INCLUDE_DIR})
  target_include_directories(bfibe SYSTEM PRIVATE ${OPENSSL_INCLUDE_DIR})

  # Only add executables when not cross compiling
  add_executable(genibe app/genibe.c)
  target_link_libraries(genibe PUBLIC bfibe)

  add_executable(genprivatekey app/genprivatekey.c)
  target_link_libraries(genprivatekey PUBLIC bfibe)

  add_executable(test app/test.c)
  target_link_libraries(test PUBLIC bfibe)

  add_executable(benchmark app/benchmark.c)
  target_link_libraries(benchmark PUBLIC bfibe)
  target_link_libraries(benchmark PUBLIC ${OPENSSL_CRYPTO_LIBRARY})
  target_include_directories(benchmark SYSTEM PRIVATE ${OPENSSL_INCLUDE_DIR})

  # add_library(bfibejni
  #             SHARED
  #             jni/bfibejni.c)
  # target_link_libraries(bfibejni PUBLIC bfibe)
  # target_include_directories(bfibejni SYSTEM PRIVATE ${JNI_INCLUDE_DIRS})
  # if(ANDROID)
  #   target_link_libraries(bfibejni PUBLIC log)
  # else()
  #   target_link_libraries(bfibejni PUBLIC ${JAVA_JVM_LIBRARY})
  # endif(ANDROID)

  install(TARGETS bfibe DESTINATION lib)
  # install(TARGETS bfibejni DESTINATION lib)
  install(TARGETS genprivatekey genibe DESTINATION bin)
endif()

