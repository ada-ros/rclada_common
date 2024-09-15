# Import a headers-only library, or source files that do not require library linking
# function(ada_import_c_headers LIBNAME INCLUDE)
#     # LIBNAME: clib_LIBNAME.gpr
#     # INCLUDE: single include path

#     set(_ext_safe_name   ${LIBNAME})
#     set(_ext_lib_include ${INCLUDE})

#     message(STATUS "Generating GPR clib_${_ext_safe_name}.gpr for INCLUDE ${_ext_lib_include}")

#     set(_gpr clib_${_ext_safe_name}.gpr)

#     configure_file(
#             ${ADA_RESOURCE_DIR}/external_c_headers.gpr.in
#             ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gpr})
# endfunction()

# Import headers only from a package
# function(ada_import_package_headers PACKAGE_NAME)
#   # Find the package
#   find_package(${PACKAGE_NAME} REQUIRED)

#   # Find its include dir
#   ada_find_package_include_dir(_include_dir ${PACKAGE_NAME})
#   ada_import_c_headers(${PACKAGE_NAME} ${_include_dir})
#   message(STATUS "Importing package headers for ${PACKAGE_NAME} at ${_include_dir}")
# endfunction()

# # Import an installed C library
# function(ada_import_c_libraries #[[ ARGN ]])
#     # Expects a list of absolute paths to libs
#     # One GPR file per path will be generated

#     list(REMOVE_DUPLICATES ARGN)
#     list(SORT ARGN)

#     foreach(_lib ${ARGN})
#         message(STATUS "Importing C lib for Ada: ${_lib}")

#         if (NOT (${_lib} MATCHES ".*[.]so" OR ${_lib} MATCHES ".*[.]a"))
#             if (NOT (${_lib} MATCHES ".*::.*")) # No need to warn about the modern CMake alternate notation
#                 message(STATUS "!!! !!! Bad C library: ${_lib}")
#             endif()
#             continue()
#         endif()

#         # Obtain name
#         get_filename_component(_ext_lib_name ${_lib} NAME_WE)
#         # Remove leading lib from libBLAH
#         string(SUBSTRING ${_ext_lib_name} 3 -1 _ext_lib_name)
#         string(REPLACE "__" "_" _ext_safe_name ${_ext_lib_name})
#         string(REPLACE "-" "_" _ext_safe_name ${_ext_safe_name})

#         message(STATUS "Generating GPR clib_${_ext_safe_name}.gpr for LIB ${_lib}")

#         # Obtain path
#         get_filename_component(_ext_lib_path ${_lib} DIRECTORY)

#         # Sibling include
#         get_filename_component(_ext_lib_include ${_ext_lib_path} DIRECTORY)
#         set(_ext_lib_include ${_ext_lib_include}/include)
#         set(_ext_lib_include_named ${_ext_lib_include}/${_ext_lib_name})

#         set(_gpr clib_${_ext_safe_name}.gpr)

#         # Verify that project hasn't been already imported (gprbuild will complain otherwise)
#         unset(_found)
#         unset(_found CACHE)
#         find_file(_found ${_gpr}
#                 ${ADA_GPR_DIRS})
#         if(NOT "${_found}" MATCHES ".*-NOTFOUND")
#             message(STATUS "C importing to Ada: skipping found ${_found}")
#             continue()
#         endif()

#         # Depending on wheter _ext_lib_include_named exists, we use a different
#         # template
#         if (EXISTS ${_ext_lib_include_named})
#             message(STATUS "Generating GPR clib_${_ext_safe_name}.gpr WITH headers for LIB ${_lib}")
#             configure_file(
#                     ${ADA_RESOURCE_DIR}/external_c_lib.gpr.in
#                     ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gpr})
#         else()
#             message(STATUS "Generating GPR clib_${_ext_safe_name}.gpr WITHOUT headers for LIB ${_lib}")
#             configure_file(
#                     ${ADA_RESOURCE_DIR}/external_c_lib_no_headers.gpr.in
#                     ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gpr})
#         endif()
#     endforeach()
# endfunction()

# function(ada_import_package_libraries PACKAGE_NAME)
#   # This is mostly Claude generated

#   # Find the package
#   find_package(${PACKAGE_NAME} REQUIRED)

