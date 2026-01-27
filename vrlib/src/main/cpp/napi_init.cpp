#include "napi/native_api.h"
#include "vrlib/md_vr_library.h"
#include "vrlib/md_log.h"
#include "vrlib/motion_strategy.h"
#include <ace/xcomponent/native_interface_xcomponent.h>
#include <unordered_map>
#include <string>
#include <mutex>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "MD360Player"

using namespace asha::vrlib;

struct MD360PlayerWrapper {
    std::shared_ptr<MDVRLibraryAPI> impl;
    OH_NativeXComponent* component = nullptr;
};

// 全局映射：XComponent ID -> MD360PlayerWrapper
static std::unordered_map<std::string, MD360PlayerWrapper*> g_wrapper_map;
static std::mutex g_wrapper_map_mutex;

// XComponent 回调函数
static void OnSurfaceCreatedCB(OH_NativeXComponent* component, void* window) {
    MD_LOGI("OnSurfaceCreatedCB called");
    int32_t ret;
    char idStr[OH_XCOMPONENT_ID_LEN_MAX + 1] = {};
    uint64_t idSize = OH_XCOMPONENT_ID_LEN_MAX + 1;
    
    ret = OH_NativeXComponent_GetXComponentId(component, idStr, &idSize);
    if (ret != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
        MD_LOGE("OnSurfaceCreatedCB: Failed to get XComponent ID");
        return;
    }
    
    std::string id(idStr);
    std::lock_guard<std::mutex> lock(g_wrapper_map_mutex);
    auto it = g_wrapper_map.find(id);
    if (it != g_wrapper_map.end() && it->second != nullptr && it->second->impl != nullptr) {
        MD_LOGI("OnSurfaceCreatedCB: Found wrapper for ID: %s", id.c_str());
        // 初始化渲染器
        it->second->impl->Init();
    } else {
        MD_LOGW("OnSurfaceCreatedCB: No wrapper found for ID: %s", id.c_str());
    }
}

static void OnSurfaceChangedCB(OH_NativeXComponent* component, void* window) {
    MD_LOGI("OnSurfaceChangedCB called");
    // 可以在这里处理 Surface 大小变化
}

static void OnSurfaceDestroyedCB(OH_NativeXComponent* component, void* window) {
    MD_LOGI("OnSurfaceDestroyedCB called");
    int32_t ret;
    char idStr[OH_XCOMPONENT_ID_LEN_MAX + 1] = {};
    uint64_t idSize = OH_XCOMPONENT_ID_LEN_MAX + 1;
    
    ret = OH_NativeXComponent_GetXComponentId(component, idStr, &idSize);
    if (ret != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
        MD_LOGE("OnSurfaceDestroyedCB: Failed to get XComponent ID");
        return;
    }
    
    std::string id(idStr);
    std::lock_guard<std::mutex> lock(g_wrapper_map_mutex);
    auto it = g_wrapper_map.find(id);
    if (it != g_wrapper_map.end() && it->second != nullptr && it->second->impl != nullptr) {
        MD_LOGI("OnSurfaceDestroyedCB: Destroying renderer for ID: %s", id.c_str());
        it->second->impl->Destroy();
    }
}

// XComponent 回调结构
static OH_NativeXComponent_Callback g_xcomponent_callback = {
    .OnSurfaceCreated = OnSurfaceCreatedCB,
    .OnSurfaceChanged = OnSurfaceChangedCB,
    .OnSurfaceDestroyed = OnSurfaceDestroyedCB,
    .DispatchTouchEvent = nullptr
};

static void Destructor(napi_env env, void* nativeObject, void* finalize_hint) {
    MD360PlayerWrapper* wrapper = reinterpret_cast<MD360PlayerWrapper*>(nativeObject);
    if (wrapper != nullptr) {
        // 从全局映射中移除
        std::lock_guard<std::mutex> lock(g_wrapper_map_mutex);
        for (auto it = g_wrapper_map.begin(); it != g_wrapper_map.end();) {
            if (it->second == wrapper) {
                g_wrapper_map.erase(it++);
            } else {
                ++it;
            }
        }
        delete wrapper;
    }
}

