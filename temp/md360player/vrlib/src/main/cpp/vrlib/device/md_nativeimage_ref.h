//
// Created on 2025/8/24.
//

#ifndef MD360PLAYER4OH_MD_NATIVEIMAGE_REF_H
#define MD360PLAYER4OH_MD_NATIVEIMAGE_REF_H

#include <native_image/native_image.h>

#include <memory>

namespace asha {
namespace vrlib {

class MDNativeImageRef {
public:
    MDNativeImageRef(int texture_id);
    ~MDNativeImageRef();
public:
    uint64_t GetSurfaceId();
    bool IsValid();
    int UpdateSurface(float* matrix);
    int GetTextureId();
private:
    OH_NativeImage* oh_image_ = nullptr;
    uint64_t surface_id_ = 0;
    int texture_id_ = 0;
};

}
}

#endif //MD360PLAYER4OH_MD_NATIVEIMAGE_REF_H

