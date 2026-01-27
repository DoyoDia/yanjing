# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(md360player)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

# 使用file命令显式获取所有源文件，确保包含所有必要的文件（包括.cc文件）
file(GLOB_RECURSE md_napi ${NATIVERENDER_ROOT_PATH}/napi/*.cpp ${NATIVERENDER_ROOT_PATH}/napi/*.cc)
file(GLOB_RECURSE md_vrlib ${NATIVERENDER_ROOT_PATH}/vrlib/*.cpp ${NATIVERENDER_ROOT_PATH}/vrlib/*.cc)
file(GLOB_RECURSE md_vrlib_device ${NATIVERENDER_ROOT_PATH}/vrlib/device/*.cpp ${NATIVERENDER_ROOT_PATH}/vrlib/device/*.cc)
# 确保motion_strategy.cc被包含
if(NOT "${md_vrlib}" MATCHES ".*motion_strategy.cc$")
    list(APPEND md_vrlib "${NATIVERENDER_ROOT_PATH}/vrlib/motion_strategy.cc")
endif()
# 排除 napi/napi_init.cc，因为我们已经使用根目录的 napi_init.cpp
list(REMOVE_ITEM md_napi "${NATIVERENDER_ROOT_PATH}/napi/napi_init.cc")

# 明确添加所有必要的源文件
set(md_src_files
    ${md_napi}
    ${md_vrlib}
    ${md_vrlib_device}
    ${NATIVERENDER_ROOT_PATH}/napi_init.cpp
)

# 打印调试信息，确认文件被正确包含
message(STATUS "NAPI files: ${md_napi}")
message(STATUS "VRLIB files: ${md_vrlib}")
message(STATUS "Device files: ${md_vrlib_device}")

add_library(md360player SHARED ${md_src_files})
target_link_libraries(md360player PUBLIC
    libace_napi.z.so
    ace_ndk.z
    ace_napi.z
    hilog_ndk.z
    libEGL.so
    libGLESv3.so
    libnative_image.so
    libnative_window.so)