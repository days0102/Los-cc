# 设置局部 C++ 编译命令
set(CMAKE_CXX_COMPILER "/usr/bin/c++")
# find_program(CXX_COMPILER NAMES "c++" REQUIRED)
# set(CMAKE_CXX_COMPILER ${CXX_COMPILER})
set(CMAKE_CXX_FLAGS)
set(CMAKE_ASM_COMPILER)
set(CMAKE_EXE_LINKER_FLAGS)
project(test)
include(GoogleTest)

set(CMAKE_SYSTEM_PROCESSOR LINUX)
set(CMAKE_SYSTEM_NAME)

FILE(GLOB_RECURSE TEST_SRC *_test.cc) # 搜索CMakeLists.txt所在目录及子目录下所有 *_test.cc文件
FOREACH(FF ${TEST_SRC})
    MESSAGE(${FF})
    get_filename_component(FILENAME ${FF} NAME_WE)
    ADD_EXECUTABLE(${FILENAME} ${FF})
    TARGET_LINK_LIBRARIES(${FILENAME} gtest gtest_main) # 链接
    gtest_discover_tests(${FILENAME})
ENDFOREACH(FF)