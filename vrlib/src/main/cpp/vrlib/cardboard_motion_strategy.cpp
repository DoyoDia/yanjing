#include "cardboard_motion_strategy.h"
#include "head_tracker.h"
#include "ohos_sensor_manager.h"
#include <hilog/log.h>
#include <thread>
#include <cmath>

namespace ohos {
namespace vr {

static constexpr char TAG[] = "CardboardMotionStrategy";

CardboardMotionStrategy::CardboardMotionStrategy(const StrategyParams& params)
    : mParams(params), mRegistered(false), mIsOn(false), mIsSupport(false) {
    // 初始化单位矩阵
    std::lock_guard<std::mutex> lock(mMatrixLock);
    for (int i = 0; i < 16; ++i) {
        mTmpMatrix[i] = (i % 5 == 0) ? 1.0f : 0.0f;
    }
}

CardboardMotionStrategy::~CardboardMotionStrategy() {
    unregisterSensor();
}

void CardboardMotionStrategy::onResume() {
    if (mRegistered) return;
    
    registerSensor();
}

void CardboardMotionStrategy::onPause() {
    if (!mRegistered) return;
    
    unregisterSensor();
}

bool CardboardMotionStrategy::handleDrag(int distanceX, int distanceY) {
    // CARDBOARD MOTION模式不处理拖拽事件
    return false;
}

void CardboardMotionStrategy::onOrientationChanged() {
}

void CardboardMotionStrategy::turnOnInGL() {
    mIsOn = true;
    
    // 重置所有director
    for (auto& director : mDirectors) {
        if (director) {
            director->reset();
        }
    }
}

void CardboardMotionStrategy::turnOffInGL() {
    mIsOn = false;
    
    // 在UI线程注销传感器
    if (mParams.uiHandler) {
        mParams.uiHandler->PostTask([this]() {
            unregisterSensor();
        });
    }
}

bool CardboardMotionStrategy::isSupport() {
    if (!mIsSupport) {
        // 检测设备是否支持加速度计和陀螺仪
        mSensorManager = std::make_unique<OHOSSensorManager>();
        if (mSensorManager->initialize()) {
            mIsSupport = mSensorManager->isAccelerometerSupported() || 
                         mSensorManager->isGyroscopeSupported();
        }
    }
    return mIsSupport;
}

void CardboardMotionStrategy::registerSensor() {
    if (mRegistered || !mSensorManager) return;
    
    // 初始化头部追踪器
    if (!mHeadTracker) {
        mHeadTracker = std::make_unique<HeadTracker>();
        mHeadTracker->initialize();
    }
    
    // 注册传感器监听 - 修正lambda表达式参数类型
    auto callback = [this](const CustomSensorEvent& event) {
        this->onSensorChanged(event);
    };
    
    if (mSensorManager->registerListener(callback)) {
        mHeadTracker->startTracking();
        mRegistered = true;
    } else {
    }
}

void CardboardMotionStrategy::unregisterSensor() {
    if (!mRegistered) return;
    
    if (mSensorManager) {
        mSensorManager->unregisterListener();
    }
    
    if (mHeadTracker) {
        mHeadTracker->stopTracking();
    }
    
    mRegistered = false;

}

void CardboardMotionStrategy::onSensorChanged(const CustomSensorEvent& event) {
    if (!mIsOn || event.accuracy == 0) return;
    
    // 处理传感器精度变化
    if (event.accuracyChanged && mParams.sensorListener) {
        mParams.sensorListener->onAccuracyChanged(event.sensorType, event.accuracy);
    }
    
    // 处理传感器数据
    if (mHeadTracker) {
        mHeadTracker->processSensorData(event.sensorType, event.timestamp, event.values);
        
        // 更新头部视图矩阵
        std::lock_guard<std::mutex> lock(mMatrixLock);
        mHeadTracker->getLastHeadView(mTmpMatrix);
    }
    
    // 在GL线程更新传感器矩阵
    if (mParams.glHandler) {
        mParams.glHandler->PostTask([this]() {
            this->updateSensorMatrix();
        });
    }
}

void CardboardMotionStrategy::updateSensorMatrix() {
    if (!mRegistered || !mIsOn) return;
    
    std::lock_guard<std::mutex> lock(mMatrixLock);
    for (auto& director : mDirectors) {
        if (director) {
            director->updateSensorMatrix(mTmpMatrix);
        }
    }
}

void CardboardMotionStrategy::getHeadViewMatrix(float* matrix) {
    std::lock_guard<std::mutex> lock(mMatrixLock);
    for (int i = 0; i < 16; ++i) {
        matrix[i] = mTmpMatrix[i];
    }
}

} // namespace vr
} // namespace ohos