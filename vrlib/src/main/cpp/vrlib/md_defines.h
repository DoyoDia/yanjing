//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MD360PLAYER4OH_MD_DEFINES_H
#define MD360PLAYER4OH_MD_DEFINES_H

#define MD_OK                       0
#define MD_ERR                      -1
#define MD_ERR_BASE                 -6000
// -6001
#define MD_ERR_NPE                  MD_ERR_BASE - 1
// -6002
#define MD_ERR_CMD_UNKNOWN          MD_ERR_BASE - 2
// -6003
#define MD_ERR_EGL_INIT             MD_ERR_BASE - 3
// 添加着色器相关错误码
#define MD_ERR_SHADER_COMPILE       MD_ERR_BASE - 4
#define MD_ERR_SHADER_LINK          MD_ERR_BASE - 5

#endif //MD360PLAYER4OH_MD_DEFINES_H

