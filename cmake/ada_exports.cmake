
function(ada_add_executables TARGET SRCDIR OUTDIR #[[ targets ]])
# No gpr file is passed as argument, only one must exist at SRCDIR
# TARGET: a target name
# SRCFOLDER: the path to the GPR-containing project
# OUTFOLDER: relative path in SRCFOLDER where the real targets are built
# TARGETS: each executable name built by this project, without path

    ada_priv_expand_srcdir(_srcdir ${SRCDIR})

    # the target that builds the Ada project and true Ada executables
    add_custom_target(
            ${TARGET}
            ALL # Always, to ensure changes are propagated. At worst, gprbuild will do nothing
            COMMAND_EXPAND_LISTS
            WORKING_DIRECTORY ${_srcdir}
            COMMAND gprbuild
                "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
                -p -j0
                --relocate-build-tree=${PROJECT_BINARY_DIR}

            COMMENT "${TARGET} Ada project build target created"
    )

    # This target depends on any messages defined in this same package, if any
    if (TARGET ada_interfaces_gpr)
        add_dependencies(${TARGET} ada_interfaces_gpr)
    endif()

    # Install the execs produced by this project
    foreach(EXEC ${ARGN})
        # must go into "lib" or ros bash completion misses it (duh)
        install(PROGRAMS    ${PROJECT_BINARY_DIR}/${OUTDIR}/${EXEC}
                DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/${PROJECT_NAME}/)
    endforeach()

endfunction()

function(ada_add_library TARGET SRCDIR GPRFILE)
    ada_priv_expand_srcdir(_srcdir ${SRCDIR})

    add_custom_target(${TARGET}
            ALL
            COMMAND_EXPAND_LISTS

            COMMAND echo "Building ${GPRFILE} from ${SRCDIR}"
            # build
            COMMAND gprbuild
                -p -j0 -P ${_srcdir}/${GPRFILE}
                -aP ${CMAKE_INSTALL_PREFIX}/share/gpr       # needed if we are using exports from this same package
               "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"            # needed for exports in other packages
                --relocate-build-tree=${PROJECT_BINARY_DIR}
                -cargs -I/opt/ros/foxy/include              # SHOULD NOT BE NEEDED and it's not needed normally. Only
                                                            # the github actions fail without this (???)

            COMMAND echo "Installing ${GPRFILE} in ${CMAKE_INSTALL_PREFIX}"
            # install
            COMMAND gprinstall
                --install-name=${TARGET}
                -f -m -p -P ${_srcdir}/${GPRFILE}
                -aP ${CMAKE_INSTALL_PREFIX}/share/gpr       # needed if we are using exports from this same package
               "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"            # needed for exports in other packages
                --relocate-build-tree=${PROJECT_BINARY_DIR}
                --prefix=${CMAKE_INSTALL_PREFIX}

            COMMAND echo "${GPRFILE} installation complete at ${_srcdir}"
            )

    # This target depends on any messages defined in this same package, if any
    if (TARGET ada_interfaces_gpr)
        message(STATUS "Ada lib DEPEND: ${TARGET} --> ada_interfaces_gpr")
        add_dependencies(${TARGET} ada_interfaces_gpr)
    else()
        message(STATUS "Ada lib DEPEND: ${TARGET} --> NONE")
    endif()
endfunction()


function(ada_generate_binding TARGET SRCDIR GPRFILE INCLUDE #[[ ARGN ]])
    # Generate corresponding Ada specs, compile it and deploy it
    # TARGET is the desired target name to depend on this
    # SRCDIR is a preexisting ada project prepared to compile in "gen" the generated specs
    # INCLUDE, list (;-separated) of folders to add with -I
    # ARGN, headers to generate

    ada_priv_expand_srcdir(_srcdir ${SRCDIR})

    set(_gen_flag ${_srcdir}/gen/generated)

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
            -I/opt/ros/foxy/include    # Needed for tf2 lib compilation
            ${ARGN}

            COMMAND touch ${_gen_flag}
    )

    # Build the Ada project, using the autogenerated part.
    # So this target depends on the previous custom command.
    add_custom_target(${TARGET}
        ALL
        DEPENDS ${_gen_flag} ${ARGN}
        COMMAND_EXPAND_LISTS

        COMMENT "Building ${GPRFILE} Ada project"
        COMMAND gprbuild
            -p -j0 -P ${_srcdir}/${GPRFILE}
            "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
            --relocate-build-tree=${PROJECT_BINARY_DIR}
            -cargs "$<$<BOOL:${INCLUDE}>:-I$<JOIN:${INCLUDE},;-I>>"
            -cargs -I/opt/ros/foxy/include              # SHOULD NOT BE NEEDED and it's not needed normally. Only
                                                            # the github actions fail without this (???)

        # This might need to be separated into a custom script, since it now runs at build time
        COMMENT "Installing ${GPRFILE} Ada project"
        COMMAND gprinstall
            -f -m -p -P ${_srcdir}/${GPRFILE}
            "-aP$<JOIN:${ADA_GPR_DIRS},;-aP>"
            --relocate-build-tree=${PROJECT_BINARY_DIR}
            --prefix=${CMAKE_INSTALL_PREFIX}

        COMMENT "${GPRFILE} (${_srcdir}}) installed"
    )

    # This target depends on any messages defined in this same package, if any
    # This is just in case; if no messages are imported this won't do anything.
    # Another option would be to document this ada_interfaces_gpr target and 
    # make the user explicitly depend on it. Not sure this speeds things up much.
    if (TARGET ada_interfaces_gpr)
        message(STATUS "Ada binding DEPEND: ${TARGET} --> ada_interfaces_gpr")
        add_dependencies(${TARGET} ada_interfaces_gpr)
    else()
        message(STATUS "Ada binding DEPEND: ${TARGET} --> NONE")
    endif()
endfunction()
