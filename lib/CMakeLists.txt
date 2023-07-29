set(gtest_force_shared_crt ON CACHE BOOL "" FORCE) # don't override our compiler/linker options when building gtest
# 设置局部 C++ 编译命令
set(CMAKE_CXX_COMPILER "/usr/bin/c++")
# find_program(CXX_COMPILER NAMES "c++" REQUIRED)
# set(CMAKE_CXX_COMPILER ${CXX_COMPILER})
set(CMAKE_CXX_FLAGS)

add_subdirectory(googletest)