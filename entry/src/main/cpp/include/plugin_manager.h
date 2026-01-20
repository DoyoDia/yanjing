/**
 * plugin_manager.h - 插件管理器
 * 管理 XComponent 与 Native 渲染器的绑定
 */

#ifndef PLUGIN_MANAGER_H
#define PLUGIN_MANAGER_H

#include <ace/xcomponent/native_interface_xcomponent.h>
#include <napi/native_api.h>
#include <string>
#include <unordered_map>
#include "panorama_renderer.h"

namespace PanoramaVR {

/**
 * 插件管理器类
 * 单例模式，管理多个 XComponent 实例与渲染器的映射
 */
class PluginManager {
public:
    static PluginManager& GetInstance();

    /**
     * 设置 NAPI 环境
     */
    void SetNapiEnv(napi_env env);

    /**
     * 获取 NAPI 环境
     */
    napi_env GetNapiEnv() const { return m_env; }

    /**
     * 注册 XComponent 回调
     */
    void RegisterXComponent(OH_NativeXComponent* xcomponent, const std::string& id);

    /**
     * 获取渲染器实例
     */
    PanoramaRenderer* GetRenderer(const std::string& id);

    /**
     * 移除渲染器实例
     */
    void RemoveRenderer(const std::string& id);

    /**
     * XComponent 回调函数
     */
    static void OnSurfaceCreated(OH_NativeXComponent* component, void* window);
    static void OnSurfaceChanged(OH_NativeXComponent* component, void* window);
    static void OnSurfaceDestroyed(OH_NativeXComponent* component, void* window);
    static void OnDispatchTouchEvent(OH_NativeXComponent* component, void* window);

private:
    PluginManager() = default;
    ~PluginManager() = default;
    PluginManager(const PluginManager&) = delete;
    PluginManager& operator=(const PluginManager&) = delete;

    /**
     * 获取 XComponent ID
     */
    static std::string GetXComponentId(OH_NativeXComponent* component);

private:
    napi_env m_env = nullptr;
    std::unordered_map<std::string, std::unique_ptr<PanoramaRenderer>> m_renderers;
    OH_NativeXComponent_Callback m_callback;
};

} // namespace PanoramaVR

#endif // PLUGIN_MANAGER_H
