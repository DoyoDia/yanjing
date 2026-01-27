//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "md_vr_library.h"
#include "md_log.h"
#include "md_defines.h"
#include "md_renderer.h"
#include <native_window/external_window.h>
#include <sstream>
#include "device/md_nativewindow_ref.h"

namespace asha {
namespace vrlib {


class MDVRLibraryOH : public MDVRLibraryAPI {
public:
    int SetSurfaceId(std::string surface_id) override {
        MD_LOGI("MDVRLibraryOH::SetSurfaceId:%s", surface_id.c_str());
        // // 根据SurfaceId创建NativeWindow，注意创建出来的NativeWindow在使用结束后需要主动调用OH_NativeWindow_DestoryNativeWindow进行释放。
        if (!surface_id.empty()) {
            uint64_t surface_id_ptr = 0;
            std::istringstream iss(surface_id);
            iss >> surface_id_ptr;
            OHNativeWindow* window = nullptr;
            int ret = OH_NativeWindow_CreateNativeWindowFromSurfaceId(surface_id_ptr, &window);
            if (ret == 0) {
                std::shared_ptr<MDNativeWindowRef> ref = std::make_shared<MDNativeWindowRef>(window);
                OH_NativeWindow_DestroyNativeWindow(window);
                renderer_->SetSurface(ref);
            }
            return ret;
        } else {
            renderer_->SetSurface(nullptr);
            return MD_OK;
        }
    }
    
    virtual void UpdateMVPMatrix(float* matrix) override {
        renderer_->UpdateMVPMatrix(matrix);
    }
    
    virtual void UpdateTouchDelta(float deltaX, float deltaY) override {
        renderer_->UpdateTouchDelta(deltaX, deltaY);
    }

    virtual int Init() override {
        return renderer_->Init();
    }
    
    virtual int Destroy() override {
        return renderer_->Destroy();
    }
    
    virtual int Resume() override {
        return renderer_->Resume();
    }
    
    virtual int Pause() override {
        return renderer_->Pause();
    }
    
    virtual uint64_t GetVideoSurfaceId() override {
        return renderer_->GetVideoSurfaceId();
    }
    
    virtual void SetClearColor(float r, float g, float b, float a) override {
        MD_LOGI("MDVRLibraryOH::SetClearColor called: r=%.3f, g=%.3f, b=%.3f, a=%.3f", r, g, b, a);
        renderer_->SetClearColor(r, g, b, a);
    }
    
    virtual void SetCullFaceEnabled(bool enabled) override {
        MD_LOGI("MDVRLibraryOH::SetCullFaceEnabled called: enabled=%s", enabled ? "true" : "false");
        renderer_->SetCullFaceEnabled(enabled);
    }
    
    virtual void SetDepthTestEnabled(bool enabled) override {
        MD_LOGI("MDVRLibraryOH::SetDepthTestEnabled called: enabled=%s", enabled ? "true" : "false");
        renderer_->SetDepthTestEnabled(enabled);
    }
    
    virtual void SetViewport(int x, int y, int width, int height) override {
        renderer_->SetViewport(x, y, width, height);
    }
    
    virtual void SetScissor(int x, int y, int width, int height) override {
        renderer_->SetScissor(x, y, width, height);
    }
    
    virtual void SetScissorEnabled(bool enabled) override {
        renderer_->SetScissorEnabled(enabled);
    }
    
    virtual void SetBlendEnabled(bool enabled) override {
        MD_LOGI("MDVRLibraryOH::SetBlendEnabled called: enabled=%s", enabled ? "true" : "false");
        renderer_->SetBlendEnabled(enabled);
    }
    
    virtual void SetBlendFunc(int src, int dst) override {
        MD_LOGI("MDVRLibraryOH::SetBlendFunc called: src=0x%x, dst=0x%x", src, dst);
        renderer_->SetBlendFunc(src, dst);
    }
    
    virtual void SetProjectionMode(int mode) override {
        MD_LOGI("MDVRLibraryOH::SetProjectionMode called: mode=%d", mode);
        renderer_->SetProjectionMode(mode);
    }

    // VR模式相关接口实现（新增）
    virtual void SetVRModeEnabled(bool enabled) override {
        MD_LOGI("MDVRLibraryOH::SetVRModeEnabled: %s", enabled ? "true" : "false");
        renderer_->SetVRModeEnabled(enabled);
    }

    virtual void SetIPD(float ipd) override {
        MD_LOGI("MDVRLibraryOH::SetIPD: %f", ipd);
        renderer_->SetIPD(ipd);
    }

    virtual void SetBarrelDistortionEnabled(bool enabled) override {
        MD_LOGI("MDVRLibraryOH::SetBarrelDistortionEnabled: %s", enabled ? "true" : "false");
        renderer_->SetBarrelDistortionEnabled(enabled);
    }

    virtual void SetBarrelDistortionParams(float k1, float k2, float scale) override {
        MD_LOGI("MDVRLibraryOH::SetBarrelDistortionParams: k1=%f, k2=%f, scale=%f", k1, k2, scale);
        renderer_->SetBarrelDistortionParams(k1, k2, scale);
    }

    virtual void SetEyeOffset(float offset) override {
        MD_LOGI("MDVRLibraryOH::SetEyeOffset: %f", offset);
        renderer_->SetEyeOffset(offset);
    }

    virtual bool IsVRModeEnabled() override {
        return renderer_->IsVRModeEnabled();
    }
    
    virtual void UpdateSensorMatrix(float* matrix) override {
        renderer_->UpdateSensorMatrix(matrix);
    }
   
private:
    std::shared_ptr<MD360RendererAPI> renderer_ = MD360RendererAPI::CreateRenderer();
};

std::shared_ptr<MDVRLibraryAPI> MDVRLibraryAPI::CreateLibrary() {
    auto library = std::make_shared<MDVRLibraryOH>();
    return library;
} 



}
};