static napi_value Constructor(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper = new MD360PlayerWrapper();
    wrapper->impl = MDVRLibraryAPI::CreateLibrary();

    napi_wrap(env, jsThis, wrapper, Destructor, nullptr, nullptr);
    
    // 尝试获取 XComponent ID 并添加到全局映射
    // 注意：此时 XComponent 可能还没有准备好，所以这里只是尝试
    napi_value exportInstance = nullptr;
    OH_NativeXComponent* nativeXComponent = nullptr;
    napi_status status = napi_get_named_property(env, jsThis, OH_NATIVE_XCOMPONENT_OBJ, &exportInstance);
    if (status == napi_ok) {
        status = napi_unwrap(env, exportInstance, reinterpret_cast<void**>(&nativeXComponent));
        if (status == napi_ok && nativeXComponent != nullptr) {
            char idStr[OH_XCOMPONENT_ID_LEN_MAX + 1] = {};
            uint64_t idSize = OH_XCOMPONENT_ID_LEN_MAX + 1;
            int32_t ret = OH_NativeXComponent_GetXComponentId(nativeXComponent, idStr, &idSize);
            if (ret == OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
                std::string id(idStr);
                wrapper->component = nativeXComponent;
                std::lock_guard<std::mutex> lock(g_wrapper_map_mutex);
                // 如果已存在相同ID的wrapper，先清理旧的
                auto existing = g_wrapper_map.find(id);
                if (existing != g_wrapper_map.end() && existing->second != nullptr) {
                    MD_LOGW("Constructor: Replacing existing wrapper for ID: %s", id.c_str());
                }
                g_wrapper_map[id] = wrapper;
                MD_LOGI("Constructor: Registered wrapper for XComponent ID: %s", id.c_str());
                
                // 注册回调（如果还没有注册）
                ret = OH_NativeXComponent_RegisterCallback(nativeXComponent, &g_xcomponent_callback);
                if (ret == OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
                    MD_LOGI("Constructor: XComponent callbacks registered");
                }
            }
        }
    }
    
    return jsThis;
}

static napi_value SetSurfaceId(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr) {
        return nullptr;
    }

    size_t strSize;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &strSize);
    std::string surfaceId(strSize, '\0');
    napi_get_value_string_utf8(env, args[0], &surfaceId[0], strSize + 1, &strSize);

    // 尝试获取并注册 XComponent 回调（如果还没有注册）
    if (wrapper->component == nullptr) {
        napi_value exportInstance = nullptr;
        OH_NativeXComponent* nativeXComponent = nullptr;
        napi_status status = napi_get_named_property(env, jsThis, OH_NATIVE_XCOMPONENT_OBJ, &exportInstance);
        if (status == napi_ok) {
            status = napi_unwrap(env, exportInstance, reinterpret_cast<void**>(&nativeXComponent));
            if (status == napi_ok && nativeXComponent != nullptr) {
                wrapper->component = nativeXComponent;
                char idStr[OH_XCOMPONENT_ID_LEN_MAX + 1] = {};
                uint64_t idSize = OH_XCOMPONENT_ID_LEN_MAX + 1;
                int32_t ret = OH_NativeXComponent_GetXComponentId(nativeXComponent, idStr, &idSize);
                if (ret == OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
                    std::string id(idStr);
                    std::lock_guard<std::mutex> lock(g_wrapper_map_mutex);
                    // 如果已存在相同ID的wrapper，先清理旧的
                    auto existing = g_wrapper_map.find(id);
                    if (existing != g_wrapper_map.end() && existing->second != nullptr) {
                        MD_LOGW("SetSurfaceId: Replacing existing wrapper for ID: %s", id.c_str());
                    }
                    g_wrapper_map[id] = wrapper;
                    ret = OH_NativeXComponent_RegisterCallback(nativeXComponent, &g_xcomponent_callback);
                    if (ret == OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
                        MD_LOGI("SetSurfaceId: XComponent callbacks registered for ID: %s", id.c_str());
                    }
                }
            }
        }
    }

    int result = wrapper->impl->SetSurfaceId(surfaceId);
    
    napi_value ret;
    napi_create_int32(env, result, &ret);
    return ret;
}

static napi_value RunCmd(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr) {
        return nullptr;
    }

    int32_t cmd;
    napi_get_value_int32(env, args[0], &cmd);

    int result = 0;
    switch(cmd) {
        case 1: result = wrapper->impl->Init(); break;
        case 2: result = wrapper->impl->Destroy(); break;
        case 3: result = wrapper->impl->Resume(); break;
        case 4: result = wrapper->impl->Pause(); break;
        default: break;
    }

    napi_value ret;
    napi_create_int32(env, result, &ret);
    return ret;
}

