message(STATUS "Ada CMake extensions loaded from ${PROJECT_NAME} v${PROJECT_VERSION}")

include(ada_exports)
include(ada_imports)
include(ada_scope)
include(ada_utils)

#get_cmake_property(_variableNames VARIABLES)
#list (SORT _variableNames)
#foreach (_variableName ${_variableNames})
#  message(STATUS "${_variableName}=${${_variableName}}")
#endforeach()