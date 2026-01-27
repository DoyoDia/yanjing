#ifndef CARDBOARD_MOTION_NAPI_H
#define CARDBOARD_MOTION_NAPI_H

#include <napi/native_api.h>
#include "vrlib/cardboard_motion_strategy.h"

namespace ohos {
namespace vr {

class CardboardMotionNapi {
public:
    static napi_value Init(napi_env env, napi_value exports);
    
private:
    static napi_value Create(napi_env env, napi_callback_info info);
    static napi_value OnResume(napi_env env, napi_callback_info info);
    static napi_value OnPause(napi_env env, napi_callback_info info);
    static napi_value TurnOn(napi_env env, napi_callback_info info);
    static napi_value TurnOff(napi_env env, napi_callback_info info);
    static napi_value IsSupport(napi_env env, napi_callback_info info);
    static napi_value SetDirectors(napi_env env, napi_callback_info info);
};

} // namespace vr
} // namespace ohos

#endif // CARDBOARD_MOTION_NAPI_H