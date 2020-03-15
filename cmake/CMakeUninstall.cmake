# ---------------------------------------
# Uninstall files in install_manifest.txt
# ---------------------------------------

# Set manifest file path
set(MANIFEST "${CMAKE_CURRENT_BINARY_DIR}/install_manifest.txt")
if(NOT EXISTS ${MANIFEST})
    message(FATAL_ERROR "Cannot find install manifest: '${MANIFEST}'")
endif()

# Remove files in manifest
file(READ ${MANIFEST} files)
string(REGEX REPLACE "\n" ";" files ${files})
foreach(file ${files})

    # Remove both files and symbolic links
    if(EXISTS ${file} OR IS_SYMLINK ${file})

        # Show remove message
        if(IS_SYMLINK ${file})
            set(RM_TYPE "symbolic link")
        else()
            set(RM_TYPE "file")
        endif()

        message(STATUS "Removing ${RM_TYPE}: ${file}")

        # Remove the file or symbolic link
        exec_program(
            ${CMAKE_COMMAND} ARGS "-E remove ${file}"
            OUTPUT_VARIABLE stdout
            RETURN_VALUE result
            )

        if(NOT "${result}" STREQUAL 0)
            message(FATAL_ERROR "Failed to remove ${RM_TYPE}: ${file}")
        endif()

    else()
        MESSAGE(STATUS "File '${file}' does not exist.")
    endif()

endforeach(file)
