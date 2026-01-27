#include "interactive_strategy.h"

namespace ohos {
namespace vr {

// 交互策略基类的实现
// 这里主要是虚函数的默认实现，具体的策略类会重写这些方法

InteractiveStrategy::InteractiveStrategy(const StrategyParams& params) 
    : mParams(params) {
}

// 默认实现为空，具体策略类需要重写
void InteractiveStrategy::onResume() {
}

void InteractiveStrategy::onPause() {
}

bool InteractiveStrategy::handleDrag(int distanceX, int distanceY) {
    return false;
}

void InteractiveStrategy::onOrientationChanged() {
}

void InteractiveStrategy::turnOnInGL() {
}

void InteractiveStrategy::turnOffInGL() {
}

bool InteractiveStrategy::isSupport() {
    return false;
}

} // namespace vr
} // namespace ohos