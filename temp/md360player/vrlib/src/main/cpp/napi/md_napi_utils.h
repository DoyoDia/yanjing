//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef MD360PLAYER4OH_MD_NAPI_UTILS_H
#define MD360PLAYER4OH_MD_NAPI_UTILS_H
#include <string>
#include <js_native_api.h>

#define MD_GET_AND_THROW_LAST_ERROR(env)                                                    \
    do {                                                                                    \
        const napi_extended_error_info* errorInfo = nullptr;                                \
        napi_get_last_error_info((env),&errorInfo);                                         \
        bool isPending = false;                                                             \
        napi_is_exception_pending((env), &isPending);                                       \
        if (!isPending && errorInfo != nullptr) {                                           \
            napi_throw_error((env), nullptr, errorInfo->error_message);                     \
        }                                                                                   \
    } while (0)

#define MD_DECLARE_NAPI_FUNCTION(name, func)                                    \
{                                                                               \
    (name), nullptr, (func), nullptr, nullptr, nullptr, napi_default, nullptr    \
}


#define MD_NAPI_CALL_BASE(env, theCall, retVal)         \
    do {                                                \
        if ((theCall)!= napi_ok) {                      \
            MD_GET_AND_THROW_LAST_ERROR((env));         \
            return retVal;                              \
        }                                               \
    } while (0)


#define MD_NAPI_CALL(env, theCall) MD_NAPI_CALL_BASE(env, theCall, nullptr)

#define MD_NAPI_ASSERT_BASE(env, assert, message, retVal)       \
    do {                                                        \
        if(!(assert)){                                           \
            napi_throw_error((env),nullptr, "asser " #assert " failed:" message);      \
            return retVal;                                                                      \
        } \
    } while (0)

#define MD_NAPI_ASSERT(env, assertion, message) MD_NAPI_ASSERT_BASE(env, assertion, message, nullptr)

class MDNapiUtils {
public:
    static bool JsValueToBool(const napi_env &env, const napi_value &value, bool *target);
    static bool JsValueToInt32(const napi_env &env, const napi_value &value, int32_t *target);
    static bool JsValueToInt64(const napi_env &env, const napi_value &value, int64_t *target);
    static bool JsValueToBigInt64(const napi_env &env, const napi_value &value, int64_t *target);
    static bool JsValueToFloat(const napi_env &env, const napi_value &value, float *target);
    static bool JsValueToString(const napi_env &env, const napi_value &value, std::string *target);
    static napi_value BoolToJsValue(const napi_env &env, bool value);
    static napi_value Int32ToJsValue(const napi_env &env, const int32_t value);
    static napi_value Int64ToJsValue(const napi_env &env, const int64_t value);
    static napi_value Int64ToJsValueBigInt(const napi_env &env, const int64_t value);
    static napi_value FloatToJsValue(const napi_env &env, const float value);
    static napi_value StringTosValue(const napi_env &env, const std::string& value);
};

#endif //MD360PLAYER4OH_MD_NAPI_UTILS_H

