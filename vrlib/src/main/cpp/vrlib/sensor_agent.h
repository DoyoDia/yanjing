#ifndef SENSOR_AGENT_H
#define SENSOR_AGENT_H

#include <cstdint>

namespace ohos {
namespace sensors {

// 传感器类型定义
enum SensorType {
    SENSOR_TYPE_ACCELEROMETER = 1,
    SENSOR_TYPE_GYROSCOPE = 4,
    SENSOR_TYPE_MAGNETIC_FIELD = 2,
    SENSOR_TYPE_LIGHT = 5,
    SENSOR_TYPE_PROXIMITY = 8
};

// 传感器信息结构
struct SensorInfo {
    const char* sensorName;
    const char* vendorName;
    int32_t sensorTypeId;
    float maxRange;
    float resolution;
    float power;
    int32_t minDelay;
    int32_t maxDelay;
};

// 传感器事件结构
struct SensorEvent {
    int32_t sensorTypeId;
    int32_t version;
    int64_t timestamp;
    int32_t option;
    int32_t mode;
    uint8_t *data;
    uint32_t dataLen;
};

// 自定义传感器回调事件结构（适配OpenHarmony传感器事件）
struct CustomSensorEvent {
    int32_t sensorType;
    int32_t accuracy;
    int64_t timestamp;
    float values[3];
    bool accuracyChanged;
};

// 传感器用户句柄（简化实现）
struct SensorUser {
    int32_t userId;
    void* userData;
};

// 传感器精度
enum SensorAccuracy {
    SENSOR_ACCURACY_UNRELIABLE = 0,
    SENSOR_ACCURACY_LOW = 1,
    SENSOR_ACCURACY_MEDIUM = 2,
    SENSOR_ACCURACY_HIGH = 3
};

// 传感器API函数声明
extern "C" {
    // 获取传感器列表
    int32_t GetAllSensors(SensorInfo** sensorInfo, int32_t* count);
    
    // 创建传感器用户
    int32_t CreateSensorUser(SensorUser** user);
    
    // 销毁传感器用户
    int32_t DestroySensorUser(SensorUser* user);
    
    // 订阅传感器
    int32_t SubscribeSensor(SensorUser* user, int32_t sensorTypeId);
    
    // 取消订阅传感器
    int32_t UnsubscribeSensor(SensorUser* user, int32_t sensorTypeId);
    
    // 设置数据回调
    int32_t SetSensorEventCallback(SensorUser* user, 
                                  void (*callback)(SensorEvent* event));
    
    // 设置精度回调
    int32_t SetSensorAccuracyCallback(SensorUser* user,
                                     void (*callback)(SensorEvent* event));
    
    // 激活传感器
    int32_t ActivateSensor(SensorUser* user, int32_t sensorTypeId);
    
    // 停用传感器
    int32_t DeactivateSensor(SensorUser* user, int32_t sensorTypeId);
}

} // namespace sensors
} // namespace ohos

#endif // SENSOR_AGENT_H