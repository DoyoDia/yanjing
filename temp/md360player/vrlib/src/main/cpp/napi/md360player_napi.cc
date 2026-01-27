//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "md360player_napi.h"
#include <napi/native_api.h>
#include <js_native_api.h>
#include <string>
#include "md_napi_utils.h"
#include "../vrlib/md_defines.h"
#include "../vrlib/md_log.h"

using namespace asha::vrlib;

static napi_ref g_exports_ref;

#define GET_ARGS0           \
    napi_value this_arg;    \
    MD_NAPI_CALL(env, napi_get_cb_info(env, info, nullptr, nullptr, &this_arg, nullptr));   \
    auto napi = GetNapi(env, this_arg);                                                     \
    MD_NAPI_ASSERT(env, napi != nullptr, "napi GET_ARGS failed.")


#define GET_ARGS(count)           \
    size_t argc = count;          \
    napi_value args[argc];        \
    napi_value this_arg; \
    MD_NAPI_CALL(env, napi_get_cb_info(env, info, &argc, args, &this_arg, nullptr));   \
    auto napi = GetNapi(env, this_arg);                                                \
    MD_NAPI_ASSERT(env, napi != nullptr, "napi GET_ARGS failed.")

bool MD360PlayerNapi::InitBindings(napi_env env, napi_value exports) {
    if (napi_create_reference(env, exports, 1, &g_exports_ref) != napi_ok) {
        // log?
    }
    napi_property_descriptor desc[] = {
        MD_DECLARE_NAPI_FUNCTION("setSurfaceId", MD360PlayerNapi::SetSurfaceIdNapi),
        MD_DECLARE_NAPI_FUNCTION("runCmd", MD360PlayerNapi::RunCmdNapi),
        MD_DECLARE_NAPI_FUNCTION("updateMVPMatrix", MD360PlayerNapi::UpdateMVPMatrixNapi),
        MD_DECLARE_NAPI_FUNCTION("updateTouchDelta", MD360PlayerNapi::UpdateTouchDeltaNapi),
        // VR相关NAPI方法绑定
        MD_DECLARE_NAPI_FUNCTION("setVRModeEnabled", MD360PlayerNapi::SetVRModeEnabledNapi),
        MD_DECLARE_NAPI_FUNCTION("setIPD", MD360PlayerNapi::SetIPDNapi),
        MD_DECLARE_NAPI_FUNCTION("setBarrelDistortionEnabled", MD360PlayerNapi::SetBarrelDistortionEnabledNapi),
        MD_DECLARE_NAPI_FUNCTION("setBarrelDistortionParams", MD360PlayerNapi::SetBarrelDistortionParamsNapi)
    };
    // napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    napi_value clz_napi_ctor;
    MD_NAPI_CALL_BASE(
        env, 
        napi_define_class(
            env,
            "MD360Player",
            NAPI_AUTO_LENGTH,
            MD360PlayerNapi::NapiCreate, nullptr,
            sizeof(desc) / sizeof(desc[0]), desc,
            &clz_napi_ctor
        ), 
        false
    );
    MD_NAPI_CALL_BASE(env, napi_set_named_property(env, exports, "MD360Player", clz_napi_ctor), false);
    return true;
}

MD360PlayerNapi::MD360PlayerNapi() {
    library_ = asha::vrlib::MDVRLibraryAPI::CreateLibrary();
}

MD360PlayerNapi* MD360PlayerNapi::GetNapi(napi_env env, napi_value value) {
    napi_value napi_obj;
    MD_NAPI_CALL(env, napi_get_named_property(env, value, "__MD360PLAYER_NAPI_OBJ__", &napi_obj));
    MD360PlayerNapi* napi = nullptr;
    MD_NAPI_CALL(env, napi_unwrap(env, napi_obj, reinterpret_cast<void **>(&napi)));
    return napi;
}

napi_value MD360PlayerNapi::NapiCreate(napi_env env, napi_callback_info info) {
    napi_value this_arg;
    MD_NAPI_CALL(env, napi_get_cb_info(env, info, nullptr, nullptr, &this_arg, nullptr));
    auto napi = new MD360PlayerNapi();
    napi_value napi_obj;
    MD_NAPI_CALL(env, napi_create_object(env, &napi_obj));
    MD_NAPI_CALL(env, napi_wrap(env, napi_obj, napi, MD360PlayerNapi::NapiDelete, nullptr, nullptr));
    MD_NAPI_CALL(env, napi_set_named_property(env, this_arg, "__MD360PLAYER_NAPI_OBJ__", napi_obj));
    return this_arg;
}

