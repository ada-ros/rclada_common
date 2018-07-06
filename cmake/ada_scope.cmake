function(ada_begin_package)
    message(STATUS " ")
    message(STATUS "${PROJECT_NAME} version ${PROJECT_VERSION}")
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

    #file(MAKE_DIRECTORY ${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/cmake)

    # Being an ament_cmake package, we prepare a file for inclusion by ament_package
    set(_conf_file ${PROJECT_NAME}-extras.cmake)
    configure_file(
            ${_conf_file_in}
            ${PROJECT_BINARY_DIR}/${_conf_file}
            @ONLY)

    ament_package(CONFIG_EXTRAS ${PROJECT_BINARY_DIR}/${_conf_file})

    # Remainder is now taken care of by ament

    # Version is dealt with with default CMake helpers
    #include(CMakePackageConfigHelpers)
    #write_basic_package_version_file(
    #        ${CMAKE_INSTALL_PREFIX}/share/${PROJECT_NAME}/cmake/${PROJECT_NAME}ConfigVersion.cmake
    #        COMPATIBILITY SameMajorVersion)
#
#    install(FILES
#            ${PROJECT_BINARY_DIR}/${_cmake_conf_file}
#            ${PROJECT_BINARY_DIR}/${_cmake_version_file}
#            DESTINATION share/${PROJECT_NAME}/cmake)
#
    #install(FILES package.xml DESTINATION share/${PROJECT_NAME})
endfunction()