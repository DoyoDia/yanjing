//
// Created on 2025/8/24.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".


#include "md_nativewindow_ref.h"

namespace asha {
namespace vrlib {

MDNativeWindowRef::MDNativeWindowRef(OHNativeWindow* window) {
    window_ = window;
    if (window_) {
        OH_NativeWindow_NativeObjectReference(window_);
    }
}

MDNativeWindowRef::~MDNativeWindowRef() {
    if (window_) {
        OH_NativeWindow_NativeObjectUnreference(window_);
    }
    window_ = nullptr;
}

OHNativeWindow* MDNativeWindowRef::GetNativeWindow() {
    return window_;
}

bool MDNativeWindowRef::IsValid() {
    return window_ != nullptr;
}

}
}


