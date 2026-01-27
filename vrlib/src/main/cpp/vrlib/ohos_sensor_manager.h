#ifndef OHOS_SENSOR_MANAGER_H
#define OHOS_SENSOR_MANAGER_H

#include <mutex>
#include <functional>
#include <vector>
#include "sensor_agent.h"

namespace ohos {
namespace vr {

// 使用sensor_agent.h中定义的SensorEvent结构体
using SensorEvent = ::ohos::sensors::SensorEvent;

// 使用sensor_agent.h中定义的CustomSensorEvent结构体
using CustomSensorEvent = ::ohos::sensors::CustomSensorEvent;

using SensorCallback = std::function<void(const CustomSensorEvent& event)>;

class OHOSSensorManager {
public:
    OHOSSensorManager();
    ~OHOSSensorManager();
    
    bool initialize();
    bool registerListener(const SensorCallback& callback);
    void unregisterListener();
    bool isAccelerometerSupported();
    bool isGyroscopeSupported();
    
private:
    static void onSensorDataCallback(::ohos::sensors::SensorEvent* event);
    static void onSensorAccuracyCallback(::ohos::sensors::SensorEvent* event);
    
    // 将OpenHarmony传感器事件转换为自定义事件
    CustomSensorEvent convertSensorEvent(const ::ohos::sensors::SensorEvent* event);
    
    std::mutex mMutex;
    SensorCallback mCallback;
    bool mInitialized;
    bool mListenerRegistered;
    
    // 传感器句柄 - 使用完整的命名空间
    ::ohos::sensors::SensorUser* mSensorUser;
    const ::ohos::sensors::SensorInfo* mAccelerometerInfo;
    const ::ohos::sensors::SensorInfo* mGyroscopeInfo;
};

} // namespace vr
} // namespace ohos

#endif // OHOS_SENSOR_MANAGER_H