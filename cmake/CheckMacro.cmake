macro(CHECK_TYPE TYPE INCLUDE_PATH VAR)
    CHECK_C_SOURCE_COMPILES(
        "#include ${INCLUDE_PATH}
        int main(void) { ${TYPE} tmp; return 0; }"
        ${VAR})
endmacro()

macro(CHECK_MEMBER TYPE MEMBER INCLUDE_PATH VAR)
    CHECK_C_SOURCE_COMPILES(
        "#include ${INCLUDE_PATH}
        int main(void) { ((${TYPE}*)0)->${MEMBER}; return 0; }"
        ${VAR})
endmacro()

macro(CHECK_DECL DEF INCLUDE_PATH VAR)
    CHECK_C_SOURCE_COMPILES(
        "#include ${INCLUDE_PATH}
        int main(void) {
        #ifndef ${DEF}
        #error Symbol undefined
        #endif
        return 0; }"
        ${VAR})
endmacro()

macro(TYPE_SIZE_T VAR)
    CHECK_C_SOURCE_COMPILES(
        "#include <sys/types.h>
        int main(void) { size_t test; return 0; }"
        HAVE_SIZE_T)
    if(NOT ${HAVE_SIZE_T})
        set(SIZE_T "unsigned int")
    endif()
endmacro()

macro(HEADER_STDC VAR)
    CHECK_C_SOURCE_COMPILES(
        "#include <stdlib.h>
        #include <stdarg.h>
        #include <string.h>
        #include <float.h>
        int main(void) { return 0; }"
        ${VAR})
endmacro()

macro(SYS_LARGEFILE _FILE_OFFSET_BITS _LARGE_FILES)
    include(CMakePushCheckState)

    # Push check state (reset all definitions)
    CMAKE_PUSH_CHECK_STATE(RESET)

    # Performing test
    if((NOT ${_FILE_OFFSET_BITS}) AND (NOT ${_LARGE_FILES}))

        # Test macro for large file support
        macro(TRY_LFS_COMPILE RESULT)
            CHECK_C_SOURCE_COMPILES("
                #include <sys/types.h>
                #define LARGE_OFF_T (((off_t)1 << 62) - 1 + ((off_t)1 << 62))
                int off_t_is_large[(LARGE_OFF_T % 2147483629 == 721 &&
                                    LARGE_OFF_T % 2147483647 == 1)
                                       ? 1
                                       : -1];
                int main() { return 0; }
                " ${RESULT})
        endmacro()

        # Test native LFS support
        TRY_LFS_COMPILE(LFS_NATIVE)

        # Test LFS support with setting _FILE_OFFSET_BITS to 64
        if(NOT LFS_NATIVE)
            set(CMAKE_REQUIRED_DEFINITIONS "-D_FILE_OFFSET_BITS=64")
            TRY_LFS_COMPILE(LFS_OFFT_64)
            if(${LFS_OFFT_64})
                set(_FILE_OFFSET_BITS 64)
            endif()
        endif()

        # Test LFS support with setting _LARGE_FILES to 1
        if((NOT LFS_NATIVE) AND (NOT LFS_OFFT_64))
            set(CMAKE_REQUIRED_DEFINITIONS "-D_LARGE_FILES=64")
            TRY_LFS_COMPILE(LFS_LARGE_FILES)
            if(${LFS_LARGE_FILES})
                set(_LARGE_FILES 1)
            endif()
        endif()

    endif()

    # Restore check state
    CMAKE_POP_CHECK_STATE()

endmacro()
