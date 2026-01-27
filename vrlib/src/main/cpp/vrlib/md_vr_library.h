//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MD360PLAYER4OH_MD_VR_LIBRARY_H
#define MD360PLAYER4OH_MD_VR_LIBRARY_H

#include <string>
#include "md_lifecycle.h"

namespace asha {
namespace vrlib {

class MDVRLibraryAPI : public MD360LifecycleAPI {
public:
    static std::shared_ptr<MDVRLibraryAPI> CreateLibrary(); 
public:
    virtual int SetSurfaceId(std::string surface_id) = 0;
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

    // VR模式相关接口（新增）
    virtual void SetVRModeEnabled(bool enabled) = 0;
    virtual void SetIPD(float ipd) = 0;
    virtual void SetBarrelDistortionEnabled(bool enabled) = 0;
    virtual void SetBarrelDistortionParams(float k1, float k2, float scale) = 0;
    virtual void SetEyeOffset(float offset) = 0;
    virtual bool IsVRModeEnabled() = 0;
    
    // 运动传感器接口
    virtual void UpdateSensorMatrix(float* matrix) = 0;
};

}
};


#endif //MD360PLAYER4OH_MD_VR_LIBRARY_H

