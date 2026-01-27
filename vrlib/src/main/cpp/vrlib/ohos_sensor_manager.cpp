#include "ohos_sensor_manager.h"
#include <hilog/log.h>
#include "sensor_agent.h"
#include <cstring>  // 添加memcpy支持

namespace ohos {
namespace vr {

static constexpr char TAG[] = "OHOSSensorManager";
static OHOSSensorManager* gInstance = nullptr;

OHOSSensorManager::OHOSSensorManager() 
    : mInitialized(false), mListenerRegistered(false), mSensorUser(nullptr),
      mAccelerometerInfo(nullptr), mGyroscopeInfo(nullptr) {
}

OHOSSensorManager::~OHOSSensorManager() {
    unregisterListener();
    if (mSensorUser) {
        ::ohos::sensors::DestroySensorUser(mSensorUser);
        mSensorUser = nullptr;
    }
    gInstance = nullptr;
}

bool OHOSSensorManager::initialize() {
    if (mInitialized) return true;
    
    int32_t ret = ::ohos::sensors::CreateSensorUser(&mSensorUser);
    if (ret != 0 || mSensorUser == nullptr) {
        return false;
    }
    
    // 获取传感器列表
    ::ohos::sensors::SensorInfo* sensorInfos = nullptr;
    int32_t count = 0;
    if (::ohos::sensors::GetAllSensors(&sensorInfos, &count) == 0) {
        for (int32_t i = 0; i < count; ++i) {
            if (sensorInfos[i].sensorTypeId == ::ohos::sensors::SENSOR_TYPE_ACCELEROMETER) {
                mAccelerometerInfo = &sensorInfos[i];
            } else if (sensorInfos[i].sensorTypeId == ::ohos::sensors::SENSOR_TYPE_GYROSCOPE) {
                mGyroscopeInfo = &sensorInfos[i];
            }
        }
    }
    
    mInitialized = true;
    gInstance = this;
    return true;
}

bool OHOSSensorManager::registerListener(const SensorCallback& callback) {
    if (!mInitialized || mListenerRegistered) return false;
    
    mCallback = callback;
    
    // 订阅加速度计
    if (mAccelerometerInfo) {
        int32_t ret = ::ohos::sensors::SubscribeSensor(mSensorUser, ::ohos::sensors::SENSOR_TYPE_ACCELEROMETER);
        if (ret != 0) {
            return false;
        }
    }
    
    // 订阅陀螺仪
    if (mGyroscopeInfo) {
        int32_t ret = ::ohos::sensors::SubscribeSensor(mSensorUser, ::ohos::sensors::SENSOR_TYPE_GYROSCOPE);
        if (ret != 0) {
            return false;
        }
    }
    
    // 设置数据回调
    ::ohos::sensors::SetSensorEventCallback(mSensorUser, onSensorDataCallback);
    ::ohos::sensors::SetSensorAccuracyCallback(mSensorUser, onSensorAccuracyCallback);
    
    // 激活传感器
    if (mAccelerometerInfo) {
        ::ohos::sensors::ActivateSensor(mSensorUser, ::ohos::sensors::SENSOR_TYPE_ACCELEROMETER);
    }
    if (mGyroscopeInfo) {
        ::ohos::sensors::ActivateSensor(mSensorUser, ::ohos::sensors::SENSOR_TYPE_GYROSCOPE);
    }
    
    mListenerRegistered = true;
    return true;
}

void OHOSSensorManager::unregisterListener() {
    if (!mListenerRegistered) return;
    
    // 停用传感器
    if (mAccelerometerInfo) {
        ::ohos::sensors::DeactivateSensor(mSensorUser, ::ohos::sensors::SENSOR_TYPE_ACCELEROMETER);
        ::ohos::sensors::UnsubscribeSensor(mSensorUser, ::ohos::sensors::SENSOR_TYPE_ACCELEROMETER);
    }
    if (mGyroscopeInfo) {
        ::ohos::sensors::DeactivateSensor(mSensorUser, ::ohos::sensors::SENSOR_TYPE_GYROSCOPE);
        ::ohos::sensors::UnsubscribeSensor(mSensorUser, ::ohos::sensors::SENSOR_TYPE_GYROSCOPE);
    }
    
    mListenerRegistered = false;
}

bool OHOSSensorManager::isAccelerometerSupported() {
    return mAccelerometerInfo != nullptr;
}

bool OHOSSensorManager::isGyroscopeSupported() {
    return mGyroscopeInfo != nullptr;
}

CustomSensorEvent OHOSSensorManager::convertSensorEvent(const ::ohos::sensors::SensorEvent* event) {
    CustomSensorEvent customEvent;
    customEvent.sensorType = event->sensorTypeId;
    customEvent.timestamp = event->timestamp;
    customEvent.accuracy = ::ohos::sensors::SENSOR_ACCURACY_MEDIUM; // 默认精度
    customEvent.accuracyChanged = false;
    
    // 复制传感器数据（简化处理）
    if (event->dataLen >= 3 * sizeof(float)) {
        float* data = reinterpret_cast<float*>(event->data);
        customEvent.values[0] = data[0];
        customEvent.values[1] = data[1];
        customEvent.values[2] = data[2];
    } else {
        // 如果数据长度不足，设置默认值
        customEvent.values[0] = 0.0f;
        customEvent.values[1] = 0.0f;
        customEvent.values[2] = 0.0f;
    }
    
    return customEvent;
}

void OHOSSensorManager::onSensorDataCallback(::ohos::sensors::SensorEvent* event) {
    if (!gInstance || !gInstance->mCallback) return;
    
    CustomSensorEvent customEvent = gInstance->convertSensorEvent(event);
    gInstance->mCallback(customEvent);
}

void OHOSSensorManager::onSensorAccuracyCallback(::ohos::sensors::SensorEvent* event) {
    if (!gInstance || !gInstance->mCallback) return;
    
    CustomSensorEvent customEvent;
    customEvent.sensorType = event->sensorTypeId;
    customEvent.timestamp = event->timestamp;
    customEvent.accuracy = static_cast<int32_t>(event->option); // 使用option字段作为精度
    customEvent.accuracyChanged = true;
    
    // 复制传感器数据（精度回调可能不包含数据）
    customEvent.values[0] = 0.0f;
    customEvent.values[1] = 0.0f;
    customEvent.values[2] = 0.0f;
    
    gInstance->mCallback(customEvent);
}

} // namespace vr
} // namespace ohos