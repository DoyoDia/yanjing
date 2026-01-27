#include "napi/native_api.h"
#include "napi/md360player_napi.h"

static volatile bool g_has_loaded = false;

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    
    if (!g_has_loaded) {
        g_has_loaded = true;
        auto binding_ret = MD360PlayerNapi::InitBindings(env, exports);
    }
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "md360player",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterMd360playerModule(void)
{
    napi_module_register(&demoModule);
}

