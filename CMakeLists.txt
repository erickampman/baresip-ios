#
# CMakeLists.txt
#
# Copyright (C) 2010 - 2022 Alfred E. Heggestad
# Copyright (C) 2022 Sebastian Reimers
# Copyright (C) 2023 Christian Spielberger
#

##############################################################################
#
# Versioning
#

cmake_minimum_required(VERSION 3.15...3.31)

project(baresip VERSION 3.21.0)

set(PROJECT_SOVERSION 20) # bump if ABI breaks

# Pre-release identifier, comment out on a release
# Increment for breaking changes (dev2, dev3...)
#set(PROJECT_VERSION_PRE dev)

if(PROJECT_VERSION_PRE)
  set(PROJECT_VERSION_FULL ${PROJECT_VERSION}-${PROJECT_VERSION_PRE})
else()
  set(PROJECT_VERSION_FULL ${PROJECT_VERSION})
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

##############################################################################
#
# ELK ... I dunno about this. Not sure iOS has this.
#
add_definitions(-DHAVE_UNISTD_H)

##############################################################################
#
# Module/Package Includes
#

option(AUTODETECT_MODULES "Autodetect modules" OFF)

set(MODULES
  contact
  coreaudio
  g711
  srtp
  uuid
)


include(GNUInstallDirs)
include(CheckIncludeFile)
# find_package(RE REQUIRED) # not the way I'm doing it. ELK

##############################################################################
#
# Compile options
#

# Modified so always building static lib
option(STATIC "Build static" ON)



set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_C_STANDARD 11)

if(APPLE)
  set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
  set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
endif()

if(MSVC)
  add_compile_options("/W3")
else()
  add_compile_options(
    -Wall
    -Wextra
  )

  set(c_flags
    -pedantic
    -Wcast-align
    -Wbad-function-cast
    -Wmissing-declarations
    -Wmissing-prototypes
    -Wnested-externs
    -Wno-strict-aliasing
    -Wold-style-definition
    -Wshadow -Waggregate-return
    -Wstrict-prototypes
    -Wuninitialized
    -Wvla
  )

  if(CMAKE_C_COMPILER_ID MATCHES "Clang")
    list(APPEND c_flags
      -Watomic-implicit-seq-cst
      -Wshorten-64-to-32
      -Wno-gnu-zero-variadic-macro-arguments
      -Wno-c2x-extensions
    )
  endif()

  add_compile_options(
    "$<$<COMPILE_LANGUAGE:C>:${c_flags}>"
  )
endif()



# find_package(re CONFIG REQUIRED HINTS ../re/cmake) # Not the way I'm doing it. ELK

list(APPEND RE_DEFINITIONS
  VERSION="${PROJECT_VERSION_FULL}"
  VER_MAJOR=${PROJECT_VERSION_MAJOR}
  VER_MINOR=${PROJECT_VERSION_MINOR}
  VER_PATCH=${PROJECT_VERSION_PATCH}
  _GNU_SOURCE
)

add_compile_definitions(${RE_DEFINITIONS})

# include_directories(
#   include
#   src
#   ${RE_INCLUDE_DIRS}
#   ${OPENSSL_INCLUDE_DIR}
# )

if(MOD_PATH)
  add_definitions(-DMOD_PATH="${MOD_PATH}")
elseif(CMAKE_INSTALL_FULL_LIBDIR)
  add_definitions(-DMOD_PATH="${CMAKE_INSTALL_FULL_LIBDIR}/baresip/modules")
endif()

if(SHARE_PATH)
  add_definitions(-DSHARE_PATH="${SHARE_PATH}")
else()
  add_definitions(-DSHARE_PATH="${CMAKE_INSTALL_FULL_DATADIR}/baresip")
endif()

if(DEFAULT_CAFILE)
  add_definitions(-DDEFAULT_CAFILE="${DEFAULT_CAFILE}")
endif()

if(DEFAULT_CAPATH)
  add_definitions(-DDEFAULT_CAPATH="${DEFAULT_CAPATH}")
endif()

if(DEFAULT_AUDIO_DEVICE)
  add_definitions(-DDEFAULT_AUDIO_DEVICE="${DEFAULT_AUDIO_DEVICE}")
endif()

if(STATIC)
  add_definitions(-DSTATIC)
endif()

##############################################################################
#
# Source section
#

set(SRCS
  src/account.c
  src/aucodec.c
  src/audio.c
  src/aufilt.c
  src/auplay.c
  src/aureceiver.c
  src/ausrc.c
  src/baresip.c
  src/bundle.c
  src/call.c
  src/cmd.c
  src/conf.c
  src/config.c
  src/contact.c
  src/custom_hdrs.c
  src/descr.c
  src/dial_number.c
  src/bevent.c
  src/jbuf.c
  src/http.c
  src/log.c
  src/mediadev.c
  src/mediatrack.c
  src/menc.c
  src/message.c
  src/metric.c
  src/mnat.c
  src/module.c
  src/net.c
  src/peerconn.c
  src/play.c
  src/reg.c
  src/rtprecv.c
  src/rtpstat.c
  src/sdp.c
  src/sipreq.c
  src/stream.c
  src/stunuri.c
  src/timestamp.c
  src/ua.c
  src/uag.c
  src/ui.c
  src/vidcodec.c
  src/video.c
  src/vidfilt.c
  src/vidisp.c
  src/vidsrc.c
  src/vidutil.c
)

