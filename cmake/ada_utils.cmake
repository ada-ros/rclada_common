# Deduct the include from the _DIR
function (ada_find_package_include_dir RETURN PACKAGE)
    find_package(${PACKAGE} REQUIRED)
    set(PACKAGE_DIR ${${PACKAGE}_DIR})

    # Just three up
    get_filename_component(_dir ${PACKAGE_DIR} DIRECTORY)
    get_filename_component(_dir ${_dir} DIRECTORY)
    get_filename_component(_dir ${_dir} DIRECTORY)
    set(${RETURN} ${_dir}/include/${PACKAGE} PARENT_SCOPE)
endfunction()

# Deduct the lib dir from the _DIR
function (ada_find_package_library_dir RETURN PACKAGE)
    find_package(${PACKAGE} REQUIRED)
    set(PACKAGE_DIR ${${PACKAGE}_DIR})

    # Just three up
    get_filename_component(_dir ${PACKAGE_DIR} DIRECTORY)
    get_filename_component(_dir ${_dir} DIRECTORY)
    get_filename_component(_dir ${_dir} DIRECTORY)
    set(${RETURN} ${_dir}/lib PARENT_SCOPE)
endfunction()

# Transform a relative path into the package srcdir into an absolute one
function(ada_priv_expand_srcdir RESULT SRCDIR)
    if(IS_ABSOLUTE ${SRCDIR})
        set(${RESULT} ${SRCDIR} PARENT_SCOPE)
    else()
        set(${RESULT} ${PROJECT_SOURCE_DIR}/${SRCDIR} PARENT_SCOPE)
    endif()
endfunction()

# Print all variables defined by a package
function(print_package_variables PACKAGE_NAME)
  get_cmake_property(_variableNames VARIABLES)
  list(SORT _variableNames)
  foreach(_variableName ${_variableNames})
    if(_variableName MATCHES "^${PACKAGE_NAME}_")
      message(STATUS "${_variableName}=${${_variableName}}")
    endif()
  endforeach()
endfunction()

# Function that finds all libraries necessary to link in a package
function(private_find_libs PACKAGE_NAME LIBS)
  find_package(${PACKAGE_NAME} REQUIRED)

  # Try to get library paths from TARGETS
  set(package_lib_paths "")
  if(${PACKAGE_NAME}_TARGETS)
    foreach(target ${${PACKAGE_NAME}_TARGETS})
      get_target_property(target_type ${target} TYPE)
      if(target_type STREQUAL "SHARED_LIBRARY" OR target_type STREQUAL "STATIC_LIBRARY")
        get_target_property(lib_path ${target} LOCATION)
        if(lib_path)
          list(APPEND package_lib_paths "${lib_path}")
        endif()
      endif()
    endforeach()
  endif()

  # Also try LIBRARIES
  if(${PACKAGE_NAME}_LIBRARIES)
    foreach(lib ${${PACKAGE_NAME}_LIBRARIES})
      if(TARGET ${lib})
        get_target_property(lib_path ${lib} LOCATION)
        if(lib_path)
          list(APPEND package_lib_paths "${lib_path}")
        endif()
      else()
        list(APPEND package_lib_paths "${lib}")
      endif()
    endforeach()
  endif()

  set(${LIBS} ${package_lib_paths} PARENT_SCOPE)
endfunction()