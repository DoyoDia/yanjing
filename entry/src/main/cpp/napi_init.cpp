/**
 * napi_init.cpp - NAPI 模块初始化
 * 提供 ArkTS 与 Native C++ 之间的接口
 */

#include <hilog/log.h>
#include <napi/native_api.h>
#include <ace/xcomponent/native_interface_xcomponent.h>
#include "include/plugin_manager.h"
#include "include/panorama_renderer.h"
#include <cstring>

#undef LOG_TAG
#define LOG_TAG "PanoramaNapi"
#define LOGI(...) OH_LOG_INFO(LOG_APP, __VA_ARGS__)
#define LOGE(...) OH_LOG_ERROR(LOG_APP, __VA_ARGS__)

using namespace PanoramaVR;

// 全局 XComponent ID
static std::string g_xcomponentId;

/**
 * 导出方法：渲染一帧
 */
static napi_value Render(napi_env env, napi_callback_info info) {
    PanoramaRenderer* renderer = PluginManager::GetInstance().GetRenderer(g_xcomponentId);
    if (renderer && renderer->IsInitialized()) {
        renderer->Render();
    }
    return nullptr;
}

/**
 * 导出方法：设置视图矩阵
 * 参数：Float32Array (16 个元素)
 */
static napi_value SetViewMatrix(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        LOGE("SetViewMatrix: Missing argument");
        return nullptr;
    }
    
    // 获取 TypedArray 信息
    napi_typedarray_type type;
    size_t length;
    void* data;
    napi_value arraybuffer;
    size_t offset;
    
    napi_status status = napi_get_typedarray_info(env, args[0], &type, &length, &data, &arraybuffer, &offset);
    if (status != napi_ok || type != napi_float32_array || length != 16) {
        LOGE("SetViewMatrix: Invalid argument, expected Float32Array with 16 elements");
        return nullptr;
    }
    
    PanoramaRenderer* renderer = PluginManager::GetInstance().GetRenderer(g_xcomponentId);
    if (renderer) {
        renderer->SetViewMatrix(static_cast<float*>(data));
    }
    
    return nullptr;
}

/**
 * 导出方法：设置分屏模式
 * 参数：boolean
 */
static napi_value SetStereoMode(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        return nullptr;
    }
    
    bool enabled;
    napi_get_value_bool(env, args[0], &enabled);
    
    PanoramaRenderer* renderer = PluginManager::GetInstance().GetRenderer(g_xcomponentId);
    if (renderer) {
        renderer->SetStereoMode(enabled);
        LOGI("Stereo mode: %s", enabled ? "enabled" : "disabled");
    }
    
    return nullptr;
}

/**
 * 导出方法：设置瞳距（IPD）
 * 参数：number (米)
 */
static napi_value SetIPD(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        return nullptr;
    }
    
    double ipd;
    napi_get_value_double(env, args[0], &ipd);
    
    PanoramaRenderer* renderer = PluginManager::GetInstance().GetRenderer(g_xcomponentId);
    if (renderer) {
        renderer->SetIPD(static_cast<float>(ipd));
        LOGI("IPD set to: %.3f m", ipd);
    }
    
    return nullptr;
}

/**
 * 导出方法：设置视场角（FOV）
 * 参数：number (度)
 */
static napi_value SetFOV(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1) {
        return nullptr;
    }

    double fov;
    napi_get_value_double(env, args[0], &fov);

    PanoramaRenderer* renderer = PluginManager::GetInstance().GetRenderer(g_xcomponentId);
    if (renderer) {
        renderer->SetFOV(static_cast<float>(fov));
        LOGI("FOV set to: %.2f deg", fov);
    }

    return nullptr;
}

// SetTexture deleted

/**
 * 导出方法：检查渲染器是否已初始化
 */
static napi_value IsInitialized(napi_env env, napi_callback_info info) {
    napi_value result;
    
    PanoramaRenderer* renderer = PluginManager::GetInstance().GetRenderer(g_xcomponentId);
    bool initialized = renderer && renderer->IsInitialized();
    
    napi_get_boolean(env, initialized, &result);
    return result;
}

/**
 * 导出方法：获取 Surface ID (字符串)
 */
static napi_value GetSurfaceId(napi_env env, napi_callback_info info) {
    napi_value result;
    
    PanoramaRenderer* renderer = PluginManager::GetInstance().GetRenderer(g_xcomponentId);
    if (!renderer) {
        napi_create_string_utf8(env, "", 0, &result);
        return result;
    }
    
    std::string surfaceId = renderer->GetSurfaceId();
    napi_create_string_utf8(env, surfaceId.c_str(), surfaceId.length(), &result);
    return result;
}

/**
 * NAPI 模块导出函数
 */
static napi_value Export(napi_env env, napi_value exports) {
    LOGI("Panorama renderer module initializing...");
    
    // 保存 NAPI 环境
    PluginManager::GetInstance().SetNapiEnv(env);
    
    // 获取 XComponent 实例
    napi_value xcomponentObj;
    napi_status status = napi_get_named_property(env, exports, "__NATIVE_XCOMPONENT_OBJ__", &xcomponentObj);
    
    if (status == napi_ok) {
        OH_NativeXComponent* xcomponent = nullptr;
        napi_unwrap(env, xcomponentObj, reinterpret_cast<void**>(&xcomponent));
        
        if (xcomponent) {
            // 获取 XComponent ID
            char idStr[OH_XCOMPONENT_ID_LEN_MAX + 1] = {0};
            uint64_t idSize = OH_XCOMPONENT_ID_LEN_MAX + 1;
            OH_NativeXComponent_GetXComponentId(xcomponent, idStr, &idSize);
            g_xcomponentId = std::string(idStr);
            
            // 注册 XComponent
            PluginManager::GetInstance().RegisterXComponent(xcomponent, g_xcomponentId);
            LOGI("XComponent registered: %s", g_xcomponentId.c_str());
        }
    }
    
    // 导出 GetSurfaceId
    napi_property_descriptor desc[] = {
        {"render", nullptr, Render, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setViewMatrix", nullptr, SetViewMatrix, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setStereoMode", nullptr, SetStereoMode, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setIPD", nullptr, SetIPD, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setFOV", nullptr, SetFOV, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"isInitialized", nullptr, IsInitialized, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getSurfaceId", nullptr, GetSurfaceId, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    
    LOGI("Panorama renderer module initialized");
    return exports;
}

/**
 * NAPI 模块注册
 */
static napi_module panoramaModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Export,
    .nm_modname = "panorama_renderer",
    .nm_priv = nullptr,
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterPanoramaModule(void) {
    napi_module_register(&panoramaModule);
}
