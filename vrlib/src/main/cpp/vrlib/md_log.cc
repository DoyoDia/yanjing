//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "md_log.h"
#include <cstdarg>
#include <cstdio>
#include <hilog/log.h>
#include <string>

namespace asha {
namespace vrlib {

#define OHOS_LOG_BUF_SIZE 4096

#define LOG_TAG "MDVRLibrary"

static LogLevel ToOHLogLevel(MDLogLevel from) {
    switch (from) {
        case ERROR: return LOG_ERROR;
        case WARN: return LOG_WARN;
        case INFO: return LOG_INFO;
        case FATAL: return LOG_FATAL;
        case DEBUG: return LOG_DEBUG;
        default: return LOG_DEBUG;
    }
}

void MDLog::Log(MDLogLevel level, const char* tag, const char* fmt, ...) {
    char buf[OHOS_LOG_BUF_SIZE] = {0};
    va_list arg;
    va_start(arg, fmt);
    vsnprintf(buf, OHOS_LOG_BUF_SIZE, fmt, arg);
    va_end(arg);
    OH_LOG_Print(LOG_APP, ToOHLogLevel(level), LOG_DOMAIN, tag, "%{public}s", buf);
}

}
}