set(HEADERS
  include/baresip.h
)
##############################################################################
#
# extra c files to compile -- not sure why they are missing
#

set(MODULE_SRCS
    modules/contact/contact.c
    modules/g711/g711.c
    modules/srtp/srtp.c
    modules/srtp/sdes.c
    modules/uuid/uuid.c
)

list(APPEND SRCS ${MODULE_SRCS})


##############################################################################
#
# Modules
#

include(modules)

set(MODULES_DETECTED "")

foreach(mod IN LISTS MODULES)
  add_subdirectory(modules/${mod})

  if(TARGET ${mod})
    target_include_directories(${mod} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_CURRENT_SOURCE_DIR}/../re-ios/include
    )
  endif()
endforeach()

foreach(mod IN LISTS APP_MODULES)
  add_subdirectory(
    ${APP_MODULES_DIR}/${mod}
    ${CMAKE_CURRENT_BINARY_DIR}/app_modules/${mod}
  )
  list(APPEND MODULES_DETECTED ${mod})
endforeach()

list(REMOVE_DUPLICATES MODULES_DETECTED)

foreach(mod IN LISTS MODULES_DETECTED)
  set_target_properties(${mod} PROPERTIES PREFIX "")
endforeach()

message("MODULES_DETECTED=${MODULES_DETECTED}")

if(STATIC)
  foreach(mod IN LISTS MODULES_DETECTED)
    set(MOD_EXPORTS
      "${MOD_EXPORTS}extern const struct mod_export exports_${mod};\n")
    set(MOD_EXPORT_TABLE
      "${MOD_EXPORT_TABLE}  &exports_${mod},\n")
  endforeach()

  configure_file(src/static.c.in src/static.c)
  list(APPEND SRCS ${CMAKE_CURRENT_BINARY_DIR}/src/static.c)
else()
  foreach(mod IN LISTS MODULES_DETECTED)
    if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
      set_target_properties(${mod} PROPERTIES
                            LINK_FLAGS "-undefined dynamic_lookup")
    endif()
  endforeach()
endif()


##############################################################################
#
# Main target library
#

set(LINKLIBS re) # as per chatGPT

add_library(baresip STATIC ${SRCS} ${HEADERS})

# Include paths
target_include_directories(baresip PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../re-ios/include>
  $<INSTALL_INTERFACE:include>
)

# Link against re and OpenSSL
target_link_libraries(baresip PRIVATE
  re
  ${OPENSSL_SSL_LIBRARY}
  ${OPENSSL_CRYPTO_LIBRARY}
)

# Archiving settings
set_target_properties(baresip PROPERTIES
  OUTPUT_NAME "baresip"
  ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/Release"
  POSITION_INDEPENDENT_CODE ON
  XCODE_GENERATE_SCHEME TRUE
  PUBLIC_HEADER "${HEADERS}"
)

# Optional: Alias + install support
add_library(baresip::baresip ALIAS baresip)
add_custom_target(build-baresip ALL DEPENDS baresip)
list(APPEND BARESIP_INSTALL_TARGETS baresip)

install(TARGETS baresip
  ARCHIVE DESTINATION lib
  PUBLIC_HEADER DESTINATION include
)

##############################################################################
#
# PKGCONF section
#

configure_file(packaging/libbaresip.pc.in libbaresip.pc @ONLY)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libbaresip.pc
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig
  COMPONENT Development
)

##############################################################################
#
# Install section
#

install(TARGETS baresip
  RUNTIME
    DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT Applications
  LIBRARY
    DESTINATION ${CMAKE_INSTALL_LIBDIR}
    COMPONENT Libraries
    NAMELINK_SKIP
  ARCHIVE
    DESTINATION ${CMAKE_INSTALL_LIBDIR}
    COMPONENT Development
  PUBLIC_HEADER
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    COMPONENT Development
)

if(NOT STATIC)
  foreach(mod IN LISTS MODULES_DETECTED)
    install(TARGETS ${mod}
      LIBRARY
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/baresip/modules
        COMPONENT Applications
    )
  endforeach()
endif()

install(TARGETS baresip
  LIBRARY
    DESTINATION ${CMAKE_INSTALL_LIBDIR}
    NAMELINK_ONLY
    COMPONENT Development
)

file(GLOB SHARE_FILES
  "${PROJECT_SOURCE_DIR}/share/*.png"
  "${PROJECT_SOURCE_DIR}/share/*.wav"
)
file(GLOB DESKTOP_FILES "${PROJECT_SOURCE_DIR}/share/*.desktop")

install(FILES ${SHARE_FILES}
  DESTINATION ${CMAKE_INSTALL_DATADIR}/baresip
  COMPONENT Applications
)

install(FILES ${DESKTOP_FILES}
  DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
  COMPONENT Applications
)


##############################################################################
#
# Packaging section
#

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  add_subdirectory(packaging)
endif()
