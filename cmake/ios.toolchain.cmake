# iOS toolchain for building baresip via Xcode

set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING "Minimum iOS version")
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "NO")

# Detect and apply platform-specific settings
if(CMAKE_OSX_SYSROOT STREQUAL "iphoneos")
  message(STATUS "✅ Targeting iOS device (arm64)")
  set(CMAKE_SYSTEM_PROCESSOR arm64)
  set(CMAKE_OSX_ARCHITECTURES arm64 CACHE STRING "iOS device arch" FORCE)

elseif(CMAKE_OSX_SYSROOT STREQUAL "iphonesimulator")
  message(STATUS "✅ Targeting iOS simulator (arm64 + x86_64)")
  set(CMAKE_SYSTEM_PROCESSOR x86_64)
  set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64" CACHE STRING "iOS simulator fat binary" FORCE)

else()
  message(WARNING "⚠️ Unknown CMAKE_OSX_SYSROOT: ${CMAKE_OSX_SYSROOT}")
endif()

# Ensure correct platform settings
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Resolve full path to ../openssl relative to this toolchain file
get_filename_component(PROJECT_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(OPENSSL_ROOT_DIR "${PROJECT_ROOT}/../openssl" CACHE PATH "OpenSSL root")
set(OPENSSL_INCLUDE_DIR "${OPENSSL_ROOT_DIR}/include" CACHE PATH "OpenSSL include")
set(OPENSSL_CRYPTO_LIBRARY "${OPENSSL_ROOT_DIR}/libcrypto.a" CACHE FILEPATH "libcrypto")
set(OPENSSL_SSL_LIBRARY "${OPENSSL_ROOT_DIR}/libssl.a" CACHE FILEPATH "libssl")

# ChatGPT says these are optional... ?
set(OpenSSL_INCLUDE_DIR "${OPENSSL_INCLUDE_DIR}")
set(OpenSSL_LIBRARIES "${OPENSSL_SSL_LIBRARY};${OPENSSL_CRYPTO_LIBRARY}")

