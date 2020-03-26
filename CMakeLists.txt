cmake_minimum_required(VERSION 3.0)

# Disable in-source builds to prevent source tree corruption.
if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
    message(FATAL_ERROR "FATAL: In-source builds are not allowed.
    You should create a separate directory for build files.")
endif()

# Set project informations
set(PROJECT_NAME libserialport)
set(PROJECT_LANGUAGE C)

# Set package version and informations
set(SP_PACKAGE_VERSION_MAJOR 0)
set(SP_PACKAGE_VERSION_MINOR 1)
set(SP_PACKAGE_VERSION_MICRO 1)
set(SP_PACKAGE_VERSION
    ${SP_PACKAGE_VERSION_MAJOR}.${SP_PACKAGE_VERSION_MINOR}.${SP_PACKAGE_VERSION_MICRO})
set(SP_PACKAGE_VERSION_STRING
    "\"${SP_PACKAGE_VERSION_MAJOR}.${SP_PACKAGE_VERSION_MINOR}.${SP_PACKAGE_VERSION_MICRO}\"")

set(SP_LIB_VERSION_CURRENT 1)
set(SP_LIB_VERSION_REVISION 0)
set(SP_LIB_VERSION_AGE 1)
set(SP_LIB_VERSION_STRING
    "\"${SP_LIB_VERSION_CURRENT}:${SP_LIB_VERSION_REVISION}:${SP_LIB_VERSION_AGE}\"")

set(PACKAGE_NAME "\"libserialport\"")
set(PACKAGE_VERSION ${SP_PACKAGE_VERSION_STRING})
set(PACKAGE_BUGREPORT "\"martin-libserialport@earth.li\"")
set(PACKAGE_TARNAME "\"libserialport\"")
set(PACKAGE_URL "\"http://sigrok.org/wiki/Libserialport\"")
set(PACKAGE_STRING "\"libserialport ${SP_PACKAGE_VERSION_MAJOR}.${SP_PACKAGE_VERSION_MINOR}.${SP_PACKAGE_VERSION_MICRO}\"")

# Set default build type to release
if(NOT CMAKE_CONFIGURATION_TYPE AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Setup project
project(${PROJECT_NAME}
    LANGUAGES ${PROJECT_LANGUAGE}
    VERSION ${SP_PACKAGE_VERSION_MAJOR}.${SP_PACKAGE_VERSION_MINOR}.${SP_PACKAGE_VERSION_MICRO})

# Add definitions
add_definitions(-DLIBSERIALPORT_CMAKE_SIMULATION)
if(MSVC)
    add_definitions(-DLIBSERIALPORT_MSBUILD)
else()
    add_definitions(-DLIBSERIALPORT_ATBUILD)
endif()

# Let CMake can find custom modules
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

# Include check modules
include(CheckIncludeFile)
include(CheckCSourceCompiles)
include(CheckFunctionExists)
include(CheckMacro)

# Checking: include files
CHECK_INCLUDE_FILE("dlfcn.h" HAVE_DLFCN_H)
CHECK_INCLUDE_FILE("inttypes.h" HAVE_INTTYPES_H)
CHECK_INCLUDE_FILE("memory.h" HAVE_MEMORY_H)
CHECK_INCLUDE_FILE("stdint.h" HAVE_STDINT_H)
CHECK_INCLUDE_FILE("stdlib.h" HAVE_STDLIB_H)
CHECK_INCLUDE_FILE("strings.h" HAVE_STRINGS_H)
CHECK_INCLUDE_FILE("string.h" HAVE_STRING_H)
CHECK_INCLUDE_FILE("sys/stat.h" HAVE_SYS_STAT_H)
CHECK_INCLUDE_FILE("sys/types.h" HAVE_SYS_TYPES_H)
CHECK_INCLUDE_FILE("unistd.h" HAVE_UNISTD_H)

# Checking: data types
CHECK_TYPE("struct termios2" "<linux/termios.h>" HAVE_STRUCT_TERMIOS2)
CHECK_TYPE("struct termiox" "<linux/termios.h>" HAVE_STRUCT_TERMIOX)
CHECK_TYPE("struct serial_struct" "<linux/serial.h>" HAVE_STRUCT_SERIAL_STRUCT)

CHECK_MEMBER("struct termios2" "c_ispeed" "<linux/termios.h>" HAVE_STRUCT_TERMIOS2_C_ISPEED)
CHECK_MEMBER("struct termios2" "c_ospeed" "<linux/termios.h>" HAVE_STRUCT_TERMIOS2_C_OSPEED)
CHECK_MEMBER("struct termios" "c_ispeed" "<linux/termios.h>" HAVE_STRUCT_TERMIOS_C_ISPEED)
CHECK_MEMBER("struct termios" "c_ospeed" "<linux/termios.h>" HAVE_STRUCT_TERMIOS_C_OSPEED)

TYPE_SIZE_T(SIZE_T)

# Checking: declaration
CHECK_DECL("BOTHER" "<linux/termios.h>" HAVE_DECL_BOTHER)

# Checking: functions
CHECK_FUNCTION_EXISTS("clock_gettime" HAVE_CLOCK_GETTIME)
CHECK_FUNCTION_EXISTS("realpath" HAVE_REALPATH)

# Checking: headers
HEADER_STDC(STDC_HEADERS)

# Configuration: SP_CV_VISIBILITY_CONTROL
set(SP_SAVED_CFLAGS ${CMAKE_C_FLAGS})
if(MSVC)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -WX")
else()
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Werror")
endif()
CHECK_C_SOURCE_COMPILES(
    "__attribute__((visibility(\"hidden\"))) void foo(void) {} int main(void) { return 0; }"
    HAVE_ATTRIBUTE)
if(${HAVE_ATTRIBUTE})
    set(SP_CV_VISIBILITY_CONTROL "attribute")
else()
    CHECK_C_SOURCE_COMPILES(
        "__declspec(dllexport) void foo(void) {} int main(void) { return 0; }"
        HAVE_DECLSPEC)
    if(${HAVE_DECLSPEC})
        set(SP_CV_VISIBILITY_CONTROL "declspec")
    else()
        set(SP_CV_VISIBILITY_CONTROL "none")
    endif()
endif()
set(CMAKE_C_FLAGS ${SP_SAVED_CFLAGS})

# Configuration: SP_API, SP_PRIV
if(SP_CV_VISIBILITY_CONTROL MATCHES "attribute")
    set(SP_API "__attribute__((visibility(\"default\")))")
    set(SP_PRIV "__attribute__((visibility(\"hidden\")))")
elseif(SP_CV_VISIBILITY_CONTROL MATCHES "declspec")
    if(${BUILD_SHARED_LIBS})
        set(SP_API "__declspec(dllexport)")
        set(SP_PRIV " ")
    else()
        set(SP_API " ")
        set(SP_PRIV " ")
    endif()
else()
    set(SP_API " ")
    set(SP_PRIV " ")
endif()

# Configuration: NO_ENUMERATION, NO_PORT_METADATA
if(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Linux|Darwin|Windows|FreeBSD")
    set(NO_ENUMERATION 1)
    set(NO_PORT_METADATA 1)
endif()

# Checking: Large file support
SYS_LARGEFILE(_FILE_OFFSET_BITS _LARGE_FILES)

# Generate config.h from config.h.cmake with checking results and configurations
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.h.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/config.h)
include_directories(${CMAKE_CURRENT_BINARY_DIR})

# Set project sources list
set(SP_SRCS
    "${CMAKE_CURRENT_SOURCE_DIR}/serialport.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/timing.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/libserialport_internal.h")

set(SP_HEADERS "${CMAKE_CURRENT_SOURCE_DIR}/libserialport.h")

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(SP_SRCS ${SP_SRCS}
        "${CMAKE_CURRENT_SOURCE_DIR}/linux.c"
        "${CMAKE_CURRENT_SOURCE_DIR}/linux_termios.c"
        "${CMAKE_CURRENT_SOURCE_DIR}/linux_termios.h")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    set(SP_SRCS ${SP_SRCS}
        "${CMAKE_CURRENT_SOURCE_DIR}/windows.c")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(SP_SRCS ${SP_SRCS}
        "${CMAKE_CURRENT_SOURCE_DIR}/macosx.c")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    set(SP_SRCS ${SP_SRCS}
        "${CMAKE_CURRENT_SOURCE_DIR}/freebsd.c")
else()
    message(FATAL_ERROR "Unexpected host operating system")
endif()

# Configure package install prefix
set(prefix ${CMAKE_INSTALL_PREFIX})
set(exec_prefix ${prefix})
set(bindir ${prefix}/bin)
set(libdir ${prefix}/lib)
set(includedir ${prefix}/include)

set(pcdir ${libdir}/pkgconfig)
set(exportdir ${libdir}/cmake)

# Configure libserialport.pc
if (UNIX)
    set(PC_FILE ${CMAKE_CURRENT_BINARY_DIR}/libserialport.pc)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/libserialport.pc.in ${PC_FILE} @ONLY)
    install(FILES ${PC_FILE} DESTINATION ${pcdir})
endif()

# Compile static library
set(SP_STATIC_LIB ${PROJECT_NAME}-static)
add_library(${SP_STATIC_LIB} STATIC ${SP_SRCS})
set_target_properties(${SP_STATIC_LIB} PROPERTIES
    PREFIX ""
    OUTPUT_NAME ${PROJECT_NAME}
    VERSION "${${PROJECT_NAME}_VERSION}"
    SOVERSION "${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}"
    )

# Deploy static library
set(SP_STATIC_LIB_TARGET ${SP_STATIC_LIB}-targets)
install(TARGETS ${SP_STATIC_LIB} EXPORT ${SP_STATIC_LIB_TARGET} DESTINATION ${libdir})
install(EXPORT ${SP_STATIC_LIB_TARGET} DESTINATION ${exportdir})

# Compile shared library
set(SP_SHARED_LIB ${PROJECT_NAME}-shared)
add_library(${SP_SHARED_LIB} SHARED ${SP_SRCS})
set_target_properties(${SP_SHARED_LIB} PROPERTIES
    PREFIX ""
    OUTPUT_NAME ${PROJECT_NAME}
    VERSION "${${PROJECT_NAME}_VERSION}"
    SOVERSION "${${PROJECT_NAME}_VERSION_MAJOR}.${${PROJECT_NAME}_VERSION_MINOR}"
    )

if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    target_link_libraries(${SP_SHARED_LIB} setupapi)
endif()

# Deploy shared library
set(SP_SHARED_LIB_TARGET ${SP_SHARED_LIB}-targets)
install(TARGETS ${SP_SHARED_LIB} EXPORT ${SP_SHARED_LIB_TARGET}
    RUNTIME DESTINATION ${bindir}
    LIBRARY DESTINATION ${libdir}
    )
install(EXPORT ${SP_SHARED_LIB_TARGET} DESTINATION ${exportdir})

# Deploy public headers
install(FILES ${SP_HEADERS} DESTINATION ${includedir})

# Configure cmake config file
file(RELATIVE_PATH REL_INCLUDE_DIR ${exportdir} ${includedir})
set(SP_INCLUDE_DIRS "\${LIBSERIALPORT_CMAKE_DIR}/${REL_INCLUDE_DIR}")

set(CMAKE_CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/libserialport-config.cmake)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/libserialport-config.cmake.in
    ${CMAKE_CONFIG_FILE} @ONLY)
install(FILES ${CMAKE_CONFIG_FILE} DESTINATION ${exportdir})

# Configure uninstall target
add_custom_target(uninstall ${CMAKE_COMMAND} -P ${CMAKE_MODULE_PATH}/CMakeUninstall.cmake)
