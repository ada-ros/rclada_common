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
        string(REPLACE lib "" _ext_lib_name ${_ext_lib_name})
        string(REPLACE "__" "_" _ext_safe_name ${_ext_lib_name})

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
function(ada_import_interfaces PKG_NAME)

    if("${PKG_NAME}" STREQUAL "${PROJECT_NAME}")
        message(STATUS "Generating Ada binding for current package messages")
        set(_depends
                ${CMAKE_INSTALL_PREFIX}/lib/lib${PROJECT_NAME}__rosidl_typesupport_c.so
                ${CMAKE_INSTALL_PREFIX}/lib/lib${PROJECT_NAME}__rosidl_typesupport_introspection_c.so)
        ada_import_c_libraries(${_depends})
        set(_pkg_lib_path ${CMAKE_INSTALL_PREFIX}/lib)
        set(_pkg_include_path ${CMAKE_INSTALL_PREFIX}/include)
    else()
        message(STATUS "Generating Ada binding for installed package ${PKG_NAME}")
        find_package(${PKG_NAME} REQUIRED)
        ada_import_c_libraries(${${PKG_NAME}_LIBRARIES})
        ada_find_package_library_dir(_pkg_lib_path ${${PKG_NAME}_DIR})
        ada_find_package_include_dir(_pkg_include_path ${${PKG_NAME}_DIR})
        # Since Foxy, for some reason the introspection variant is not provided
        # with the previous _LIBRARIES variable. THE FOLLOWING SHOULD ADD IT
        # BUT IT'S BROKEN BECAUSE I CANNOT LOCATE THE LIBDIR WHERE ALL LIBS
        # FSCKING ARE. I HATE CMAKE.
        ada_import_c_libraries(${_pkg_lib_path}/lib${PKG_NAME}__rosidl_typesupport_introspection_c.so)
    endif()

    set(_pkg_name ${PKG_NAME})
    set(_gpr ros2_typesupport_${PKG_NAME}.gpr)

    configure_file(
            ${ADA_RESOURCE_DIR}/msg_import.gpr.in
            ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gpr})
endfunction()
