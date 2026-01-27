#include "sensor_agent.h"
#include <cstdlib>
#include <cstring>
#include <thread>
#include <chrono>
#include <random>

namespace ohos {
namespace sensors {

// 全局变量用于存储传感器信息
static SensorInfo* gSensorInfos = nullptr;
static int32_t gSensorCount = 0;
static bool gSensorThreadRunning = false;
static std::thread gSensorThread;
static int32_t gActiveSensorCount = 0; // 跟踪激活的传感器数量

// 传感器回调函数指针
static void (*gSensorEventCallback)(SensorEvent* event) = nullptr;
static void (*gSensorAccuracyCallback)(SensorEvent* event) = nullptr;

// 初始化传感器信息（桩实现）
static void initializeSensorInfos() {
    if (gSensorInfos == nullptr) {
        gSensorCount = 2; // 模拟加速度计和陀螺仪
        
        gSensorInfos = static_cast<SensorInfo*>(malloc(sizeof(SensorInfo) * gSensorCount));
        
        // 加速度计
        gSensorInfos[0].sensorName = "Accelerometer";
        gSensorInfos[0].vendorName = "OpenHarmony";
        gSensorInfos[0].sensorTypeId = SENSOR_TYPE_ACCELEROMETER;
        gSensorInfos[0].maxRange = 19.6f;
        gSensorInfos[0].resolution = 0.01f;
        gSensorInfos[0].power = 0.5f;
        gSensorInfos[0].minDelay = 10000;
        gSensorInfos[0].maxDelay = 200000;
        
        // 陀螺仪
        gSensorInfos[1].sensorName = "Gyroscope";
        gSensorInfos[1].vendorName = "OpenHarmony";
        gSensorInfos[1].sensorTypeId = SENSOR_TYPE_GYROSCOPE;
        gSensorInfos[1].maxRange = 34.91f;
        gSensorInfos[1].resolution = 0.001f;
        gSensorInfos[1].power = 6.1f;
        gSensorInfos[1].minDelay = 10000;
        gSensorInfos[1].maxDelay = 200000;
    }
}

// 模拟传感器数据生成线程
static void sensorDataGenerator() {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<float> accelDist(-10.0f, 10.0f);
    std::uniform_real_distribution<float> gyroDist(-5.0f, 5.0f);
    
    while (gSensorThreadRunning) {
        if (gSensorEventCallback) {
            // 生成加速度计数据
            SensorEvent accelEvent;
            accelEvent.sensorTypeId = SENSOR_TYPE_ACCELEROMETER;
            accelEvent.version = 1;
            accelEvent.timestamp = std::chrono::duration_cast<std::chrono::nanoseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
            accelEvent.option = SENSOR_ACCURACY_MEDIUM;
            accelEvent.mode = 0;
            
            float accelData[3] = {accelDist(gen), accelDist(gen), accelDist(gen)};
            accelEvent.data = reinterpret_cast<uint8_t*>(accelData);
            accelEvent.dataLen = sizeof(accelData);
            
            gSensorEventCallback(&accelEvent);
            
            // 生成陀螺仪数据
            SensorEvent gyroEvent;
            gyroEvent.sensorTypeId = SENSOR_TYPE_GYROSCOPE;
            gyroEvent.version = 1;
            gyroEvent.timestamp = std::chrono::duration_cast<std::chrono::nanoseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
            gyroEvent.option = SENSOR_ACCURACY_MEDIUM;
            gyroEvent.mode = 0;
            
            float gyroData[3] = {gyroDist(gen), gyroDist(gen), gyroDist(gen)};
            gyroEvent.data = reinterpret_cast<uint8_t*>(gyroData);
            gyroEvent.dataLen = sizeof(gyroData);
            
            gSensorEventCallback(&gyroEvent);
        }
        
        std::this_thread::sleep_for(std::chrono::milliseconds(100)); // 100ms间隔
    }
}

// 获取所有传感器
int32_t GetAllSensors(SensorInfo** sensorInfo, int32_t* count) {
    initializeSensorInfos();
    *sensorInfo = gSensorInfos;
    *count = gSensorCount;
    return 0; // 成功
}

// 创建传感器用户
int32_t CreateSensorUser(SensorUser** user) {
    if (user == nullptr) return -1;
    
    *user = static_cast<SensorUser*>(malloc(sizeof(SensorUser)));
    if (*user == nullptr) return -1;
    
    (*user)->userId = 1; // 模拟用户ID
    (*user)->userData = nullptr;
    
    return 0; // 成功
}

// 销毁传感器用户
int32_t DestroySensorUser(SensorUser* user) {
    if (user == nullptr) return -1;
    
    // 停止传感器线程
    gSensorThreadRunning = false;
    if (gSensorThread.joinable()) {
        gSensorThread.join();
    }
    
    // 释放传感器信息内存
    if (gSensorInfos != nullptr) {
        free(gSensorInfos);
        gSensorInfos = nullptr;
        gSensorCount = 0;
    }
    
    free(user);
    return 0; // 成功
}

// 订阅传感器
int32_t SubscribeSensor(SensorUser* user, int32_t sensorTypeId) {
    if (user == nullptr) return -1;
    
    // 桩实现：总是返回成功
    return 0;
}

// 取消订阅传感器
int32_t UnsubscribeSensor(SensorUser* user, int32_t sensorTypeId) {
    if (user == nullptr) return -1;
    
    // 桩实现：总是返回成功
    return 0;
}

// 设置数据回调
int32_t SetSensorEventCallback(SensorUser* user, void (*callback)(SensorEvent* event)) {
    if (user == nullptr || callback == nullptr) return -1;
    
    gSensorEventCallback = callback;
    return 0;
}

// 设置精度回调
int32_t SetSensorAccuracyCallback(SensorUser* user, void (*callback)(SensorEvent* event)) {
    if (user == nullptr || callback == nullptr) return -1;
    
    gSensorAccuracyCallback = callback;
    return 0;
}

// 激活传感器
int32_t ActivateSensor(SensorUser* user, int32_t sensorTypeId) {
    if (user == nullptr) return -1;
    
    // 启动传感器数据生成线程
    if (!gSensorThreadRunning) {
        // 如果之前有线程在运行，先等待它结束
        if (gSensorThread.joinable()) {
            gSensorThread.join();
        }
        gSensorThreadRunning = true;
        gSensorThread = std::thread(sensorDataGenerator);
    }
    
    gActiveSensorCount++;
    return 0; // 成功
}

// 停用传感器
int32_t DeactivateSensor(SensorUser* user, int32_t sensorTypeId) {
    if (user == nullptr) return -1;
    
    // 减少激活的传感器计数
    if (gActiveSensorCount > 0) {
        gActiveSensorCount--;
    }
    
    // 只有当所有传感器都停用时，才停止线程
    if (gActiveSensorCount <= 0 && gSensorThreadRunning) {
        gSensorThreadRunning = false;
        if (gSensorThread.joinable()) {
            gSensorThread.join();
        }
        gActiveSensorCount = 0; // 重置计数
    }
    
    return 0; // 成功
}

} // namespace sensors
} // namespace ohos