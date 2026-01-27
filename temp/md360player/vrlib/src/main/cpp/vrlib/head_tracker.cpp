#include "head_tracker.h"
#include <hilog/log.h>
#include <cmath>

namespace ohos {
namespace vr {

static constexpr char TAG[] = "HeadTracker";
static constexpr float PI = 3.14159265358979323846f;
static constexpr float DEG_TO_RAD = PI / 180.0f;

HeadTracker::HeadTracker() 
    : mLastTimestamp(0), mIsTracking(false), mInitialized(false) {
    // 初始化单位矩阵
    std::lock_guard<std::mutex> lock(mMatrixLock);
    for (int i = 0; i < 16; ++i) {
        mHeadViewMatrix[i] = (i % 5 == 0) ? 1.0f : 0.0f;
    }
    
    // 初始化四元数 (无旋转)
    mOrientation[0] = 1.0f; // w
    mOrientation[1] = 0.0f; // x
    mOrientation[2] = 0.0f; // y
    mOrientation[3] = 0.0f; // z
    
    // 初始化传感器偏差
    for (int i = 0; i < 3; ++i) {
        mGyroBias[i] = 0.0f;
        mAccelBias[i] = 0.0f;
    }
    
    mFilterCoefficient = 0.98f; // 互补滤波器系数
}

HeadTracker::~HeadTracker() {
    stopTracking();
}

bool HeadTracker::initialize() {
    if (mInitialized) return true;
    
    mInitialized = true;
    return true;
}

void HeadTracker::startTracking() {
    if (mIsTracking) return;
    
    mIsTracking = true;
    mLastTimestamp = 0;
}

void HeadTracker::stopTracking() {
    if (!mIsTracking) return;
    
    mIsTracking = false;
}

void HeadTracker::getLastHeadView(float* matrix) {
    std::lock_guard<std::mutex> lock(mMatrixLock);
    for (int i = 0; i < 16; ++i) {
        matrix[i] = mHeadViewMatrix[i];
    }
}

void HeadTracker::processSensorData(int32_t sensorType, int64_t timestamp, const float* values) {
    if (!mIsTracking) return;
    
    float dt = 0.0f;
    if (mLastTimestamp > 0) {
        dt = (timestamp - mLastTimestamp) / 1000000000.0f; // 转换为秒
    }
    mLastTimestamp = timestamp;
    
    if (dt <= 0 || dt > 0.1f) {
        dt = 0.01f; // 默认10ms
    }
    
    switch (sensorType) {
        case 1: // 加速度计
            // 使用加速度计数据校正陀螺仪漂移
            break;
            
        case 4: // 陀螺仪
            if (dt > 0) {
                std::lock_guard<std::mutex> lock(mMatrixLock);
                updateOrientation(mOrientation, values, dt);
                quaternionToMatrix(mHeadViewMatrix, mOrientation);
            }
            break;
            
        default:
            break;
    }
}

void HeadTracker::updateOrientation(float* quaternion, const float* gyro, float dt) {
    // 陀螺仪数据转换为角速度 (rad/s)
    float gx = gyro[0] * DEG_TO_RAD;
    float gy = gyro[1] * DEG_TO_RAD;
    float gz = gyro[2] * DEG_TO_RAD;
    
    // 四元数微分方程
    float q0 = quaternion[0], q1 = quaternion[1], q2 = quaternion[2], q3 = quaternion[3];
    
    // 角速度的一半
    float halfGx = gx * 0.5f;
    float halfGy = gy * 0.5f;
    float halfGz = gz * 0.5f;
    
    // 四元数导数
    float dq0 = (-q1 * halfGx - q2 * halfGy - q3 * halfGz);
    float dq1 = (q0 * halfGx + q2 * halfGz - q3 * halfGy);
    float dq2 = (q0 * halfGy - q1 * halfGz + q3 * halfGx);
    float dq3 = (q0 * halfGz + q1 * halfGy - q2 * halfGx);
    
    // 积分更新四元数
    quaternion[0] = q0 + dq0 * dt;
    quaternion[1] = q1 + dq1 * dt;
    quaternion[2] = q2 + dq2 * dt;
    quaternion[3] = q3 + dq3 * dt;
    
    // 归一化四元数
    float norm = std::sqrt(quaternion[0]*quaternion[0] + quaternion[1]*quaternion[1] + 
                          quaternion[2]*quaternion[2] + quaternion[3]*quaternion[3]);
    if (norm > 0.0f) {
        quaternion[0] /= norm;
        quaternion[1] /= norm;
        quaternion[2] /= norm;
        quaternion[3] /= norm;
    }
}

void HeadTracker::quaternionToMatrix(float* matrix, const float* quaternion) {
    float q0 = quaternion[0], q1 = quaternion[1], q2 = quaternion[2], q3 = quaternion[3];
    
    // 四元数转旋转矩阵
    matrix[0] = 1.0f - 2.0f * (q2 * q2 + q3 * q3);
    matrix[1] = 2.0f * (q1 * q2 - q0 * q3);
    matrix[2] = 2.0f * (q1 * q3 + q0 * q2);
    matrix[3] = 0.0f;
    
    matrix[4] = 2.0f * (q1 * q2 + q0 * q3);
    matrix[5] = 1.0f - 2.0f * (q1 * q1 + q3 * q3);
    matrix[6] = 2.0f * (q2 * q3 - q0 * q1);
    matrix[7] = 0.0f;
    
    matrix[8] = 2.0f * (q1 * q3 - q0 * q2);
    matrix[9] = 2.0f * (q2 * q3 + q0 * q1);
    matrix[10] = 1.0f - 2.0f * (q1 * q1 + q2 * q2);
    matrix[11] = 0.0f;
    
    matrix[12] = 0.0f;
    matrix[13] = 0.0f;
    matrix[14] = 0.0f;
    matrix[15] = 1.0f;
}

} // namespace vr
} // namespace ohos