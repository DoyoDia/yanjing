//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MD360PLAYER4OH_MD_RENDERER_H
#define MD360PLAYER4OH_MD_RENDERER_H

#include <string>
#include "md_lifecycle.h"
#include "device/md_nativewindow_ref.h"

namespace asha {
namespace vrlib {

// 眼睛类型枚举
enum EyeType {
    LEFT_EYE = 0,
    RIGHT_EYE = 1
};

// VR模式配置结构体
struct VRModeConfig {
    bool enabled = false;
    bool barrelDistortionEnabled = true;
    float ipd = 0.064f; // 默认瞳距64mm
    float eyeOffset = 0.03f; // 默认单眼偏移量
    float k1 = -0.068f; // 桶形畸变参数k1
    float k2 = 0.32f; // 桶形畸变参数k2
    float scale = 0.95f; // 畸变缩放因子
};

class MD360RendererAPI : public MD360LifecycleAPI {
public:
    static std::shared_ptr<MD360RendererAPI> CreateRenderer(); 
public:
    virtual int SetSurface(std::shared_ptr<MDNativeWindowRef> ref) = 0;
    virtual int OnDrawFrame() = 0;
    virtual void UpdateMVPMatrix(float* matrix) = 0;
    virtual void UpdateTouchDelta(float deltaX, float deltaY) = 0;
    virtual uint64_t GetVideoSurfaceId() = 0;
    virtual void SetClearColor(float r, float g, float b, float a) = 0;
    virtual void SetCullFaceEnabled(bool enabled) = 0;
    virtual void SetDepthTestEnabled(bool enabled) = 0;
    virtual void SetViewport(int x, int y, int width, int height) = 0;
    virtual void SetScissor(int x, int y, int width, int height) = 0;
    virtual void SetScissorEnabled(bool enabled) = 0;
    virtual void SetBlendEnabled(bool enabled) = 0;
    virtual void SetBlendFunc(int src, int dst) = 0;
    virtual void SetProjectionMode(int mode) = 0;

    // 新增VR模式相关接口
    virtual void SetVRModeEnabled(bool enabled) = 0;
    virtual void SetIPD(float ipd) = 0;
    virtual void SetBarrelDistortionEnabled(bool enabled) = 0;
    virtual void SetBarrelDistortionParams(float k1, float k2, float scale) = 0;
    virtual void SetEyeOffset(float offset) = 0;
    virtual bool IsVRModeEnabled() const = 0;
    
    // 运动传感器接口
    virtual void UpdateSensorMatrix(float* matrix) = 0;
};

}
};


#endif //MD360PLAYER4OH_MD_RENDERER_H

