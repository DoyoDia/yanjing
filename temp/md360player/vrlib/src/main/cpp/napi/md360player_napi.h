//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MD360PLAYER4OH_MD360PLAYER_NAPI_H
#define MD360PLAYER4OH_MD360PLAYER_NAPI_H

#include "../vrlib/md_vr_library.h"
#include <memory>
#include <node_api.h>

enum MD360PlayerNapiCmd {
    kCmdUnknown = 0,
    kCmdInit = 1,
    kCmdDestroy,
    kCmdResume,
    kCmdPause,
    // VR相关命令
    kCmdSetVRModeEnabled = 5,
    kCmdSetIPD = 6,
    kCmdSetBarrelDistortionEnabled = 7,
    kCmdSetBarrelDistortionParams = 8
};

class MD360PlayerNapi {
public:
    static bool InitBindings(napi_env env, napi_value exports);
private:
    MD360PlayerNapi();
    static MD360PlayerNapi* GetNapi(napi_env env, napi_value value);
    static napi_value NapiCreate(napi_env env, napi_callback_info info);
    static void NapiDelete(napi_env env, void* finalize_data, void* finalize_hint);
private:
    static napi_value SetSurfaceIdNapi(napi_env env, napi_callback_info info);
    static napi_value RunCmdNapi(napi_env env, napi_callback_info info);
    static napi_value UpdateMVPMatrixNapi(napi_env env, napi_callback_info info);
    static napi_value UpdateTouchDeltaNapi(napi_env env, napi_callback_info info);
    // VR相关NAPI方法
    static napi_value SetVRModeEnabledNapi(napi_env env, napi_callback_info info);
    static napi_value SetIPDNapi(napi_env env, napi_callback_info info);
    static napi_value SetBarrelDistortionEnabledNapi(napi_env env, napi_callback_info info);
    static napi_value SetBarrelDistortionParamsNapi(napi_env env, napi_callback_info info);
    
public:
    std::shared_ptr<asha::vrlib::MDVRLibraryAPI>& GetLibrary();
private:
    std::shared_ptr<asha::vrlib::MDVRLibraryAPI> library_ = nullptr;
};

#endif //MD360PLAYER4OH_MD360PLAYER_NAPI_H

