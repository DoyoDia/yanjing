//
// Created on 2025/8/24.
//

#ifndef MD360PLAYER4OH_MD_EGL_H
#define MD360PLAYER4OH_MD_EGL_H

#include <memory>
#include <EGL/egl.h>
#include "md_nativewindow_ref.h"
namespace asha {
namespace vrlib {

class MDEgl {
public:
    virtual int Prepare() = 0;
    virtual int MakeCurrent(bool current) = 0;
    virtual int SetRenderWindow(std::shared_ptr<MDNativeWindowRef> window_ref) = 0;
    virtual int SwapBuffer() = 0;
    virtual int Terminate() = 0;
    virtual bool IsEglValid() = 0;
    virtual bool QuerySurface(EGLint attribute, EGLint* value) = 0;
public:
    static std::shared_ptr<MDEgl> CreateEgl();
};

}
}

#endif //MD360PLAYER4OH_MD_EGL_H

