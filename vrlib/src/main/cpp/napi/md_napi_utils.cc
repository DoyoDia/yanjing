//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "md_napi_utils.h"
#include <locale>
#include <utility>
#include <codecvt>

bool MDNapiUtils::JsValueToBool(const napi_env &env, const napi_value &value, bool *target) {
    MD_NAPI_CALL_BASE(env, napi_get_value_bool(env, value, target), false);
    return true;
}

bool MDNapiUtils::JsValueToInt32(const napi_env &env, const napi_value &value, int32_t *target) {
    MD_NAPI_CALL_BASE(env, napi_get_value_int32(env, value, target), false);
    return true;
}

bool MDNapiUtils::JsValueToInt64(const napi_env &env, const napi_value &value, int64_t *target) {
    MD_NAPI_CALL_BASE(env, napi_get_value_int64(env, value, target), false);
    return true;
}
    
bool MDNapiUtils::JsValueToBigInt64(const napi_env &env, const napi_value &value, int64_t *target) {
    bool lossless = false;
    MD_NAPI_CALL_BASE(env, napi_get_value_bigint_int64(env, value, target, &lossless), false);
    return true;
}
bool MDNapiUtils::JsValueToFloat(const napi_env &env, const napi_value &value, float *target) {
    double f = 0.0;
    MD_NAPI_CALL_BASE(env, napi_get_value_double(env, value, &f), false);
    *target = (float)f;
    return true;
}

bool MDNapiUtils::JsValueToString(const napi_env &env, const napi_value &value, std::string *target) {
    size_t length;
    MD_NAPI_CALL_BASE(env, napi_get_value_string_utf16(env, value, nullptr, 0, &length), false);
    char16_t buf[length + 1];
    size_t result;
    MD_NAPI_CALL_BASE(env, napi_get_value_string_utf16(env, value, buf, length + 1, &result), false);
    std::wstring_convert<std::codecvt_utf8_utf16<char16_t>, char16_t> convert; 
    *target = convert.to_bytes(buf, buf + length);
    return true;
}

napi_value MDNapiUtils::BoolToJsValue(const napi_env &env, bool value) {
    napi_value temp;
    napi_create_int32(env, value == true ?1 :0, &temp);
    napi_value result;
    napi_coerce_to_bool(env, temp, &result);
    return result;
}

napi_value MDNapiUtils::Int32ToJsValue(const napi_env &env, const int32_t value) {
    napi_value result;
    napi_create_int32(env, value, &result);
    return result;
}

napi_value MDNapiUtils::Int64ToJsValue(const napi_env &env, const int64_t value) {
    napi_value result;
    napi_create_int64(env, value, &result);
    return result;
}
napi_value MDNapiUtils::Int64ToJsValueBigInt(const napi_env &env, const int64_t value) {
    napi_value result;
    napi_create_bigint_int64(env, value, &result);
    return result;
}

napi_value MDNapiUtils::FloatToJsValue(const napi_env &env, const float value) {
    napi_value result;
    napi_create_double(env, value, &result);
    return result;
}

napi_value MDNapiUtils::StringTosValue(const napi_env &env, const std::string& value) {
    napi_value result;
    napi_create_string_utf8(env, value.data(), value.size(), &result);
    return result;
}