#   # Print non-empty package information
#   message(STATUS "Importing package libraries: ${PACKAGE_NAME}")
#   if(${PACKAGE_NAME}_INCLUDE_DIRS)
#     message(STATUS "  ${PACKAGE_NAME}_INCLUDE_DIRS: ${${PACKAGE_NAME}_INCLUDE_DIRS}")
#   endif()
#   if(${PACKAGE_NAME}_LIBRARIES)
#     message(STATUS "  ${PACKAGE_NAME}_LIBRARIES: ${${PACKAGE_NAME}_LIBRARIES}")
#   endif()
#   if(${PACKAGE_NAME}_TARGETS)
#     message(STATUS "  ${PACKAGE_NAME}_TARGETS: ${${PACKAGE_NAME}_TARGETS}")
#   endif()

#   # Try to get library paths from TARGETS
#   set(package_lib_paths "")
#   if(${PACKAGE_NAME}_TARGETS)
#     foreach(target ${${PACKAGE_NAME}_TARGETS})
#       get_target_property(target_type ${target} TYPE)
#       if(target_type STREQUAL "SHARED_LIBRARY" OR target_type STREQUAL "STATIC_LIBRARY")
#         get_target_property(lib_path ${target} LOCATION)
#         if(lib_path)
#           list(APPEND package_lib_paths "${lib_path}")
#         endif()
#       endif()
#     endforeach()
#   endif()

#   # If we couldn't get paths from TARGETS, try LIBRARIES
#   if(NOT package_lib_paths AND ${PACKAGE_NAME}_LIBRARIES)
#     foreach(lib ${${PACKAGE_NAME}_LIBRARIES})
#       if(TARGET ${lib})
#         get_target_property(lib_path ${lib} LOCATION)
#         if(lib_path)
#           list(APPEND package_lib_paths "${lib_path}")
#         endif()
#       else()
#         list(APPEND package_lib_paths "${lib}")
#       endif()
#     endforeach()
#   endif()

#   # Print found library paths
#   if(package_lib_paths)
#     message(STATUS "Found ${PACKAGE_NAME} library paths:")
#     foreach(lib_path ${package_lib_paths})
#       message(STATUS "  ${lib_path}")
#     endforeach()
#   else()
#     message(FATAL_ERROR "Could not determine ${PACKAGE_NAME} library paths")
#   endif()

#   # Import the libraries using ada_import_c_libraries. Iterate over them, and
#   # import only the ones that match the name of the package plus a suffix.
#   # This is to avoid importing libraries that are not part of the package.
#   foreach(lib_path ${package_lib_paths})
#     get_filename_component(lib_name ${lib_path} NAME_WE)
#     if(lib_name MATCHES "^${PACKAGE_NAME}.*")
#       ada_import_c_libraries(${lib_path})
#     endif()
#   endforeach()
# endfunction()

# Create a single GPR project to link any number of libraries in packages
function(ada_gpr_link GPR_NAME #[[ ARGN ]])
  # Expects a list of packages whose target libraries will be added for linking
  # in the GPR_NAME_imports file

  list(REMOVE_DUPLICATES ARGN)
  list(SORT ARGN)

  set(_gprname ${GPR_NAME})
  set(_libs)

  foreach(_pkg ${ARGN})
    message(STATUS "Adding package ${_pkg} to GPR ${GPR_NAME}_imports")
    private_find_libs(${_pkg} _pkglibs)
    list(APPEND _libs ${_pkglibs})
  endforeach()

  # Sort and remove duplicates from _libs
  list(REMOVE_DUPLICATES _libs)
  list(SORT _libs)

  # Print found library paths
  if(_libs)
    message(STATUS "Found libraries for ${GPR_NAME}_imports:")
    foreach(lib_path ${_libs})
      message(STATUS "  ${lib_path}")
    endforeach()
  else()
    message(FATAL_ERROR "Could not determine libraries for ${GPR_NAME}_imports")
  endif()

  # Create _linking containing each lib in a separate line, comma separated
  # but for the last one, in a single string
  set(_linking "")
  foreach(lib ${_libs})
    # Compute the containing directory of ${lib}
    get_filename_component(parent ${lib} DIRECTORY)

    # Skip switches starting with "-"
    # TODO: we should rather pass them as-is?
    if(lib MATCHES "^-.*")
      continue()
    endif()

    # TODO: we can pass full paths directly without stripping anything and -L?
    # TRY IT!

    # Get the name without .a or .so* and without the leading 3 "lib"
    get_filename_component(lib ${lib} NAME_WE)

    # Remove leading "lib" (only if it is there!)
    if(lib MATCHES "^lib.*")
      string(SUBSTRING ${lib} 3 -1 lib)
    endif()

    # Add -l for the library
    set(_linking "${_linking}         \"-l${lib}\",\n")

    # Add also a -L for the containing directory, for libs not in path
    # only if parent /= ""
    if(NOT parent STREQUAL "")
      set(_linking "${_linking}         \"-L${parent}\",\n")
    endif()
  endforeach()

  configure_file(
    ${ADA_RESOURCE_DIR}/external_c_lib_linker_imports.gpr.in
    ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gprname}_linker_imports.gpr
  )

  # Create an empty .ads file in the include dir to allow linking
  file(WRITE ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gprname}_linker_imports.ads
    "package ${_gprname}_linker_imports is\nend ${_gprname}_linker_imports;")

