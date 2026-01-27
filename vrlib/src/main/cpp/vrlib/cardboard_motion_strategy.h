#ifndef CARDBOARD_MOTION_STRATEGY_H
#define CARDBOARD_MOTION_STRATEGY_H

#include <mutex>
#include <memory>
#include <vector>
#include <functional>
#include <atomic>
#include "md360_director.h"  // 添加完整的头文件引用
#include "sensor_agent.h"    // 添加传感器代理头文件

namespace ohos {
namespace vr {

// 前向声明（保留，但主要使用完整头文件）
class HeadTracker;
class OHOSSensorManager;
class MD360Director;

// 使用sensor_agent.h中定义的SensorEvent结构体
using SensorEvent = ::ohos::sensors::SensorEvent;

// 使用sensor_agent.h中定义的CustomSensorEvent结构体
using CustomSensorEvent = ::ohos::sensors::CustomSensorEvent;

// 传感器监听器接口
class SensorEventListener {
public:
    virtual ~SensorEventListener() = default;
    virtual void onSensorChanged(const CustomSensorEvent& event) = 0;
    virtual void onAccuracyChanged(int32_t sensorType, int32_t accuracy) = 0;
};

// 处理器接口（用于跨线程通信）
class Handler {
public:
    virtual ~Handler() = default;
    virtual void PostTask(std::function<void()> task) = 0;
};

// Cardboard运动策略主类
class CardboardMotionStrategy {
public:
    struct StrategyParams {
        int motionDelay{10};  // 运动延迟
        std::shared_ptr<SensorEventListener> sensorListener;  // 传感器监听器
        std::shared_ptr<Handler> uiHandler;  // UI线程处理器
        std::shared_ptr<Handler> glHandler;  // GL线程处理器
        
        StrategyParams() = default;
    };
    
    explicit CardboardMotionStrategy(const StrategyParams& params);
    ~CardboardMotionStrategy();
    
    // 生命周期管理
    void onResume();
    void onPause();
    
    // 交互处理
    bool handleDrag(int distanceX, int distanceY);
    void onOrientationChanged();
    
    // 设备支持检测
    bool isSupport();
    
    // GL线程操作
    void turnOnInGL();
    void turnOffInGL();
    
    // 获取头部视图矩阵
    void getHeadViewMatrix(float* matrix);
    
    // 设置director列表（用于更新传感器矩阵）
    void setDirectors(const std::vector<std::shared_ptr<MD360Director>>& directors);
    
private:
    void registerSensor();
    void unregisterSensor();
    void onSensorChanged(const CustomSensorEvent& event);
    void updateSensorMatrix();
    
    // 将OpenHarmony传感器事件转换为自定义事件
    CustomSensorEvent convertSensorEvent(const ::ohos::sensors::SensorEvent* event);
    
    bool mRegistered{false};
    bool mIsOn{false};
    std::atomic<bool> mIsSupport{false};
    
    std::mutex mMatrixLock;
    float mTmpMatrix[16];
    
    std::unique_ptr<HeadTracker> mHeadTracker;
    std::unique_ptr<OHOSSensorManager> mSensorManager;
    StrategyParams mParams;
    std::vector<std::shared_ptr<MD360Director>> mDirectors;
};

} // namespace vr
} // namespace ohos

#endif // CARDBOARD_MOTION_STRATEGY_H