message(STATUS "Ada CMake extensions loaded from ${PROJECT_NAME} v${PROJECT_VERSION}")

function(ada_begin_package)
    message(STATUS " ")
    message(STATUS "${PROJECT_NAME} version ${PROJECT_VERSION}")
endfunction()

function(ada_add_executables GPR_TARGET SRCDIR OUTDIR #[[ targets ]])
# SRCFOLDER: the path to the GPR-containing project
# OUTFOLDER: relative path in SRCFOLDER where the real targets are built
# TARGETS: each executable name built by this project, without path

    ada_priv_expand_srcdir(_srcdir ${SRCDIR})

    # message(STATUS "XXXXXXXXXXXXXXXXXX GPRS: ${ADA_GPR_DIRS}")

    # the target that builds the Ada project and true Ada executables
    add_custom_target(
            ${GPR_TARGET}
            # ALL
            COMMAND_EXPAND_LISTS
            WORKING_DIRECTORY ${_srcdir}
            COMMAND gprbuild
                "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
                -p -j0
                --relocate-build-tree=${PROJECT_BINARY_DIR}

            COMMENT "${GPR_TARGET} Ada project build target created"
    )

    # Fake targets (to be indexed by autocompletion) and its replacement
    foreach(TARGET ${ARGN})
        # Fake exec to be able to install an executable target
        add_executable(${TARGET} ${ADA_RESOURCE_DIR}/rclada_fake_target.c)

        # Copy each executable in place
        add_custom_command(
                TARGET ${TARGET}
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E remove -f ${PROJECT_BINARY_DIR}/${TARGET}
                COMMAND ${CMAKE_COMMAND} -E copy
                    ${PROJECT_BINARY_DIR}/${OUTDIR}/${TARGET}
                    ${PROJECT_BINARY_DIR}/${TARGET}
                COMMENT "${TARGET} Ada binary put in place"
        )

        # ensure the Ada project is built before so the post-command works
        # make the copy in place after building
        add_dependencies(${TARGET} ${GPR_TARGET})

        # must go into "lib" or ros bash completion misses it (duh)
        install(TARGETS     ${TARGET}
                DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/${PROJECT_NAME}/)
    endforeach()

endfunction()


function(ada_add_library TARGET SRCDIR GPRFILE)
    ada_priv_expand_srcdir(_srcdir ${SRCDIR})

    add_custom_target(${TARGET}
            ALL
            COMMAND_EXPAND_LISTS

            COMMENT "Building ${GPRFILE} from ${SRCDIR}"
            # build
            COMMAND gprbuild
                -p -j0 -P ${_srcdir}/${GPRFILE}
               "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
                --relocate-build-tree=${PROJECT_BINARY_DIR}

            COMMENT "Installing ${GPRFILE} in ${CMAKE_INSTALL_PREFIX}"
            # install
            COMMAND gprinstall
                -f -m -p -P ${_srcdir}/${GPRFILE}
                "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
                --relocate-build-tree=${PROJECT_BINARY_DIR}
                --prefix=${CMAKE_INSTALL_PREFIX}

            COMMENT "${GPRFILE} (${_srcdir}) installation complete"
            )
endfunction()


function(ada_end_package)
    message(STATUS "Exporting ${PROJECT_NAME} from ${PROJECT_SOURCE_DIR}")

#    set(_cmake_version_file ${PROJECT_NAME}ConfigVersion.cmake)
#    configure_file(
#            cmake/${_cmake_version_file}.in
#            ${PROJECT_BINARY_DIR}/${_cmake_version_file})
#
    file(GLOB_RECURSE _conf_file_in
            "${PROJECT_SOURCE_DIR}/${PROJECT_NAME}*onfig.cmake.in")

    if("${_conf_file_in}" STREQUAL "" OR "${_conf_file_in}" MATCHES ".*[;].*")
        set(_conf_file_in ${ADA_RESOURCE_DIR}/DefaultConfig.cmake.in)
        message(STATUS "Using default Ada DefaultConfig.cmake.in since package doesn't provide one")
    endif()

    file(MAKE_DIRECTORY ${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/cmake)

    # The configuration file, at a minimum, should propagate the
    # ADA_GPR_DIRS and ADA_GPRIMPORT_DIRS of the package
    # (which are prepared in the ada_begin_package)
    set(_conf_file ${PROJECT_NAME}Config.cmake)
    configure_file(
            ${_conf_file_in}
            ${PROJECT_BINARY_DIR}/${_conf_file}
            @ONLY)
    install(FILES
            ${PROJECT_BINARY_DIR}/${_conf_file}
            DESTINATION ${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/cmake)

    # Version is dealt with with default CMake helpers
    include(CMakePackageConfigHelpers)
    write_basic_package_version_file(
            ${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}ConfigVersion.cmake
            COMPATIBILITY SameMajorVersion)
#
#    install(FILES
#            ${PROJECT_BINARY_DIR}/${_cmake_conf_file}
#            ${PROJECT_BINARY_DIR}/${_cmake_version_file}
#            DESTINATION share/${PROJECT_NAME}/cmake)
#
    install(FILES package.xml DESTINATION share/${PROJECT_NAME})
endfunction()


function (ada_find_package_include_dir RETURN PACKAGE_DIR)
    # Just three up
    get_filename_component(_dir ${PACKAGE_DIR} DIRECTORY)
    get_filename_component(_dir ${_dir} DIRECTORY)
    get_filename_component(_dir ${_dir} DIRECTORY)
    set(${RETURN} ${_dir}/include PARENT_SCOPE)
endfunction()


function (ada_find_package_library_dir RETURN PACKAGE_DIR)
    # Just three up
    get_filename_component(_dir ${PACKAGE_DIR} DIRECTORY)
    get_filename_component(_dir ${_dir} DIRECTORY)
    get_filename_component(_dir ${_dir} DIRECTORY)
    set(${RETURN} ${_dir}/lib PARENT_SCOPE)
endfunction()


function(ada_generate_binding TARGET SRCDIR GPRFILE INCLUDE #[[ ARGN ]])
    # Generate corresponding Ada specs, compile it and deploy it
    # TARGET is the desired target name to depend on this
    # SRCDIR is a preexisting ada project prepared to compile in "gen" the generated specs
    # INCLUDE, list (;-separated) of folders to add with -I
    # ARGN, headers to generate

    ada_priv_expand_srcdir(_srcdir ${SRCDIR})

    set(_gen_flag ${_srcdir}/gen/generated)

    add_custom_target(${TARGET}
        ALL
        DEPENDS ${_gen_flag}
        COMMAND_EXPAND_LISTS

        COMMENT "Building ${GPRFILE} Ada project"
        COMMAND gprbuild
            -p -j0 -P ${_srcdir}/${GPRFILE}
            "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
            --relocate-build-tree=${PROJECT_BINARY_DIR}
            -cargs "$<$<BOOL:${INCLUDE}>:-I$<JOIN:${INCLUDE},;-I>>"

        # This might need to be separated into a custom script, since it now runs at build time
        COMMENT "Installing ${GPRFILE} Ada project"
        COMMAND gprinstall
            -f -m -p -P ${_srcdir}/${GPRFILE}
            "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
            --relocate-build-tree=${PROJECT_BINARY_DIR}
            --prefix=${CMAKE_INSTALL_PREFIX}

        COMMENT "${GPRFILE} (${_srcdir}}) installed"
    )

    # Generate autobinding
    add_custom_command(
            OUTPUT ${_gen_flag}

            COMMAND_EXPAND_LISTS
            WORKING_DIRECTORY ${_srcdir}/gen

            COMMENT "Generating autobinding for project ${GPRFILE}..."
            COMMAND g++
            -fdump-ada-spec-slim
            -C
            "$<$<BOOL:${INCLUDE}>:-I$<JOIN:${INCLUDE},;-I>>"
            ${ARGN}

            COMMAND touch ${_gen_flag}
    )
endfunction()


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

function(ada_priv_expand_srcdir RESULT SRCDIR)
    if(IS_ABSOLUTE ${SRCDIR})
        set(${RESULT} ${SRCDIR} PARENT_SCOPE)
    else()
        set(${RESULT} ${PROJECT_SOURCE_DIR}/${SRCDIR} PARENT_SCOPE)
    endif()
endfunction()