void MD360PlayerNapi::NapiDelete(napi_env env, void* finalize_data, void* finalize_hint) {
    auto napi = (MD360PlayerNapi*) finalize_data;
    if (napi != nullptr) {
        // 确保库资源被正确释放
        if (napi->library_ != nullptr) {
            napi->library_->Destroy();
        }
        delete napi;
    }
}

napi_value MD360PlayerNapi::SetSurfaceIdNapi(napi_env env, napi_callback_info info) {
    GET_ARGS(1);
    std::string surface_id;
    if (!MDNapiUtils::JsValueToString(env, args[0], &surface_id)) {
        MD_LOGE("MD360PlayerNapi::SetSurfaceIdNapi JsValueToString failed");
        return MDNapiUtils::Int32ToJsValue(env, -1);;
    }
    int ret = napi->GetLibrary()->SetSurfaceId(surface_id);
    MD_LOGI("MD360PlayerNapi::GetLibrary SetSurfaceId ret:%d", ret);
    return MDNapiUtils::Int32ToJsValue(env, ret);
}

napi_value MD360PlayerNapi::RunCmdNapi(napi_env env, napi_callback_info info) {
    GET_ARGS(1);
    int cmd = 0;
    if (!MDNapiUtils::JsValueToInt32(env, args[0], &cmd)) {
        MD_NAPI_ASSERT(env, false, "MD360PlayerNapi::RunCmdNapi JsValueToInt32 failed");
        return MDNapiUtils::Int32ToJsValue(env, -1);
    }
    MD_LOGI("MD360PlayerNapi::GetLibrary RunCmd cmd(%d)", cmd);
    int ret = MD_OK;

    // VR相关命令需要额外参数，需要重新获取参数
    if (cmd >= kCmdSetVRModeEnabled && cmd <= kCmdSetBarrelDistortionParams) {
        size_t vr_argc = 0;
        napi_value vr_args[5];  // 最多需要5个参数
        napi_value vr_this_arg;
        MD_NAPI_CALL(env, napi_get_cb_info(env, info, &vr_argc, vr_args, &vr_this_arg, nullptr));
        auto vr_napi = GetNapi(env, vr_this_arg);
        MD_NAPI_ASSERT(env, vr_napi != nullptr, "napi GET_ARGS failed for VR commands");
    
        switch (cmd) {
            case kCmdSetVRModeEnabled: {
                if (vr_argc >= 2) {
                    bool enabled;
                    if (MDNapiUtils::JsValueToBool(env, vr_args[1], &enabled)) {
                        vr_napi->GetLibrary()->SetVRModeEnabled(enabled);
                    }
                }
                break;
            }
            case kCmdSetIPD: {
                if (vr_argc >= 2) {
                    float ipd;
                    if (MDNapiUtils::JsValueToFloat(env, vr_args[1], &ipd)) {
                        vr_napi->GetLibrary()->SetIPD((float)ipd);
                    }
                }
                break;
            }
            case kCmdSetBarrelDistortionEnabled: {
                if (vr_argc >= 2) {
                    bool enabled;
                    if (MDNapiUtils::JsValueToBool(env, vr_args[1], &enabled)) {
                        vr_napi->GetLibrary()->SetBarrelDistortionEnabled(enabled);
                    }
                }
                break;
            }
            case kCmdSetBarrelDistortionParams: {
                if (vr_argc >= 4) {
                    float k1, k2, scale;
                    if (MDNapiUtils::JsValueToFloat(env, vr_args[1], &k1) &&
                        MDNapiUtils::JsValueToFloat(env, vr_args[2], &k2) &&
                        MDNapiUtils::JsValueToFloat(env, vr_args[3], &scale)) {
                        vr_napi->GetLibrary()->SetBarrelDistortionParams(
                            (float)k1, (float)k2, (float)scale);
                    }
                }
                break;
            }
            default:
                break;
        }
    } else {
        // 原有非VR命令处理逻辑保持不变
        switch (cmd) {
            case kCmdInit: {
                ret = napi->GetLibrary()->Init();
                break;
            } 
            case kCmdDestroy: {
                ret = napi->GetLibrary()->Destroy();
                break;
            } 
            case kCmdPause: {
                ret = napi->GetLibrary()->Pause();
                break;
            } 
            case kCmdResume: {
                ret = napi->GetLibrary()->Resume();
                break;
            }
            default: {
                ret = MD_ERR_CMD_UNKNOWN;
                MD_LOGE("MD360PlayerNapi::GetLibrary RunCmd failed, cmd(%d) unknown", cmd);
                break;
            }
        }
    }
    return MDNapiUtils::Int32ToJsValue(env, ret);
}

