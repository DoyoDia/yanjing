#ifndef INTERACTIVE_STRATEGY_H
#define INTERACTIVE_STRATEGY_H

#include <functional>
#include <vector>
#include <memory>

namespace ohos {
namespace vr {

class MD360Director;

// 策略参数结构体
struct StrategyParams {
    std::function<void(std::function<void()>)> uiHandler; // UI线程处理器
    std::function<void(std::function<void()>)> glHandler; // GL线程处理器
    std::function<void(int32_t, int32_t)> sensorListener; // 传感器监听器
    int32_t motionDelay{10000}; // 运动延迟
};

// 交互策略基类
class InteractiveStrategy {
public:
    explicit InteractiveStrategy(const StrategyParams& params);
    virtual ~InteractiveStrategy() = default;
    
    // 生命周期管理
    virtual void onResume() = 0;
    virtual void onPause() = 0;
    
    // 交互处理
    virtual bool handleDrag(int distanceX, int distanceY) = 0;
    virtual void onOrientationChanged() = 0;
    
    // GL线程相关
    virtual void turnOnInGL() = 0;
    virtual void turnOffInGL() = 0;
    
    // 设备支持检测
    virtual bool isSupport() = 0;
    
    // 设置director列表
    void setDirectors(const std::vector<std::shared_ptr<MD360Director>>& directors) {
        mDirectors = directors;
    }
    
    // 获取director列表
    const std::vector<std::shared_ptr<MD360Director>>& getDirectors() const {
        return mDirectors;
    }

protected:
    StrategyParams mParams;
    std::vector<std::shared_ptr<MD360Director>> mDirectors;
};

} // namespace vr
} // namespace ohos

#endif // INTERACTIVE_STRATEGY_H