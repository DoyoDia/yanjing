//
// Created on 2025/8/24.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "md_egl.h"
#include "../md_defines.h"
#include "../md_log.h"
#include <iostream>
#include <string>
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <GLES2/gl2ext.h>
#include <sys/mman.h>
#include <native_image/native_image.h>
#include <native_window/external_window.h>
#include <native_buffer/native_buffer.h>

namespace asha {
namespace vrlib {

using GetPlatformDisplayExt = PFNEGLGETPLATFORMDISPLAYEXTPROC;
constexpr const char *EGL_EXT_PLATFORM_WAYLAND = "EGL_EXT_platform_wayland";
constexpr const char *EGL_KHR_PLATFORM_WAYLAND = "EGL_KHR_platform_wayland";
constexpr int32_t EGL_CONTEXT_CLIENT_VERSION_NUM = 2;
constexpr char CHARACTER_WHITESPACE = ' ';
constexpr const char *CHARACTER_STRING_WHITESPACE = " ";
constexpr const char *EGL_GET_PLATFORM_DISPLAY_EXT = "eglGetPlatformDisplayEXT";

// 检查egl扩展
static bool CheckEglExtension(const char *extensions, const char *extension) {
    size_t extlen = strlen(extension);
    const char *end = extensions + strlen(extensions);

    while (extensions < end) {
        size_t n = 0;
        if (*extensions == CHARACTER_WHITESPACE) {
            extensions++;
            continue;
        }
        n = strcspn(extensions, CHARACTER_STRING_WHITESPACE);
        if (n == extlen && strncmp(extension, extensions, n) == 0) {
            return true;
        }
        extensions += n;
    }
    return false;
}

// 获取当前的显示设备
static EGLDisplay GetPlatformEglDisplay(EGLenum platform, void *native_display, const EGLint *attrib_list) {
    static GetPlatformDisplayExt eglGetPlatformDisplayExt = NULL;

    if (!eglGetPlatformDisplayExt) {
        const char *extensions = eglQueryString(EGL_NO_DISPLAY, EGL_EXTENSIONS);
        if (extensions && (CheckEglExtension(extensions, EGL_EXT_PLATFORM_WAYLAND) ||
                           CheckEglExtension(extensions, EGL_KHR_PLATFORM_WAYLAND))) {
            eglGetPlatformDisplayExt = (GetPlatformDisplayExt)eglGetProcAddress(EGL_GET_PLATFORM_DISPLAY_EXT);
        }
    }

    if (eglGetPlatformDisplayExt) {
        return eglGetPlatformDisplayExt(platform, native_display, attrib_list);
    }

    return eglGetDisplay((EGLNativeDisplayType)native_display);
}


class MDEglV1 : public MDEgl {
public:
    virtual ~MDEglV1() = default;
    virtual int Prepare() override {
        InitContextInternal();
        InitWindowInternal();
        return MD_OK;
    }
    
    virtual int SetRenderWindow(std::shared_ptr<MDNativeWindowRef> window_ref) override {
        std::lock_guard<std::mutex> lock(window_mutex_);
        window_for_render_ = window_ref;
        return MD_OK;
    }
    
