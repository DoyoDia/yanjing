/**
 * plugin_manager.cpp - 插件管理器实现
 */

#include "include/plugin_manager.h"
#include <hilog/log.h>
#include <cstring>

#undef LOG_TAG
#define LOG_TAG "PluginManager"
#define LOGD(...) OH_LOG_DEBUG(LOG_APP, __VA_ARGS__)
#define LOGI(...) OH_LOG_INFO(LOG_APP, __VA_ARGS__)
#define LOGE(...) OH_LOG_ERROR(LOG_APP, __VA_ARGS__)

namespace PanoramaVR {

PluginManager& PluginManager::GetInstance() {
    static PluginManager instance;
    return instance;
}

void PluginManager::SetNapiEnv(napi_env env) {
    m_env = env;
}

std::string PluginManager::GetXComponentId(OH_NativeXComponent* component) {
    char idStr[OH_XCOMPONENT_ID_LEN_MAX + 1] = {0};
    uint64_t idSize = OH_XCOMPONENT_ID_LEN_MAX + 1;
    
    if (OH_NativeXComponent_GetXComponentId(component, idStr, &idSize) != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
        LOGE("Failed to get XComponent ID");
        return "";
    }
    
    return std::string(idStr);
}

void PluginManager::RegisterXComponent(OH_NativeXComponent* xcomponent, const std::string& id) {
    LOGI("Registering XComponent: %s", id.c_str());
    
    // 创建渲染器实例
    m_renderers[id] = std::make_unique<PanoramaRenderer>();
    
    // 设置回调
    m_callback.OnSurfaceCreated = OnSurfaceCreated;
    m_callback.OnSurfaceChanged = OnSurfaceChanged;
    m_callback.OnSurfaceDestroyed = OnSurfaceDestroyed;
    m_callback.DispatchTouchEvent = OnDispatchTouchEvent;
    
    OH_NativeXComponent_RegisterCallback(xcomponent, &m_callback);
}

PanoramaRenderer* PluginManager::GetRenderer(const std::string& id) {
    auto it = m_renderers.find(id);
    if (it != m_renderers.end()) {
        return it->second.get();
    }
    return nullptr;
}

void PluginManager::RemoveRenderer(const std::string& id) {
    auto it = m_renderers.find(id);
    if (it != m_renderers.end()) {
        it->second->Destroy();
        m_renderers.erase(it);
        LOGI("Renderer removed: %s", id.c_str());
    }
}

void PluginManager::OnSurfaceCreated(OH_NativeXComponent* component, void* window) {
    LOGI("OnSurfaceCreated");
    
    std::string id = GetXComponentId(component);
    if (id.empty()) return;
    
    auto& manager = GetInstance();
    PanoramaRenderer* renderer = manager.GetRenderer(id);
    
    if (renderer) {
        // 获取窗口大小
        uint64_t width, height;
        OH_NativeXComponent_GetXComponentSize(component, window, &width, &height);
        
        // 初始化渲染器
        if (renderer->Initialize(reinterpret_cast<EGLNativeWindowType>(window))) {
            renderer->SetViewport(static_cast<int>(width), static_cast<int>(height));
            LOGI("Renderer initialized with size: %lux%lu", width, height);
        } else {
            LOGE("Failed to initialize renderer");
        }
    }
}

void PluginManager::OnSurfaceChanged(OH_NativeXComponent* component, void* window) {
    LOGI("OnSurfaceChanged");
    
    std::string id = GetXComponentId(component);
    if (id.empty()) return;
    
    auto& manager = GetInstance();
    PanoramaRenderer* renderer = manager.GetRenderer(id);
    
    if (renderer && renderer->IsInitialized()) {
        uint64_t width, height;
        OH_NativeXComponent_GetXComponentSize(component, window, &width, &height);
        renderer->SetViewport(static_cast<int>(width), static_cast<int>(height));
        LOGI("Surface changed: %lux%lu", width, height);
    }
}

void PluginManager::OnSurfaceDestroyed(OH_NativeXComponent* component, void* window) {
    LOGI("OnSurfaceDestroyed");
    
    std::string id = GetXComponentId(component);
    if (id.empty()) return;
    
    auto& manager = GetInstance();
    manager.RemoveRenderer(id);
}

void PluginManager::OnDispatchTouchEvent(OH_NativeXComponent* component, void* window) {
    // 触摸事件处理（可用于手势控制，暂不实现）
}

} // namespace PanoramaVR