static napi_value UpdateMVPMatrix(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr) {
        return nullptr;
    }

    bool isArray;
    napi_is_array(env, args[0], &isArray);
    if (!isArray) return nullptr;

    uint32_t length;
    napi_get_array_length(env, args[0], &length);
    
    float matrix[16];
    for (uint32_t i = 0; i < length && i < 16; i++) {
        napi_value element;
        napi_get_element(env, args[0], i, &element);
        double val;
        napi_get_value_double(env, element, &val);
        matrix[i] = (float)val;
    }

    wrapper->impl->UpdateMVPMatrix(matrix);
    return nullptr;
}

static napi_value UpdateTouchDelta(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 2) {
        return nullptr;
    }

    double deltaX, deltaY;
    napi_get_value_double(env, args[0], &deltaX);
    napi_get_value_double(env, args[1], &deltaY);

    wrapper->impl->UpdateTouchDelta((float)deltaX, (float)deltaY);
    return nullptr;
}

static napi_value GetVideoSurfaceId(napi_env env, napi_callback_info info) {
    napi_value jsThis;
    napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr) {
        MD_LOGE("GetVideoSurfaceId: wrapper or impl is null");
        napi_value nullValue;
        napi_get_null(env, &nullValue);
        return nullValue;
    }

    uint64_t surfaceId = wrapper->impl->GetVideoSurfaceId();
    MD_LOGI("GetVideoSurfaceId: Got surfaceId from C++: %llu", (unsigned long long)surfaceId);
    
    // 将 uint64_t 转换为字符串（因为 surfaceId 在 HarmonyOS 中通常以字符串形式传递）
    char surfaceIdStr[32];
    snprintf(surfaceIdStr, sizeof(surfaceIdStr), "%llu", (unsigned long long)surfaceId);
    MD_LOGI("GetVideoSurfaceId: Converting to string: %s", surfaceIdStr);
    
    napi_value result;
    napi_create_string_utf8(env, surfaceIdStr, NAPI_AUTO_LENGTH, &result);
    return result;
}

static napi_value SetClearColor(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value args[4];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 4) {
        return nullptr;
    }

    double r, g, b, a;
    napi_get_value_double(env, args[0], &r);
    napi_get_value_double(env, args[1], &g);
    napi_get_value_double(env, args[2], &b);
    napi_get_value_double(env, args[3], &a);

    MD_LOGI("NAPI SetClearColor called: r=%.3f, g=%.3f, b=%.3f, a=%.3f", r, g, b, a);
    wrapper->impl->SetClearColor((float)r, (float)g, (float)b, (float)a);
    return nullptr;
}

static napi_value SetCullFaceEnabled(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 1) {
        return nullptr;
    }

    bool enabled;
    napi_get_value_bool(env, args[0], &enabled);

    MD_LOGI("NAPI SetCullFaceEnabled called: enabled=%s", enabled ? "true" : "false");
    wrapper->impl->SetCullFaceEnabled(enabled);
    return nullptr;
}

static napi_value SetDepthTestEnabled(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 1) {
        return nullptr;
    }

    bool enabled;
    napi_get_value_bool(env, args[0], &enabled);

    MD_LOGI("NAPI SetDepthTestEnabled called: enabled=%s", enabled ? "true" : "false");
    wrapper->impl->SetDepthTestEnabled(enabled);
    return nullptr;
}

static napi_value SetViewport(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value args[4];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 4) {
        return nullptr;
    }

    int32_t x, y, width, height;
    napi_get_value_int32(env, args[0], &x);
    napi_get_value_int32(env, args[1], &y);
    napi_get_value_int32(env, args[2], &width);
    napi_get_value_int32(env, args[3], &height);

    wrapper->impl->SetViewport(x, y, width, height);
    return nullptr;
}

static napi_value SetScissor(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value args[4];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 4) {
        return nullptr;
    }

    int32_t x, y, width, height;
    napi_get_value_int32(env, args[0], &x);
    napi_get_value_int32(env, args[1], &y);
    napi_get_value_int32(env, args[2], &width);
    napi_get_value_int32(env, args[3], &height);

    wrapper->impl->SetScissor(x, y, width, height);
    return nullptr;
}

