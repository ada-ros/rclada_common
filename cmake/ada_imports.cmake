# Import an installed C library
function(ada_import_c_libraries #[[ ARGN ]])
    # Expects a list of absolute paths to libs
    # One GPR file per path will be generated

    list(REMOVE_DUPLICATES ARGN)
    list(SORT ARGN)

    foreach(_lib ${ARGN})
        message(STATUS "Importing C lib for Ada: ${_lib}")

        if (NOT (${_lib} MATCHES ".*[.]so" OR ${_lib} MATCHES ".*[.]a"))
            message(STATUS "!!! !!! Bad C library: ${_lib}")
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

        #message("XXXXXXXXXXXXXX ${_ext_lib_name}")
        #message("XXXXXXXXXXXXXX ${_ext_lib_path}")

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
#                ${PROJECT_BINARY_DIR}/${_gpr})

#        install(FILES       ${PROJECT_BINARY_DIR}/${_gpr}
#                DESTINATION ${CMAKE_INSTALL_PREFIX}/share/gpr)
    endforeach()
endfunction()

# Make foreign msgs usable from the ada side, manually
function(ada_import_msgs PKG_NAME)

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
    endif()

    set(_pkg_name ${PKG_NAME})
    set(_gpr ros2_typesupport_${PKG_NAME}.gpr)

    configure_file(
            ${ADA_RESOURCE_DIR}/msg_import.gpr.in
            ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gpr})
            #${PROJECT_BINARY_DIR}/${_gpr})

    #install(FILES       ${PROJECT_BINARY_DIR}/${_gpr}
    #        DESTINATION ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gpr})
endfunction()