# iOS toolchain for CMake (re-ios / baresip-ios)

set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_SYSTEM_PROCESSOR arm64)
set(CMAKE_HOST_SYSTEM_NAME Darwin)

# Allow override of platform: OS (default) or SIMULATOR
if(NOT DEFINED IOS_PLATFORM)
  set(IOS_PLATFORM "OS")  # Default to device build
endif()

# Determine SDK and architectures
if("${IOS_PLATFORM}" STREQUAL "SIMULATOR")
  set(IOS_SDK_TYPE iphonesimulator)
  set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
else()
  set(IOS_SDK_TYPE iphoneos)
  set(CMAKE_OSX_ARCHITECTURES "arm64")
endif()

# Use xcrun to locate the full path to the SDK
execute_process(
  COMMAND xcrun --sdk ${IOS_SDK_TYPE} --show-sdk-path
  OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Minimum iOS version
set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING "Minimum iOS version")

# Bitcode generally off for static builds
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "NO")

# Optional debug info
message(STATUS "✅ Platform: ${IOS_PLATFORM}")
message(STATUS "✅ SDK: ${IOS_SDK_TYPE}")
message(STATUS "✅ SYSROOT: ${CMAKE_OSX_SYSROOT}")
message(STATUS "✅ ARCHS: ${CMAKE_OSX_ARCHITECTURES}")

# OpenSSL setup
get_filename_component(PROJECT_ROOT "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(OPENSSL_ROOT_DIR "${PROJECT_ROOT}/../openssl" CACHE PATH "OpenSSL root")
set(OPENSSL_INCLUDE_DIR "${OPENSSL_ROOT_DIR}/include" CACHE PATH "OpenSSL include")
set(OPENSSL_SSL_LIBRARY "${OPENSSL_ROOT_DIR}/libssl.a" CACHE FILEPATH "libssl")
set(OPENSSL_CRYPTO_LIBRARY "${OPENSSL_ROOT_DIR}/libcrypto.a" CACHE FILEPATH "libcrypto")

# Export OpenSSL to CMake find_package()
set(OpenSSL_INCLUDE_DIR "${OPENSSL_INCLUDE_DIR}")
set(OpenSSL_LIBRARIES "${OPENSSL_SSL_LIBRARY};${OPENSSL_CRYPTO_LIBRARY}")

# Help CMake locate includes and libs
set(CMAKE_INCLUDE_PATH "${OPENSSL_INCLUDE_DIR}")
set(CMAKE_LIBRARY_PATH "${OPENSSL_ROOT_DIR}")
set(CMAKE_PREFIX_PATH "${OPENSSL_ROOT_DIR}")
set(CMAKE_FIND_ROOT_PATH "${CMAKE_OSX_SYSROOT};${OPENSSL_ROOT_DIR}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Feature toggles (e.g., minimal re/baresip builds)
set(USE_ZLIB OFF CACHE BOOL "" FORCE)
set(USE_BACKTRACE OFF CACHE BOOL "" FORCE)
set(USE_STUN OFF CACHE BOOL "" FORCE)
set(USE_TURN OFF CACHE BOOL "" FORCE)
set(USE_ICE OFF CACHE BOOL "" FORCE)
set(USE_TRICE OFF CACHE BOOL "" FORCE)
set(USE_UDP_SIP OFF CACHE BOOL "" FORCE)

