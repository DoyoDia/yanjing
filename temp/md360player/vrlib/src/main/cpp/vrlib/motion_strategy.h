#ifndef MOTION_STRATEGY_H
#define MOTION_STRATEGY_H

#include <vector>
#include <mutex>
#include <atomic>
#include <cstdint>

// 日志宏定义
#include "md_log.h"

// 矩阵类型定义
typedef float Matrix4x4[16];

// OpenGL头文件
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

// 传感器数据结构
typedef struct {
    float x;
    float y;
    float z;
    float w;
} Quaternion;

typedef struct {
    Quaternion rotationVector;
    uint64_t timestamp;
    int accuracy;
} SensorData;

namespace asha {
namespace vrlib {

class MotionStrategy {
public:
    MotionStrategy();
    ~MotionStrategy();

    // 公共接口 - 平台无关
    bool handleDrag(int distanceX, int distanceY);
    void turnOn();
    void turnOff();
    bool isSupport();
    
    // 生命周期管理方法
    void onResume();
    void onPause();
    
    // 与安卓命名保持一致的GL线程方法
    void turnOnInGL();
    void turnOffInGL();

    // 传感器数据更新接口（供NAPI调用）
    void UpdateGyroData(float quatX, float quatY, float quatZ, float quatW);

    // OpenGL相关方法
    void updateDirectorsInGL();
    void applySensorMatrixToProgram(GLuint program, const char* matrixUniformName);
    
    // 获取传感器矩阵（供外部调用）
    void getSensorMatrix(Matrix4x4 matrix);

private:
    // 矩阵操作
    void rotationVectorToMatrix(const Quaternion& q, Matrix4x4 matrix);
    void applyDisplayRotation(int rotation, Matrix4x4 matrix);
    void multiplyMatrices(const Matrix4x4 a, const Matrix4x4 b, Matrix4x4 result);

    // 数据成员
    Matrix4x4 mSensorMatrix;
    Matrix4x4 mTmpMatrix;
    std::mutex mMatrixLock;

    // 状态标志
    std::atomic<bool> mIsOn;
    std::atomic<bool> mIsSupport;

    // 其他参数
    int mDisplayRotation;
};

} // namespace vrlib
} // namespace asha

#endif // MOTION_STRATEGY_H