napi_value MD360PlayerNapi::UpdateMVPMatrixNapi(napi_env env, napi_callback_info info) {
    GET_ARGS(1);
    
    bool is_array;
    napi_is_array(env, args[0], &is_array);
    if (!is_array) {
        return nullptr;
    }
    
    uint32_t length;
    napi_get_array_length(env, args[0], &length);
    if (length < 16) {
        return nullptr;
    }
    
    float matrix[16];
    for (uint32_t i = 0; i < 16; i++) {
        napi_value element;
        napi_get_element(env, args[0], i, &element);
        double val;
        napi_get_value_double(env, element, &val);
        matrix[i] = (float)val;
    }
    
    napi->GetLibrary()->UpdateMVPMatrix(matrix);
    return nullptr;
}

napi_value MD360PlayerNapi::UpdateTouchDeltaNapi(napi_env env, napi_callback_info info) {
    GET_ARGS(2);
    
    float deltaX = 0.0f;
    float deltaY = 0.0f;
    if (!MDNapiUtils::JsValueToFloat(env, args[0], &deltaX) ||
        !MDNapiUtils::JsValueToFloat(env, args[1], &deltaY)) {
        MD_NAPI_ASSERT(env, false, "MD360PlayerNapi::UpdateTouchDeltaNapi JsValueToFloat failed");
        return nullptr;
    }
    
    napi->GetLibrary()->UpdateTouchDelta(deltaX, deltaY);
    return nullptr;
}

// VR相关NAPI方法实现
napi_value MD360PlayerNapi::SetVRModeEnabledNapi(napi_env env, napi_callback_info info) {
    GET_ARGS(1);
    bool enabled;
    if (!MDNapiUtils::JsValueToBool(env, args[0], &enabled)) {
        MD_NAPI_ASSERT(env, false, "MD360PlayerNapi::SetVRModeEnabledNapi JsValueToBool failed");
        return MDNapiUtils::Int32ToJsValue(env, -1);
    }
    napi->GetLibrary()->SetVRModeEnabled(enabled);
    return MDNapiUtils::Int32ToJsValue(env, MD_OK);
}

napi_value MD360PlayerNapi::SetIPDNapi(napi_env env, napi_callback_info info) {
    GET_ARGS(1);
    float ipd;
    if (!MDNapiUtils::JsValueToFloat(env, args[0], &ipd)) {
        MD_NAPI_ASSERT(env, false, "MD360PlayerNapi::SetIPDNapi JsValueToDouble failed");
        return MDNapiUtils::Int32ToJsValue(env, -1);
    }
    napi->GetLibrary()->SetIPD((float)ipd);
    return MDNapiUtils::Int32ToJsValue(env, MD_OK);
}

napi_value MD360PlayerNapi::SetBarrelDistortionEnabledNapi(napi_env env, napi_callback_info info) {
    GET_ARGS(1);
    bool enabled;
    if (!MDNapiUtils::JsValueToBool(env, args[0], &enabled)) {
        MD_NAPI_ASSERT(env, false, "MD360PlayerNapi::SetBarrelDistortionEnabledNapi JsValueToBool failed");
        return MDNapiUtils::Int32ToJsValue(env, -1);
    }
    napi->GetLibrary()->SetBarrelDistortionEnabled(enabled);
    return MDNapiUtils::Int32ToJsValue(env, MD_OK);
}

napi_value MD360PlayerNapi::SetBarrelDistortionParamsNapi(napi_env env, napi_callback_info info) {
    GET_ARGS(3);
    float k1, k2, scale;
    if (!MDNapiUtils::JsValueToFloat(env, args[0], &k1) ||
        !MDNapiUtils::JsValueToFloat(env, args[1], &k2) ||
        !MDNapiUtils::JsValueToFloat(env, args[2], &scale)) {
        MD_NAPI_ASSERT(env, false, "MD360PlayerNapi::SetBarrelDistortionParamsNapi JsValueToFloat failed");
        return MDNapiUtils::Int32ToJsValue(env, -1);
    }
    napi->GetLibrary()->SetBarrelDistortionParams(
        (float)k1, (float)k2, (float)scale);
    return MDNapiUtils::Int32ToJsValue(env, MD_OK);
}

std::shared_ptr<asha::vrlib::MDVRLibraryAPI>& MD360PlayerNapi::GetLibrary() {
    return library_;
}