static napi_value SetScissorEnabled(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 1) {
        return nullptr;
    }

    bool enabled;
    napi_get_value_bool(env, args[0], &enabled);

    wrapper->impl->SetScissorEnabled(enabled);
    return nullptr;
}

static napi_value SetBlendEnabled(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 1) {
        return nullptr;
    }

    bool enabled;
    napi_get_value_bool(env, args[0], &enabled);

    MD_LOGI("NAPI SetBlendEnabled called: enabled=%s", enabled ? "true" : "false");
    wrapper->impl->SetBlendEnabled(enabled);
    return nullptr;
}

static napi_value SetBlendFunc(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 2) {
        return nullptr;
    }

    int32_t src, dst;
    napi_get_value_int32(env, args[0], &src);
    napi_get_value_int32(env, args[1], &dst);

    MD_LOGI("NAPI SetBlendFunc called: src=0x%x, dst=0x%x", src, dst);
    wrapper->impl->SetBlendFunc(src, dst);
    return nullptr;
}

static napi_value SetProjectionMode(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 1) {
        return nullptr;
    }

    int32_t mode;
    napi_get_value_int32(env, args[0], &mode);

    MD_LOGI("NAPI SetProjectionMode called: mode=%d", mode);
    wrapper->impl->SetProjectionMode(mode);
    return nullptr;
}

// VR模式相关方法（新增）
static napi_value SetVRModeEnabled(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 1) {
        napi_value result;
        napi_create_int32(env, -1, &result);
        return result;
    }

    bool enabled;
    napi_get_value_bool(env, args[0], &enabled);

    MD_LOGI("NAPI SetVRModeEnabled called: enabled=%s", enabled ? "true" : "false");
    wrapper->impl->SetVRModeEnabled(enabled);
    
    napi_value result;
    napi_create_int32(env, 0, &result);
    return result;
}

static napi_value SetIPD(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 1) {
        napi_value result;
        napi_create_int32(env, -1, &result);
        return result;
    }

    double ipd;
    napi_get_value_double(env, args[0], &ipd);

    MD_LOGI("NAPI SetIPD called: ipd=%f", (float)ipd);
    wrapper->impl->SetIPD((float)ipd);
    
    napi_value result;
    napi_create_int32(env, 0, &result);
    return result;
}

static napi_value SetBarrelDistortionEnabled(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 1) {
        napi_value result;
        napi_create_int32(env, -1, &result);
        return result;
    }

    bool enabled;
    napi_get_value_bool(env, args[0], &enabled);

    MD_LOGI("NAPI SetBarrelDistortionEnabled called: enabled=%s", enabled ? "true" : "false");
    wrapper->impl->SetBarrelDistortionEnabled(enabled);
    
    napi_value result;
    napi_create_int32(env, 0, &result);
    return result;
}

static napi_value SetBarrelDistortionParams(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    MD360PlayerWrapper* wrapper;
    napi_unwrap(env, jsThis, (void**)&wrapper);

    if (wrapper == nullptr || wrapper->impl == nullptr || argc < 3) {
        napi_value result;
        napi_create_int32(env, -1, &result);
        return result;
    }

    double k1, k2, scale;
    napi_get_value_double(env, args[0], &k1);
    napi_get_value_double(env, args[1], &k2);
    napi_get_value_double(env, args[2], &scale);

    MD_LOGI("NAPI SetBarrelDistortionParams called: k1=%f, k2=%f, scale=%f", (float)k1, (float)k2, (float)scale);
    wrapper->impl->SetBarrelDistortionParams((float)k1, (float)k2, (float)scale);
    
    napi_value result;
    napi_create_int32(env, 0, &result);
    return result;
}

