# Deduct the include from the _DIR
function (ada_find_package_include_dir RETURN PACKAGE_DIR)
    # Just three up
    get_filename_component(_dir ${PACKAGE_DIR} DIRECTORY)
    get_filename_component(_dir ${_dir} DIRECTORY)
    get_filename_component(_dir ${_dir} DIRECTORY)
    set(${RETURN} ${_dir}/include PARENT_SCOPE)
endfunction()

# Deduct the lib dir from the _DIR
function (ada_find_package_library_dir RETURN PACKAGE_DIR)
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
