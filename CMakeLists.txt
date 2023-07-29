cmake_minimum_required(VERSION 3.15)

project(los-cc)

set(CMAKE_CROSSCOMPILING TRUE)

set(COMPILE_COMMANDS_PATH ${CMAKE_CURRENT_BINARY_DIR}/compile_commands.json)
# 设置包含路径
set(INCLUDE_DIRS "-I${CMAKE_CURRENT_SOURCE_DIR}")

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

# set(CMAKE_VERBOSE_MAKEFILE ON) #调试时使用

# Set other variables
set(QEMU "qemu-system-riscv32") # Change this to "qemu-system-riscv64" for 64-bit
set(CPUS 1)
set(QFLAGS "-nographic;-smp;${CPUS};-machine;virt;-bios;none")
# set(QFLAGS "${QFLAGS} -drive file=fs.img,if=none,format=raw,id=x0")
# set(QFLAGS "${QFLAGS} -device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0")
# set(QFLAGS "${QFLAGS} -netdev user,id=net,hostfwd=udp::6666-:666")
# set(QFLAGS "${QFLAGS} -device e1000,netdev=net,bus=pcie.0")
# set(QFLAGS "${QFLAGS} -object filter-dump,id=net,netdev=net,file=net.dat")

###########################################################

# 添加汇编文件
file(GLOB_RECURSE SRCS_ASM "src/*.S")

foreach(SRC_ASM ${SRCS_ASM})
    get_filename_component(SRC_ASM_NAME ${SRC_ASM} NAME_WE)
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SRC_ASM_NAME}.o
        COMMAND ${CMAKE_ASM_COMPILER} ${CMAKE_ASM_FLAGS} -c ${SRC_ASM} -o ${CMAKE_CURRENT_BINARY_DIR}/${SRC_ASM_NAME}.o
        DEPENDS ${SRC_ASM}
    )
    list(APPEND OBJS ${CMAKE_CURRENT_BINARY_DIR}/${SRC_ASM_NAME}.o)
endforeach()

include_directories(${CMAKE_CURRENT_SOURCE_DIR} RECURSIVE)
# include_directories(${CMAKE_CURRENT_SOURCE_DIR}/inc)

# 添加源文件
file(GLOB_RECURSE SRCS_CC "src/*.cc")

foreach(SRC_CC ${SRCS_CC})
    get_filename_component(SRC_CC_NAME ${SRC_CC} NAME_WE)
    message(STATUS ${CMAKE_CXX_FLAGS})

    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${SRC_CC_NAME}.o
        COMMAND
            ${CMAKE_CXX_COMPILER}
            ${CXX_FLAGS}
            ${INCLUDE_DIRS}
            -c
            ${SRC_CC}
            -o
            ${CMAKE_CURRENT_BINARY_DIR}/${SRC_CC_NAME}.o
        DEPENDS ${SRC_CC}
    )
    list(APPEND OBJS ${CMAKE_CURRENT_BINARY_DIR}/${SRC_CC_NAME}.o)
endforeach()

# Add the kernel target
add_executable(kernel.elf ${OBJS})
# add_executable(kernel.elf ${SRCS_CC} ${SRCS_ASM})
# target_compile_options(kernel.elf PRIVATE)
add_link_options("-T ${CMAKE_CURRENT_SOURCE_DIR}/kernel.ld")
# target_link_options(kernel.elf PRIVATE "-T ${CMAKE_SOURCE_DIR}/kernel.ld")
# target_link_options(kernel.elf PRIVATE ${OBJS} "-T ${CMAKE_CURRENT_SOURCE_DIR}/kernel.ld")
set_target_properties(kernel.elf PROPERTIES LINKER_LANGUAGE CXX)

add_subdirectory(lib)
add_subdirectory(test)
#####################################################################################
# clang-tidy
#

# 搜索 clang-tidy
find_program(CLANG_TIDY_EXE NAMES "clang-tidy-12" REQUIRED)
# 禁用了所有默认检查 (-*)，并且只启用了提倡使用现代 C++ 语言结构的检查 ( modernize-*)。
set(CLANG_TIDY_COMMAND "${CLANG_TIDY_EXE}" "-p;${COMPILE_COMMANDS_PATH}" "-checks=-*,modernize-*" "-extra-arg=-Iinc")
# 为构建目标clang-tidy设置属性
set_target_properties(kernel.elf PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}")

# 为每个源文件创建一个自定义目标来应用 clang-tidy
foreach(SRC_CC ${SRCS_CC})
    get_filename_component(SRC_CC_NAME ${SRC_CC} NAME_WE)
    add_custom_target(${SRC_CC_NAME}_clang_tidy
        COMMAND ${CLANG_TIDY_COMMAND} ${SRC_CC}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Running clang-tidy on ${SRC_CC}"
        VERBATIM
    )
    add_dependencies(kernel.elf ${SRC_CC_NAME}_clang_tidy)
endforeach()

#####################
add_custom_target(run
    COMMAND ${CMAKE_COMMAND} -E env ${QEMU} ${QFLAGS} -kernel kernel.elf
    DEPENDS kernel.elf
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

# 定义clean目标
add_custom_target(clean-all
    # COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/build
    COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/build/*
    # COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/fs.img
    # COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/kernel.elf
    # COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/*.o
    # COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/*.d
    # COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/*.bin
    # COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/*.asm
    # COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_BINARY_DIR}/*.sym
    # ... 添加其他需要清理的文件或目录 ...
)

# 添加一个自定义目标 debug，用于构建带有调试标志的内核并启动QEMU调试
add_custom_target(debug
    # COMMAND ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=Debug --build ${CMAKE_BINARY_DIR}
    COMMAND ${CMAKE_COMMAND} -E echo "Press Ctrl-A and then X to exit QEMU"
    COMMAND ${QEMU} ${QFLAGS} -kernel kernel.elf -s -S
    COMMENT "Building kernel with debug flags and starting QEMU debugger..."
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
