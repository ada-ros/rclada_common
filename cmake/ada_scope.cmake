function(ada_begin_package)
    message(STATUS " ")
    message(STATUS "${PROJECT_NAME} version ${PROJECT_VERSION}")
endfunction()


function(ada_end_package)
    message(STATUS "Exporting ${PROJECT_NAME} from ${PROJECT_SOURCE_DIR}")

    file(GLOB_RECURSE _conf_file_in
            "${PROJECT_SOURCE_DIR}/${PROJECT_NAME}*onfig.cmake.in")

    if("${_conf_file_in}" STREQUAL "" OR "${_conf_file_in}" MATCHES ".*[;].*")
        set(_conf_file_in ${ADA_RESOURCE_DIR}/DefaultConfig.cmake.in)
        message(STATUS "Using default Ada DefaultConfig.cmake.in since package doesn't provide one")
    endif()

    # Being an ament_cmake package, we prepare a file for inclusion by ament_package
    set(_conf_file ${PROJECT_NAME}-extras.cmake)
    configure_file(
            ${_conf_file_in}
            ${PROJECT_BINARY_DIR}/${_conf_file}
            @ONLY)

    ament_package(CONFIG_EXTRAS ${PROJECT_BINARY_DIR}/${_conf_file})

endfunction()