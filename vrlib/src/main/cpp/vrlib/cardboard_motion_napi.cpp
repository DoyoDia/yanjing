#include "cardboard_motion_napi.h"
#include <hilog/log.h>
#include "vrlib/cardboard_motion_strategy.h"

namespace ohos {
namespace vr {

static constexpr char TAG[] = "CardboardMotionNapi";

napi_value CardboardMotionNapi::Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "create", nullptr, Create, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "onResume", nullptr, OnResume, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "onPause", nullptr, OnPause, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "turnOn", nullptr, TurnOn, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "turnOff", nullptr, TurnOff, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "isSupport", nullptr, IsSupport, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setDirectors", nullptr, SetDirectors, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

napi_value CardboardMotionNapi::Create(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisVar = nullptr;
    
    napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    // 创建策略实例 - 修复：使用完整的限定名称
    CardboardMotionStrategy::StrategyParams params;
    auto strategy = new CardboardMotionStrategy(params);
    
    // 包装为NAPI对象
    napi_value result;
    napi_create_object(env, &result);
    
    napi_wrap(env, result, strategy, 
        [](napi_env env, void* data, void* hint) {
            // 自动清理
            auto strategy = reinterpret_cast<CardboardMotionStrategy*>(data);
            delete strategy;
            strategy = nullptr;
        }, 
        nullptr, nullptr);
    
    return result;
}

napi_value CardboardMotionNapi::OnResume(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisVar = nullptr;
    
    napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr);
    
    CardboardMotionStrategy* strategy = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&strategy));
    
    if (strategy) {
        strategy->onResume();
    }
    
    return nullptr;
}

napi_value CardboardMotionNapi::OnPause(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisVar = nullptr;
    
    napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr);
    
    CardboardMotionStrategy* strategy = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&strategy));
    
    if (strategy) {
        strategy->onPause();
    }
    
    return nullptr;
}

napi_value CardboardMotionNapi::TurnOn(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisVar = nullptr;
    
    napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr);
    
    CardboardMotionStrategy* strategy = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&strategy));
    
    if (strategy) {
        strategy->turnOnInGL();
    }
    
    return nullptr;
}

napi_value CardboardMotionNapi::TurnOff(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisVar = nullptr;
    
    napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr);
    
    CardboardMotionStrategy* strategy = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&strategy));
    
    if (strategy) {
        strategy->turnOffInGL();
    }
    
    return nullptr;
}

napi_value CardboardMotionNapi::IsSupport(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisVar = nullptr;
    
    napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr);
    
    CardboardMotionStrategy* strategy = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&strategy));
    
    napi_value result;
    if (strategy) {
        napi_get_boolean(env, strategy->isSupport(), &result);
    } else {
        napi_get_boolean(env, false, &result);
    }
    
    return result;
}

napi_value CardboardMotionNapi::SetDirectors(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_value thisVar = nullptr;
    
    napi_get_cb_info(env, info, &argc, args, &thisVar, nullptr);
    
    CardboardMotionStrategy* strategy = nullptr;
    napi_unwrap(env, thisVar, reinterpret_cast<void**>(&strategy));
    
    if (strategy && argc > 0) {
        // 解析director数组
        // 实现细节省略...
    }
    
    return nullptr;
}

} // namespace vr
} // namespace ohos