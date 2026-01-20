cmake_minimum_required(VERSION 3.5.0)
project(panorama_renderer)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

# 添加头文件搜索路径
include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

# 添加源文件
add_library(panorama_renderer SHARED
    napi_init.cpp
    plugin_manager.cpp
    panorama_renderer.cpp
    sphere_mesh.cpp
)

# 查找需要的库
find_library(hilog-lib hilog_ndk.z)
find_library(ace-lib ace_ndk.z)
find_library(napi-lib ace_napi.z)
find_library(uv-lib uv)
find_library(EGL-lib EGL)
find_library(GLESv3-lib GLESv3)
find_library(rawfile-lib rawfile.z)

# 链接库
target_link_libraries(panorama_renderer PUBLIC
    ${hilog-lib}
    ${ace-lib}
    ${napi-lib}
    ${uv-lib}
    ${EGL-lib}
    ${GLESv3-lib}
    ${rawfile-lib}
    libnative_window.so
    libnative_image.so
)
