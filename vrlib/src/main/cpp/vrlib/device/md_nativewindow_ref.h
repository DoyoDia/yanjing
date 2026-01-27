//
// Created on 2025/8/24.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MD360PLAYER4OH_MD_NATIVEWINDOW_REF_H
#define MD360PLAYER4OH_MD_NATIVEWINDOW_REF_H

#include <native_window/external_window.h>

#include <memory>

namespace asha {
namespace vrlib {

class MDNativeWindowRef {
public:
    MDNativeWindowRef(OHNativeWindow* window);
    ~MDNativeWindowRef();
public:
    OHNativeWindow* GetNativeWindow();
    bool IsValid();
private:
    OHNativeWindow* window_ = nullptr;
};

}
}

#endif //MD360PLAYER4OH_MD_NATIVEWINDOW_REF_H

