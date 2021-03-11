
function(ada_add_executables GPR_TARGET SRCDIR OUTDIR #[[ targets ]])
# No gpr file is passed as argument, only one must exist at SRCDIR
# GPR_TARGET: a target name
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