    virtual int MakeCurrent(bool current) override {
        if (IsEglValidateContext()) {
            if (current) {
                EGLSurface surface = eglSurface_ != EGL_NO_SURFACE ? eglSurface_ : eglPbSurface_;
                eglMakeCurrent(eglDisplay_, surface, surface, eglContext_);
            } else {
                // make nope
                eglMakeCurrent(eglDisplay_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
            }
        }
        return MD_OK;
    }
    
    virtual int SwapBuffer() override {
        if (IsEglValid()) {
            eglSwapBuffers(eglDisplay_, eglSurface_);    
        }
        return MD_OK;
    }
    
    virtual bool IsEglValid() override {
        return IsEglValidateContext() && IsEglValidateWindow();
    }
    
    virtual int Terminate() override {
        TerminateWindowInternal();
        TerminateContextInternal();
        return MD_OK;
    }
    
     virtual bool QuerySurface(EGLint attribute, EGLint* value) override {
        if (!IsEglValid() || value == nullptr) {
            return false;
        }
        
        EGLSurface surface = eglSurface_ != EGL_NO_SURFACE ? eglSurface_ : eglPbSurface_;
        if (surface == EGL_NO_SURFACE) {
            return false;
        }
        
        return eglQuerySurface(eglDisplay_, surface, attribute, value) == EGL_TRUE;
    }
    
private:
    bool IsEglValidateContext() {
        return eglContext_ != EGL_NO_CONTEXT && eglDisplay_ != EGL_NO_DISPLAY && config_ != EGL_NO_CONFIG_KHR && eglPbSurface_ != EGL_NO_SURFACE;
    }
    
    bool IsEglValidateWindow() {
        return eglSurface_ != EGL_NO_SURFACE;
    }
    
    int InitContextInternal() {
        if (IsEglValidateContext()) {
            return MD_OK;
        }
        // 获取当前的显示设备
        eglDisplay_ = GetPlatformEglDisplay(EGL_PLATFORM_OHOS_KHR, EGL_DEFAULT_DISPLAY, NULL);
        if (eglDisplay_ == EGL_NO_DISPLAY) {
            MD_LOGE("MDEglV1::Init Failed to create EGLDisplay gl errno :%d", eglGetError());
        }
    
        EGLint major, minor;
        // 初始化EGLDisplay
        if (eglInitialize(eglDisplay_, &major, &minor) == EGL_FALSE) {
            MD_LOGE("MDEglV1::Init Failed to initialize EGLDisplay");
        }
    
        // 绑定图形绘制的API为OpenGLES
        if (eglBindAPI(EGL_OPENGL_ES_API) == EGL_FALSE) {
            MD_LOGE("MDEglV1::Init Failed to bind OpenGL ES API");
        }
    
        unsigned int glRet;
        EGLint count;
        EGLint config_attribs[] = { EGL_SURFACE_TYPE,
                                    EGL_WINDOW_BIT | EGL_PBUFFER_BIT,
                                    EGL_SAMPLE_BUFFERS,
                                    EGL_FALSE,
                                    EGL_SAMPLES,
                                    0,
                                    EGL_RED_SIZE,
                                    8,
                                    EGL_GREEN_SIZE,
                                    8,
                                    EGL_BLUE_SIZE,
                                    8,
                                    EGL_ALPHA_SIZE,
                                    8,
                                    EGL_RENDERABLE_TYPE,
                                    EGL_OPENGL_ES2_BIT,
                                    EGL_NONE
        };
    
        // 获取一个有效的系统配置信息
        glRet = eglChooseConfig(eglDisplay_, config_attribs, &config_, 1, &count);
        if (!(glRet && static_cast<unsigned int>(count) >= 1)) {
            MD_LOGE("MDEglV1::Init Failed to eglChooseConfig");
        }
    
        static const EGLint context_attribs[] = {EGL_CONTEXT_CLIENT_VERSION, EGL_CONTEXT_CLIENT_VERSION_NUM, EGL_NONE};
    
        // 创建上下文
        eglContext_ = eglCreateContext(eglDisplay_, config_, EGL_NO_CONTEXT, context_attribs);
        if (eglContext_ == EGL_NO_CONTEXT) {
            MD_LOGE("MDEglV1::Init Failed to create egl context, error:%d", eglGetError());
        }
        
        {
            const EGLint pbuffer_attribs[] = {
                EGL_WIDTH, 16,
                EGL_HEIGHT, 16,
                EGL_NONE
            };
            eglPbSurface_ = eglCreatePbufferSurface(eglDisplay_, config_, pbuffer_attribs);
        }
        
        // EGL环境初始化完成
        MD_LOGI("MDEglV1::Init Create EGL context successfully, version %d.%d", major, minor);
        return MD_OK;
    }
    
    int TerminateWindowInternal() {
        if (IsEglValidateContext()) {
            eglMakeCurrent(eglDisplay_, EGL_NO_SURFACE, EGL_NO_SURFACE, eglContext_);
            eglDestroySurface(eglDisplay_, eglSurface_);
            eglSurface_ = EGL_NO_SURFACE;
        }
        return MD_OK;
    }
    
    int TerminateContextInternal() {
        if (IsEglValidateContext()) {
            if (eglPbSurface_ != EGL_NO_SURFACE) {
                eglMakeCurrent(eglDisplay_, EGL_NO_SURFACE, EGL_NO_SURFACE, eglContext_);
                eglDestroySurface(eglDisplay_, eglPbSurface_);
                eglPbSurface_ = EGL_NO_SURFACE;
            }
            if (eglContext_ != EGL_NO_CONTEXT) {
                eglMakeCurrent(eglDisplay_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
                eglDestroyContext(eglDisplay_, eglContext_);
                eglContext_ = EGL_NO_CONTEXT;
            }
            eglTerminate(eglDisplay_);
            eglDisplay_ = EGL_NO_DISPLAY;
            config_ = EGL_NO_CONFIG_KHR;
            window_used_ = nullptr;
            {
                std::lock_guard<std::mutex> lock(window_mutex_);
                window_for_render_ = nullptr;
            }
        }
        return MD_OK;
    }
    
    int InitWindowInternal() {
        std::shared_ptr<MDNativeWindowRef> window_ref = nullptr;
        {
            std::lock_guard<std::mutex> lock(window_mutex_);
            window_ref = window_for_render_;
        }
        if (window_ref == window_used_) {
            return MD_OK;
        }
        if (IsEglValidateWindow()) {
            TerminateWindowInternal();
            window_used_ = nullptr;
        }
        if (window_ref != nullptr && window_ref->IsValid()) {
            // 创建eglSurface
            EGLNativeWindowType nativeWindow = reinterpret_cast<EGLNativeWindowType>(window_ref->GetNativeWindow());
            eglSurface_ = eglCreateWindowSurface(eglDisplay_, config_, nativeWindow, NULL);
            if (eglSurface_ == EGL_NO_SURFACE) {
                MD_LOGE("MDEglV1::Init Failed to create egl surface, error:%d window:%p", eglGetError(), window_ref->GetNativeWindow());
            }
            window_used_ = window_ref;
        }
        return MD_OK;
    }
private:
    EGLContext eglContext_ = EGL_NO_CONTEXT;
    EGLDisplay eglDisplay_ = EGL_NO_DISPLAY;
    EGLConfig config_ = EGL_NO_CONFIG_KHR;
    EGLSurface eglSurface_ = EGL_NO_SURFACE;
    EGLSurface eglPbSurface_ = EGL_NO_SURFACE;
    std::shared_ptr<MDNativeWindowRef> window_used_ = nullptr;
    // 上屏window
    std::shared_ptr<MDNativeWindowRef> window_for_render_ = nullptr;
    std::mutex window_mutex_;
};


std::shared_ptr<MDEgl> MDEgl::CreateEgl() {
    auto egl = std::make_shared<MDEglV1>();
    return egl;
}

}
}

