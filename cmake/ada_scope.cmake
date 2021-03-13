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

    # When we close the Ada context we include at least the AdaConfig file that 
    # builds the list of dirs for GPR, besides any other info the package exports
    ament_package(CONFIG_EXTRAS ${ADA_RESOURCE_DIR}/AdaConfig.cmake.in)

endfunction()