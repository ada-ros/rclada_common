function(ada_begin_package)
    message(STATUS " ")
    message(STATUS "${PROJECT_NAME} version ${PROJECT_VERSION}")
endfunction()


function(ada_end_package)
    message(STATUS "Exporting Ada ${PROJECT_NAME} from ${PROJECT_SOURCE_DIR}")

    # Find the *Config.in, *-config.in file, to pass along to ament_package() once configured
    file(GLOB_RECURSE _conf_file_in
            "${PROJECT_SOURCE_DIR}/${PROJECT_NAME}*onfig.cmake.in")

    if(NOT "${_conf_file_in}" STREQUAL "")
        message(STATUS "Processing ${_conf_file_in} as part of ${PROJECT_NAME} closing config")
        list(APPEND ${PROJECT_NAME}_CONFIG_EXTRAS ${_conf_file_in}) # The file is configured by ament_package()
    endif()

    find_package(ament_cmake REQUIRED)

    # Export the location of installed project files. This allows clients of rclada
    # to be edited after sourcing the setup.bash. For development of rclada itself,
    # this is not enough as this only points to installed headers. Use printenv_ada
    # AFTER sourcing setup.bash in that case.
    # NOTE: enabling this one is breaking package isolation, as any existing Ada 
    # package will be reachable after sourcing, no matter if it is a dependency or
    # not. For that reason, we leave this functionality as a convenience during for
    # development with GNAT Studio that can be activated on request
    if($ENV{RCLADA_EXPORT}) 
        ament_environment_hooks("${ADA_RESOURCE_DIR}/ada_env_install.dsv.in")
    endif()

    # When we close the Ada context we include at least the AdaConfig file that
    # builds the list of dirs for GPR, besides any other info the package exports
    ament_package(CONFIG_EXTRAS ${ADA_RESOURCE_DIR}/AdaConfig.cmake.in)

endfunction()