// 获取并注册 XComponent 回调
static void RegisterXComponentCallback(napi_env env, napi_value exports) {
    napi_value exportInstance = nullptr;
    OH_NativeXComponent* nativeXComponent = nullptr;
    napi_status status;
    int32_t ret;
    char idStr[OH_XCOMPONENT_ID_LEN_MAX + 1] = {};
    uint64_t idSize = OH_XCOMPONENT_ID_LEN_MAX + 1;
    
    // 尝试获取 XComponent 实例
    status = napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ, &exportInstance);
    if (status != napi_ok) {
        MD_LOGI("RegisterXComponentCallback: No XComponent found, will register later");
        return;
    }
    
    status = napi_unwrap(env, exportInstance, reinterpret_cast<void**>(&nativeXComponent));
    if (status != napi_ok || nativeXComponent == nullptr) {
        MD_LOGE("RegisterXComponentCallback: Failed to unwrap XComponent");
        return;
    }
    
    ret = OH_NativeXComponent_GetXComponentId(nativeXComponent, idStr, &idSize);
    if (ret != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
        MD_LOGE("RegisterXComponentCallback: Failed to get XComponent ID");
        return;
    }
    
    std::string id(idStr);
    MD_LOGI("RegisterXComponentCallback: Registering callbacks for XComponent ID: %s", id.c_str());
    
    // 注册回调
    ret = OH_NativeXComponent_RegisterCallback(nativeXComponent, &g_xcomponent_callback);
    if (ret != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
        MD_LOGE("RegisterXComponentCallback: Failed to register callbacks, error: %d", ret);
        return;
    }
    
    // 将 XComponent 实例保存到全局映射中（如果已有对应的 wrapper）
    std::lock_guard<std::mutex> lock(g_wrapper_map_mutex);
    auto it = g_wrapper_map.find(id);
    if (it != g_wrapper_map.end() && it->second != nullptr) {
        it->second->component = nativeXComponent;
        MD_LOGI("RegisterXComponentCallback: Linked XComponent to existing wrapper");
    } else {
        MD_LOGI("RegisterXComponentCallback: XComponent registered, wrapper will be linked later");
    }
}

static MotionStrategy g_motionStrategy;

static napi_value TurnOnGyro(napi_env env, napi_callback_info info) {
    MD_LOGI("NAPI TurnOnGyro called");
    g_motionStrategy.turnOn();
    return nullptr;
}

static napi_value TurnOffGyro(napi_env env, napi_callback_info info) {
    MD_LOGI("NAPI TurnOffGyro called");
    g_motionStrategy.turnOff();
    return nullptr;
}

static napi_value TurnOnInGL(napi_env env, napi_callback_info info) {
    MD_LOGI("NAPI TurnOnInGL called");
    g_motionStrategy.turnOnInGL();
    return nullptr;
}

static napi_value TurnOffInGL(napi_env env, napi_callback_info info) {
    MD_LOGI("NAPI TurnOffInGL called");
    g_motionStrategy.turnOffInGL();
    return nullptr;
}

static napi_value HandleDrag(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    if (argc < 2) {
        napi_value ret;
        napi_get_boolean(env, false, &ret);
        return ret;
    }

    int32_t distanceX, distanceY;
    napi_get_value_int32(env, args[0], &distanceX);
    napi_get_value_int32(env, args[1], &distanceY);

    MD_LOGI("NAPI HandleDrag called: distanceX=%d, distanceY=%d", distanceX, distanceY);
    bool result = g_motionStrategy.handleDrag(distanceX, distanceY);
    
    napi_value ret;
    napi_get_boolean(env, result, &ret);
    return ret;
}

static napi_value OnResume(napi_env env, napi_callback_info info) {
    MD_LOGI("NAPI OnResume called");
    g_motionStrategy.onResume();
    return nullptr;
}

static napi_value OnPause(napi_env env, napi_callback_info info) {
    MD_LOGI("NAPI OnPause called");
    g_motionStrategy.onPause();
    return nullptr;
}

static napi_value IsSupport(napi_env env, napi_callback_info info) {
    MD_LOGI("NAPI IsSupport called");
    bool result = g_motionStrategy.isSupport();
    
    napi_value ret;
    napi_get_boolean(env, result, &ret);
    return ret;
}

static napi_value GetSensorMatrix(napi_env env, napi_callback_info info) {
    Matrix4x4 matrix;
    g_motionStrategy.getSensorMatrix(matrix);
    
    // 将C++矩阵转换为JS数组
    napi_value jsMatrix;
    napi_create_array(env, &jsMatrix);
    
    for (int i = 0; i < 16; i++) {
        napi_value val;
        napi_create_double(env, matrix[i], &val);
        napi_set_element(env, jsMatrix, i, val);
    }
    
    return jsMatrix;
}

