cmake_minimum_required(VERSION 3.15)

project(los-cc)

set(CMAKE_CROSSCOMPILING TRUE)

set(CXX_STANDARD 17)

# set(CMAKE_C_COMPILER riscv64-unknown-elf-gcc)
set(CMAKE_CXX_COMPILER riscv64-unknown-elf-g++)
set(CMAKE_ASM_COMPILER riscv64-unknown-elf-g++)

set(CMAKE_SYSTEM_PROCESSOR riscv64)
set(CMAKE_SYSTEM_NAME Generic)

# set(CMAKE_C_FLAGS "-nostdlib -fno-builtin -march=rv32ima -mabi=ilp32 -g -MD")
set(CMAKE_CXX_FLAGS "-nostdlib -fno-builtin -march=rv32ima -mabi=ilp32 -g -MD -ffreestanding -Werror")
set(CXX_FLAGS "-nostdlib;-fno-builtin;-march=rv32ima;-mabi=ilp32;-g;-MD;-ffreestanding;-Werror")
set(CMAKE_ASM_FLAGS "-nostdlib;-fno-builtin;-march=rv32ima;-mabi=ilp32;-ffreestanding;-g;-MD;-Werror")

set(CMAKE_BUILD_TYPE Debug)

# 设置链接脚本
set(LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/kernel.ld)
set(CMAKE_EXE_LINKER_FLAGS "-T ${LINKER_SCRIPT}")

# 添加汇编语言支持
enable_language(ASM)

set(CMAKE_VERBOSE_MAKEFILE ON)

message(STATUS "--------------------")

###########################################################

# 添加汇编文件
file(GLOB SRCS_ASM "*.S")

foreach(SRC_ASM ${SRCS_ASM})
    get_filename_component(SRC_ASM_NAME ${SRC_ASM} NAME_WE)
    message(STATUS  ${CMAKE_CURRENT_BINARY_DIR})
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SRC_ASM_NAME}.o
        COMMAND ${CMAKE_ASM_COMPILER} ${CMAKE_ASM_FLAGS} -c ${SRC_ASM} -o ${CMAKE_CURRENT_BINARY_DIR}/${SRC_ASM_NAME}.o
        DEPENDS ${SRC_ASM}
    )
    list(APPEND OBJS ${CMAKE_CURRENT_BINARY_DIR}/${SRC_ASM_NAME}.o)
endforeach()


# 添加源文件
file(GLOB SRCS_CC "*.cc")

foreach(SRC_CC ${SRCS_CC})
    get_filename_component(SRC_CC_NAME ${SRC_CC} NAME_WE)
    message(STATUS ${CMAKE_CXX_FLAGS})

    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SRC_CC_NAME}.o
        COMMAND
            ${CMAKE_CXX_COMPILER}
            ${CXX_FLAGS}
            -c
            ${SRC_CC}
            -o
            ${CMAKE_CURRENT_BINARY_DIR}/${SRC_CC_NAME}.o
        DEPENDS ${SRC_CC}
    )
    list(APPEND OBJS ${CMAKE_CURRENT_BINARY_DIR}/${SRC_CC_NAME}.o)
        # 为每个源文件应用 clang-tidy
        find_program(CLANG_TIDY_EXE NAMES "clang-tidy-12" REQUIRED)
        set(CLANG_TIDY_COMMAND "${CLANG_TIDY_EXE}" "-checks=-*,modernize-*")
        set_source_files_properties(${SRC_CC} PROPERTIES COMPILE_OPTIONS "$<$<COMPILE_LANGUAGE:CXX>:${CLANG_TIDY_COMMAND}>")
    
endforeach()

# Add the kernel target
add_executable(kernel.elf ${OBJS})
# add_executable(kernel.elf ${SRCS_CC} ${SRCS_ASM})
# target_compile_options(kernel.elf PRIVATE)
add_link_options("-T ${CMAKE_CURRENT_SOURCE_DIR}/kernel.ld")
# target_link_options(kernel.elf PRIVATE "-T ${CMAKE_SOURCE_DIR}/kernel.ld")
# target_link_options(kernel.elf PRIVATE ${OBJS} "-T ${CMAKE_CURRENT_SOURCE_DIR}/kernel.ld")
set_target_properties(kernel.elf PROPERTIES LINKER_LANGUAGE CXX)


#####################################################################################
# clang-tidy
#

# 搜索 clang-tidy
find_program(CLANG_TIDY_EXE NAMES "clang-tidy-12" REQUIRED)
# 禁用了所有默认检查 (-*)，并且只启用了提倡使用现代 C++ 语言结构的检查 ( modernize-*)。
set(CLANG_TIDY_COMMAND "${CLANG_TIDY_EXE}" "-checks=-*,modernize-*")
# 为构建目标clang-tidy设置属性
set_target_properties(kernel.elf PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}")

# 为每个源文件创建一个自定义目标来应用 clang-tidy
foreach(SRC_CC ${SRCS_CC})
    get_filename_component(SRC_CC_NAME ${SRC_CC} NAME_WE)
    add_custom_target(${SRC_CC_NAME}_clang_tidy
        COMMAND ${CLANG_TIDY_COMMAND} ${SRC_CC}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running clang-tidy on ${SRC_CC}"
        VERBATIM
    )
    add_dependencies(kernel.elf ${SRC_CC_NAME}_clang_tidy)
endforeach()