endfunction()

# Create a single GPR project to find any number of headers in packages
function(ada_gpr_headers GPR_NAME #[[ ARGN ]])
  # Expects a list of packages whose target libraries will be added for linking
  # in the GPR_NAME_imports file

  list(REMOVE_DUPLICATES ARGN)
  list(SORT ARGN)

  set(_gprname ${GPR_NAME})
  set(_headers)

  message(STATUS "Creating GPR ${GPR_NAME}_header_imports for packages: ${ARGN}")

  foreach(_pkg ${ARGN})
    message(STATUS "Adding package ${_pkg} to GPR ${GPR_NAME}_imports")
    ada_find_package_include_dir(_include ${_pkg})
    list(APPEND _headers ${_include})
  endforeach()

  # Sort and remove duplicates
  list(REMOVE_DUPLICATES _headers)
  list(SORT _headers)

  # Print found library paths
  if(_headers)
    message(STATUS "Found header dirs for ${GPR_NAME}_header_imports:")
    foreach(path ${_headers})
      message(STATUS "  ${path}")
    endforeach()
  else()
    message(FATAL_ERROR "Could not determine header locations for ${GPR_NAME}_header_imports")
  endif()

  # Create string containing each path in a separate line, comma separated
  set(_formatted "")
  foreach(header ${_headers})
    set(_formatted "${_formatted}         \"${header}\",\n")
  endforeach()

  set(_headers ${_formatted}) # Rename for the file template

  configure_file(
    ${ADA_RESOURCE_DIR}/external_c_lib_header_imports.gpr.in
    ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gprname}_header_imports.gpr
  )

  # Create an empty .h file in the include dir to avoid a "no sources" warning
  file(WRITE ${CMAKE_INSTALL_PREFIX}/share/gpr/${_gprname}_header_imports.h "")
endfunction()

# Make foreign msgs usable from the ada side, manually
function(ada_import_interfaces #[[ ARGN ]])

    set(PKG_NAMES ${ARGN})

    find_package(rosidl_generator_ada REQUIRED) # import the generator

    # Depending on whether we are importing our own messages, we must add this dependency or not.
    # Something is amiss here because if we aren't generating messages, a circularity appears, when
    # it seems it should be the other way around.

    if (${PROJECT_NAME} IN_LIST PKG_NAMES)
        set(_depends ${PROJECT_NAME}) # depend on the package C messages, which are under the package name target
    endif()

    # Add a target for the generator with the arguments

    add_custom_command(
        OUTPUT ada_ifaces.stamp # Never created, so regenerated every time until I do smthg about this
        COMMAND echo "Running Ada generator for ${PKG_NAMES}"
        COMMAND ${ADA_GENERATOR}
            "--import-pkg=$<JOIN:${PKG_NAMES},,>"
            "--from-pkg=${PROJECT_NAME}"
            "--current-src=${PROJECT_SOURCE_DIR}"
        DEPENDS ${_depends}
        VERBATIM
    )

    # Avoid multiple generations by grouping the generator command under a common custom target
    add_custom_target(ada_interfaces_internal ALL
        COMMENT "Custom target for ADA GENERATOR"
        DEPENDS ada_ifaces.stamp
        VERBATIM
    )

    ada_add_library(
        ada_interfaces_gpr
        "${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_ada"
        "ros2_interfaces_${PROJECT_NAME}")
    add_dependencies(ada_interfaces_gpr ada_interfaces_internal)

endfunction()
