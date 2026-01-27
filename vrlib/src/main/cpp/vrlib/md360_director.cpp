#include "md360_director.h"
#include <cmath>
#include <cstring>

namespace ohos {
namespace vr {

MD360Director::MD360Director() {
    // 初始化单位矩阵
    for (int i = 0; i < 16; ++i) {
        mSensorMatrix[i] = (i % 5 == 0) ? 1.0f : 0.0f;
        mWorldRotationMatrix[i] = (i % 5 == 0) ? 1.0f : 0.0f;
        mViewMatrix[i] = (i % 5 == 0) ? 1.0f : 0.0f;
        mProjectionMatrix[i] = (i % 5 == 0) ? 1.0f : 0.0f;
    }
    
    // 初始化投影矩阵
    setProjectionParams(mFov, mAspect, mNear, mFar);
}

void MD360Director::updateSensorMatrix(const float* sensorMatrix) {
    // 检查输入矩阵是否有效
    if (!sensorMatrix) return;
    
    // 复制传感器矩阵
    std::memcpy(mSensorMatrix, sensorMatrix, 16 * sizeof(float));
    
    // 标记世界旋转矩阵为无效，需要重新计算
    mWorldRotationMatrixValid = false;
}

void MD360Director::reset() {
    // 重置旋转增量
    mDeltaX = 0.0f;
    mDeltaY = 0.0f;
    mDeltaZ = 0.0f;
    
    // 重置传感器矩阵为单位矩阵
    for (int i = 0; i < 16; ++i) {
        mSensorMatrix[i] = (i % 5 == 0) ? 1.0f : 0.0f;
    }
    
    // 标记世界旋转矩阵为无效
    mWorldRotationMatrixValid = false;
}

void MD360Director::getViewMatrix(float* matrix) const {
    if (!matrix) return;
    
    // 如果世界旋转矩阵无效，需要重新计算
    if (!mWorldRotationMatrixValid) {
        const_cast<MD360Director*>(this)->updateWorldRotationMatrix();
    }
    
    // 视图矩阵 = 投影矩阵 × 世界旋转矩阵
    multiplyMatrix(mProjectionMatrix, mWorldRotationMatrix, matrix);
}

void MD360Director::setProjectionParams(float fov, float aspect, float near, float far) {
    mFov = fov;
    mAspect = aspect;
    mNear = near;
    mFar = far;
    
    // 计算投影矩阵（透视投影）
    float f = 1.0f / std::tan(mFov * 0.5f * M_PI / 180.0f);
    float range = mNear - mFar;
    
    mProjectionMatrix[0] = f / mAspect;
    mProjectionMatrix[1] = 0.0f;
    mProjectionMatrix[2] = 0.0f;
    mProjectionMatrix[3] = 0.0f;
    
    mProjectionMatrix[4] = 0.0f;
    mProjectionMatrix[5] = f;
    mProjectionMatrix[6] = 0.0f;
    mProjectionMatrix[7] = 0.0f;
    
    mProjectionMatrix[8] = 0.0f;
    mProjectionMatrix[9] = 0.0f;
    mProjectionMatrix[10] = (mFar + mNear) / range;
    mProjectionMatrix[11] = -1.0f;
    
    mProjectionMatrix[12] = 0.0f;
    mProjectionMatrix[13] = 0.0f;
    mProjectionMatrix[14] = (2.0f * mFar * mNear) / range;
    mProjectionMatrix[15] = 0.0f;
}

void MD360Director::updateWorldRotationMatrix() {
    // 这里实现世界旋转矩阵的计算逻辑
    // 简单实现：直接使用传感器矩阵
    std::memcpy(mWorldRotationMatrix, mSensorMatrix, 16 * sizeof(float));
    mWorldRotationMatrixValid = true;
}

// 添加const修饰符
void MD360Director::multiplyMatrix(const float* a, const float* b, float* result) const {
    for (int i = 0; i < 4; ++i) {
        for (int j = 0; j < 4; ++j) {
            result[i * 4 + j] = 0.0f;
            for (int k = 0; k < 4; ++k) {
                result[i * 4 + j] += a[i * 4 + k] * b[k * 4 + j];
            }
        }
    }
}

// 添加const修饰符
void MD360Director::invertMatrix(const float* matrix, float* result) const {
    // 简化实现：假设矩阵是可逆的4x4矩阵
    // 实际实现需要更复杂的数学计算
    std::memcpy(result, matrix, 16 * sizeof(float));
}

} // namespace vr
} // namespace ohos