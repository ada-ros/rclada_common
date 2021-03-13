#include "ament_index_cpp/get_resources.hpp"
#include "ament_index_cpp/get_package_prefix.hpp"
#include <cstring>
#include <iostream>
#include <string>

//  Returns the install path of a package
//  /opt/ros/foxy/
//  /src/myprog/install/package_name
//  etc. (Note, for an install, packages are merged; during development they aren't by default)
//  Then you can append the part you want:
//  /opt/ros/foxy/lib/libbuiltin_interfaces__rosidl_typesupport_c.so or whatever
std::string get_package_install_path(const std::string & package_name)
{
  try {

    std::string package_prefix;
    try {
      package_prefix = ament_index_cpp::get_package_prefix(package_name);
    } catch (ament_index_cpp::PackageNotFoundError & e) {
      std::cerr << "ERROR: could not find package at rosidl_ada::ament_query "
      << package_name << ": " << e.what() << std::endl;
      return "";
    }

    return package_prefix;

  } catch (std::exception & e) {
    std::cerr << "ERROR: unexpected at rosidl_ada::ament_query: "
    << e.what() << std::endl;
    return "";
  }
}

extern "C" {
  //  Caller has to free the memory
  const char * rosidl_ada_find_package_install_path(const char * package_name)
  {
    auto loc = get_package_install_path(package_name);

    if (loc == "")
      return NULL;

    char * dst = (char*)malloc(loc.size() + 1);
    strcpy(dst, loc.c_str());
    return dst;
  }
}