static napi_value UpdateGyroData(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value args[4];
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);

    if (argc < 4) {
        return nullptr;
    }

    double quatX, quatY, quatZ, quatW;
    napi_get_value_double(env, args[0], &quatX);
    napi_get_value_double(env, args[1], &quatY);
    napi_get_value_double(env, args[2], &quatZ);
    napi_get_value_double(env, args[3], &quatW);

    MD_LOGI("NAPI UpdateGyroData called: x=%.3f, y=%.3f, z=%.3f, w=%.3f", quatX, quatY, quatZ, quatW);
    
    // 更新 MotionStrategy
    g_motionStrategy.UpdateGyroData((float)quatX, (float)quatY, (float)quatZ, (float)quatW);
    
    // 获取传感器矩阵并传递给渲染器
    MD360PlayerWrapper* wrapper;
    napi_status status = napi_unwrap(env, jsThis, (void**)&wrapper);
    if (status == napi_ok && wrapper != nullptr && wrapper->impl != nullptr) {
        Matrix4x4 sensorMatrix;
        g_motionStrategy.getSensorMatrix(sensorMatrix);
        wrapper->impl->UpdateSensorMatrix(sensorMatrix);
    }
    
    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    // 尝试注册 XComponent 回调
    RegisterXComponentCallback(env, exports);
    
    napi_property_descriptor desc[] = {
        { "setSurfaceId", nullptr, SetSurfaceId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "runCmd", nullptr, RunCmd, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "updateMVPMatrix", nullptr, UpdateMVPMatrix, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "updateTouchDelta", nullptr, UpdateTouchDelta, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getVideoSurfaceId", nullptr, GetVideoSurfaceId, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setClearColor", nullptr, SetClearColor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCullFaceEnabled", nullptr, SetCullFaceEnabled, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setDepthTestEnabled", nullptr, SetDepthTestEnabled, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setViewport", nullptr, SetViewport, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setScissor", nullptr, SetScissor, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setScissorEnabled", nullptr, SetScissorEnabled, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBlendEnabled", nullptr, SetBlendEnabled, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBlendFunc", nullptr, SetBlendFunc, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setProjectionMode", nullptr, SetProjectionMode, nullptr, nullptr, nullptr, napi_default, nullptr },
        // VR模式相关方法（新增）
        { "setVRModeEnabled", nullptr, SetVRModeEnabled, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setIPD", nullptr, SetIPD, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBarrelDistortionEnabled", nullptr, SetBarrelDistortionEnabled, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setBarrelDistortionParams", nullptr, SetBarrelDistortionParams, nullptr, nullptr, nullptr, napi_default, nullptr },
        //陀螺仪
        { "turnOnGyro", nullptr, TurnOnGyro, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "turnOffGyro", nullptr, TurnOffGyro, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "turnOnInGL", nullptr, TurnOnInGL, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "turnOffInGL", nullptr, TurnOffInGL, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "handleDrag", nullptr, HandleDrag, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "updateGyroData", nullptr, UpdateGyroData, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getSensorMatrix", nullptr, GetSensorMatrix, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "onResume", nullptr, OnResume, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "onPause", nullptr, OnPause, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "isSupport", nullptr, IsSupport, nullptr, nullptr, nullptr, napi_default, nullptr }
    };

    napi_value cons;
    napi_define_class(env, "MD360Player", NAPI_AUTO_LENGTH, Constructor, nullptr, sizeof(desc) / sizeof(desc[0]), desc, &cons);

    napi_set_named_property(env, exports, "MD360Player", cons);

    napi_value cmdEnum;
    napi_create_object(env, &cmdEnum);
    
    napi_value val;
    napi_create_int32(env, 0, &val);
    napi_set_named_property(env, cmdEnum, "UNKNOWN", val);
    napi_create_int32(env, 1, &val);
    napi_set_named_property(env, cmdEnum, "INIT", val);
    napi_create_int32(env, 2, &val);
    napi_set_named_property(env, cmdEnum, "DESTROY", val);
    napi_create_int32(env, 3, &val);
    napi_set_named_property(env, cmdEnum, "RESUME", val);
    napi_create_int32(env, 4, &val);
    napi_set_named_property(env, cmdEnum, "PAUSE", val);

    napi_set_named_property(env, exports, "MD360PlayerCmd", cmdEnum);

    return exports;
}
EXTERN_C_END

static napi_module md360player_module = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "md360player",
    .nm_priv = ((void*)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterMD360PlayerModule(void) {
    napi_module_register(&md360player_module);
}
