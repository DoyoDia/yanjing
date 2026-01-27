//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MD360PLAYER4OH_MD_LOG_H
#define MD360PLAYER4OH_MD_LOG_H


namespace asha {
namespace vrlib {

enum MDLogLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR,
    FATAL
};

class MDLog {
public:
    static void Log(MDLogLevel level, const char* tag, const char* fmt, ...);
};

}
}

#define MD_LOGI(...) asha::vrlib::MDLog::Log(asha::vrlib::INFO, "MDVRLibrary", __VA_ARGS__);
#define MD_LOGW(...) asha::vrlib::MDLog::Log(asha::vrlib::WARN, "MDVRLibrary", __VA_ARGS__);
#define MD_LOGE(...) asha::vrlib::MDLog::Log(asha::vrlib::ERROR, "MDVRLibrary", __VA_ARGS__);
#endif //MD360PLAYER4OH_MD_LOG_H

