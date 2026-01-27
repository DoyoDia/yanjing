#ifndef MD360_DIRECTOR_H
#define MD360_DIRECTOR_H

#include <array>
#include <atomic>

namespace ohos {
namespace vr {

class MD360Director {
public:
    MD360Director();
    ~MD360Director() = default;
    
    // 更新传感器矩阵
    void updateSensorMatrix(const float* sensorMatrix);
    
    // 重置旋转状态
    void reset();
    
    // 获取当前视图矩阵
    void getViewMatrix(float* matrix) const;
    
    // 设置投影矩阵参数
    void setProjectionParams(float fov, float aspect, float near, float far);
    
private:
    void updateWorldRotationMatrix();
    // 将这两个函数声明为const
    void multiplyMatrix(const float* a, const float* b, float* result) const;
    void invertMatrix(const float* matrix, float* result) const;
    
    std::atomic<bool> mWorldRotationMatrixValid{false};
    float mSensorMatrix[16];
    float mWorldRotationMatrix[16];
    float mViewMatrix[16];
    float mProjectionMatrix[16];
    
    // 旋转增量
    float mDeltaX{0.0f};
    float mDeltaY{0.0f};
    float mDeltaZ{0.0f};
    
    // 投影参数
    float mFov{90.0f};
    float mAspect{1.0f};
    float mNear{0.1f};
    float mFar{100.0f};
};

} // namespace vr
} // namespace ohos

#endif // MD360_DIRECTOR_H