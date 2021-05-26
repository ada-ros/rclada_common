# Import a headers-only library, or source files that do not require library linking
function(ada_import_c_headers LIBNAME INCLUDE)
    # LIBNAME: clib_libname.gpr
    # INCLUDE: single include path

    set(_ext_safe_name   ${LIBNAME})
    set(_ext_lib_include ${INCLUDE})

    set(_gpr clib_${_ext_safe_name}.gpr)

    configure_file(
            ${ADA_RESOURCE_DIR}/external_c_headers.gpr.in
            ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gpr})
endfunction()

# Import an installed C library
function(ada_import_c_libraries #[[ ARGN ]])
    # Expects a list of absolute paths to libs
    # One GPR file per path will be generated

    list(REMOVE_DUPLICATES ARGN)
    list(SORT ARGN)

    foreach(_lib ${ARGN})
        message(STATUS "Importing C lib for Ada: ${_lib}")

        if (NOT (${_lib} MATCHES ".*[.]so" OR ${_lib} MATCHES ".*[.]a"))
            if (NOT (${_lib} MATCHES ".*::.*")) # No need to warn about the modern CMake alternate notation
                message(STATUS "!!! !!! Bad C library: ${_lib}")
            endif()
            continue()
        endif()

        # Obtain name
        get_filename_component(_ext_lib_name ${_lib} NAME_WE)
        # Remove leading lib from libBLAH
        string(SUBSTRING ${_ext_lib_name} 3 -1 _ext_lib_name)
        string(REPLACE "__" "_" _ext_safe_name ${_ext_lib_name})
        string(REPLACE "-" "_" _ext_safe_name ${_ext_safe_name})

        message(STATUS "Generating GPR clib_${_ext_safe_name}.gpr for LIB ${_lib}")

        # Obtain path
        get_filename_component(_ext_lib_path ${_lib} DIRECTORY)

        # Sibling include
        get_filename_component(_ext_lib_include ${_ext_lib_path} DIRECTORY)
        set(_ext_lib_include ${_ext_lib_include}/include)

        set(_gpr clib_${_ext_safe_name}.gpr)

        # Verify that project hasn't been already imported (gprbuild will complain otherwise)
        unset(_found)
        unset(_found CACHE)
        find_file(_found ${_gpr}
                ${ADA_GPR_DIRS})
        if(NOT "${_found}" MATCHES ".*-NOTFOUND")
            message(STATUS "C importing to Ada: skipping found ${_found}")
            continue()
        endif()

        configure_file(
                ${ADA_RESOURCE_DIR}/external_c_lib.gpr.in
                ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gpr})
    endforeach()
endfunction()

# Make foreign msgs usable from the ada side, manually
function(ada_import_interfaces #[[ ARGN ]])

    set(PKG_NAMES ${ARGN})

    find_package(rosidl_generator_ada REQUIRED) # import the generator

    # Depending on whether we are importing our own messages, we must add this dependency or not.
    # Something is amiss here because if we aren't generating messages, a circularity appears, when
    # it seems it should be the other way around.

    if (${PROJECT_NAME} IN_LIST PKG_NAMES)
        set(_depends ${PROJECT_NAME}) # depend on the package C messages, which are under the package name target
    endif()

    # Add a target for the generator with the arguments

    add_custom_command(
        OUTPUT ada_ifaces.stamp # Never created, so regenerated every time until I do smthg about this
        COMMAND echo "Running Ada generator for ${PKG_NAMES}"
        COMMAND ${ADA_GENERATOR}
            "--import-pkg=$<JOIN:${PKG_NAMES},,>"
            "--from-pkg=${PROJECT_NAME}"
            "--current-src=${PROJECT_SOURCE_DIR}"
        DEPENDS ${_depends}
        VERBATIM
    )

    # Avoid multiple generations by grouping the generator command under a common custom target
    add_custom_target(ada_interfaces_internal ALL
        COMMENT "Custom target for ADA GENERATOR"
        DEPENDS ada_ifaces.stamp
        VERBATIM
    )

    ada_add_library(
        ada_interfaces_gpr
        "${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_ada"
        "ros2_interfaces_${PROJECT_NAME}")
    add_dependencies(ada_interfaces_gpr ada_interfaces_internal)

endfunction()
