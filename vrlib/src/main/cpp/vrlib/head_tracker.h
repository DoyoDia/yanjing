#ifndef HEAD_TRACKER_H
#define HEAD_TRACKER_H

#include <mutex>
#include <atomic>
#include <cmath>

namespace ohos {
namespace vr {

class HeadTracker {
public:
    HeadTracker();
    ~HeadTracker();
    
    bool initialize();
    void startTracking();
    void stopTracking();
    void getLastHeadView(float* matrix);
    void processSensorData(int32_t sensorType, int64_t timestamp, const float* values);
    
private:
    void updateOrientation(float* quaternion, const float* gyro, float dt);
    void quaternionToMatrix(float* matrix, const float* quaternion);
    void matrixMultiply(float* result, const float* lhs, const float* rhs);
    
    std::mutex mMatrixLock;
    float mHeadViewMatrix[16];
    float mOrientation[4]; // 四元数表示方向
    int64_t mLastTimestamp;
    std::atomic<bool> mIsTracking;
    std::atomic<bool> mInitialized;
    
    // 传感器融合参数
    float mGyroBias[3];
    float mAccelBias[3];
    float mFilterCoefficient;
};

} // namespace vr
} // namespace ohos

#endif // HEAD_TRACKER_H