message(STATUS "Ada CMake extensions loaded from ${PROJECT_NAME} v${PROJECT_VERSION}")

function(ada_begin_package)
    message(STATUS " ")
    message(STATUS "${PROJECT_NAME} version ${PROJECT_VERSION}")
endfunction()

function(ada_add_executables GPR_TARGET SRCFOLDER OUTDIR #[[ targets ]])
# SRCFOLDER: the path to the GPR-containing project
# OUTFOLDER: relative path in SRCFOLDER where the real targets are built
# TARGETS: each executable name built by this project, without path

    get_filename_component(_basename ${SRCFOLDER} NAME)
    set(_workspace ${PROJECT_BINARY_DIR}/${_basename})

    # working space:
    file(COPY ${SRCFOLDER}
            DESTINATION ${PROJECT_BINARY_DIR})

    # the target that builds the Ada project
    add_custom_target(
            ${GPR_TARGET}
            # ALL
            WORKING_DIRECTORY ${_workspace}

            COMMAND gprbuild
                "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
                -p -j0

            COMMENT "${GPR_TARGET} Ada project build target created"
    )

    foreach(TARGET ${ARGN})
        # Fake exec to be able to install an executable target
        add_executable(${TARGET} ${ADA_RESOURCE_DIR}/rclada_fake_target.c)

        # Copy each executable in place
        add_custom_command(
                TARGET ${TARGET}
                POST_BUILD
                WORKING_DIRECTORY ${_workspace}
                COMMAND ${CMAKE_COMMAND} -E remove -f ${PROJECT_BINARY_DIR}/${TARGET}
                COMMAND ${CMAKE_COMMAND} -E copy
                    ${_workspace}/${OUTDIR}/${TARGET}
                    ${PROJECT_BINARY_DIR}/${TARGET}
                COMMENT "${TARGET} Ada binary put in place"
        )

        # ensure the Ada project is built before so the post-command works
        # make the copy in place after building
        add_dependencies(${TARGET} ${GPR_TARGET})

        # must go into "lib" or ros bash completion misses it (duh)
        install(TARGETS ${TARGET} DESTINATION lib/${PROJECT_NAME}/)
    endforeach()

endfunction()


function(ada_add_library TARGET SRCDIR GPRFILE)
    add_custom_target(${TARGET}
            ALL
            COMMAND_EXPAND_LISTS

            COMMENT "Building ${GPRFILE} from ${SRCDIR}"
            # build
            COMMAND gprbuild
                -p -j0 -P ${PROJECT_SOURCE_DIR}/${SRCDIR}/${GPRFILE}
               "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
                --relocate-build-tree=${PROJECT_BINARY_DIR}

            COMMENT "Installing ${GPRFILE} in ${CMAKE_INSTALL_PREFIX}"
            # install
            COMMAND gprinstall
                -f -m -p -P ${PROJECT_SOURCE_DIR}/${SRCDIR}/${GPRFILE}
                "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
                --relocate-build-tree=${PROJECT_BINARY_DIR}
                --prefix=${CMAKE_INSTALL_PREFIX}

            COMMENT "${GPRFILE} (${SRCDIR}) installation complete"
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
    get_filename_component(_conf_file ${_conf_file_in} NAME_WE)
    configure_file(
            ${_conf_file_in}
            ${PROJECT_BINARY_DIR}/${_conf_file}.cmake
            @ONLY)
    install(FILES
            ${PROJECT_BINARY_DIR}/${_conf_file}.cmake
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

    # Compile everything and install
    # This must run everytime so changes are detected

    set(_gen_flag ${SRCDIR}/gen/generated)

    add_custom_target(${TARGET}
        ALL
        COMMAND_EXPAND_LISTS

        DEPENDS ${_gen_flag}

        COMMENT "Building ${GPRFILE} Ada project"
        COMMAND gprbuild
            -p -j0 -P ${SRCDIR}/${GPRFILE}
            "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
            --relocate-build-tree=${PROJECT_BINARY_DIR}

        # This might need to be separated into a custom script, since it now runs at build time
        COMMENT "Installing ${GPRFILE} Ada project"
        COMMAND gprinstall
            -f -m -p -P ${SRCDIR}/${GPRFILE}
            "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
            --relocate-build-tree=${PROJECT_BINARY_DIR}
            --prefix=${CMAKE_INSTALL_PREFIX}

        COMMENT "${GPRFILE} (${SRCDIR}) installed"
        )

    # Generate autobinding
    add_custom_command(
            OUTPUT ${_gen_flag}

            WORKING_DIRECTORY ${SRCDIR}/gen

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

    foreach(_lib ${ARGN})
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

        configure_file(
                ${ADA_RESOURCE_DIR}/external_c_lib.gpr.in
                ${CMAKE_INSTALL_PREFIX}/share/gprimport/clib_${_ext_safe_name}.gpr)
    endforeach()
endfunction()

# Make foreign msgs usable from the ada side, manually
function(ada_import_msgs PKG_NAME)

    if(${PKG_NAME} STREQUAL ${PROJECT_NAME})
        message("Generating Ada binding for current package messages")
        set(_depends
                ${CMAKE_INSTALL_PREFIX}/lib/lib${PROJECT_NAME}__rosidl_typesupport_c.so
                ${CMAKE_INSTALL_PREFIX}/lib/lib${PROJECT_NAME}__rosidl_typesupport_introspection_c.so)
        ada_import_c_libraries(${_depends})
        set(_pkg_lib_path ${CMAKE_INSTALL_PREFIX}/lib)
        set(_pkg_include_path ${CMAKE_INSTALL_PREFIX}/include)
    else()
        message("Generating Ada binding for installed package ${PKG_NAME}")
        find_package(${PKG_NAME} REQUIRED)
        ada_import_c_libraries(${${PKG_NAME}_LIBRARIES})
        ada_find_package_library_dir(_pkg_lib_path ${${PKG_NAME}_DIR})
        ada_find_package_include_dir(_pkg_include_path ${${PKG_NAME}_DIR})
    endif()

    set(_pkg_name ${PKG_NAME})

    configure_file(
            ${ADA_RESOURCE_DIR}/msg_import.gpr.in
            ${CMAKE_INSTALL_PREFIX}/share/gprimport/ros2_typesupport_${PKG_NAME}.gpr
    )
endfunction()