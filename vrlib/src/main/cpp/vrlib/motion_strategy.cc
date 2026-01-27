#include "motion_strategy.h"
#include <cmath>

// 初始化矩阵为单位矩阵
static void initMatrix(Matrix4x4 matrix) {
    for (int i = 0; i < 16; i++) {
        matrix[i] = (i % 5 == 0) ? 1.0f : 0.0f;
    }
}

// 旋转变换矩阵：绕X轴旋转
static void rotateX(Matrix4x4 matrix, float angle) {
    float cosA = cosf(angle);
    float sinA = sinf(angle);
    Matrix4x4 rotation;
    initMatrix(rotation);
    rotation[5] = cosA;
    rotation[6] = -sinA;
    rotation[9] = sinA;
    rotation[10] = cosA;
    
    // 临时实现矩阵乘法
    Matrix4x4 result;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            result[i * 4 + j] = 0.0f;
            for (int k = 0; k < 4; k++) {
                result[i * 4 + j] += matrix[i * 4 + k] * rotation[k * 4 + j];
            }
        }
    }
    
    // 将结果复制回原矩阵
    for (int i = 0; i < 16; i++) {
        matrix[i] = result[i];
    }
}

// 旋转变换矩阵：绕Y轴旋转
static void rotateY(Matrix4x4 matrix, float angle) {
    float cosA = cosf(angle);
    float sinA = sinf(angle);
    Matrix4x4 rotation;
    initMatrix(rotation);
    rotation[0] = cosA;
    rotation[2] = sinA;
    rotation[8] = -sinA;
    rotation[10] = cosA;
    
    // 临时实现矩阵乘法
    Matrix4x4 result;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            result[i * 4 + j] = 0.0f;
            for (int k = 0; k < 4; k++) {
                result[i * 4 + j] += matrix[i * 4 + k] * rotation[k * 4 + j];
            }
        }
    }
    
    // 将结果复制回原矩阵
    for (int i = 0; i < 16; i++) {
        matrix[i] = result[i];
    }
}

// 旋转变换矩阵：绕Z轴旋转
static void rotateZ(Matrix4x4 matrix, float angle) {
    float cosA = cosf(angle);
    float sinA = sinf(angle);
    Matrix4x4 rotation;
    initMatrix(rotation);
    rotation[0] = cosA;
    rotation[1] = -sinA;
    rotation[4] = sinA;
    rotation[5] = cosA;
    
    // 临时实现矩阵乘法
    Matrix4x4 result;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            result[i * 4 + j] = 0.0f;
            for (int k = 0; k < 4; k++) {
                result[i * 4 + j] += matrix[i * 4 + k] * rotation[k * 4 + j];
            }
        }
    }
    
    // 将结果复制回原矩阵
    for (int i = 0; i < 16; i++) {
        matrix[i] = result[i];
    }
}

namespace asha {
namespace vrlib {

MotionStrategy::MotionStrategy() {
    // 初始化矩阵
    initMatrix(mSensorMatrix);
    initMatrix(mTmpMatrix);
    
    // 初始化状态标志
    mIsOn = false;
    mIsSupport = true;
    
    // 初始化其他参数
    mDisplayRotation = 0;
    
    MD_LOGI("MotionStrategy initialized");
}

MotionStrategy::~MotionStrategy() {
    // 确保资源被释放
    MD_LOGI("MotionStrategy destroyed");
}

// 私有方法实现
void MotionStrategy::multiplyMatrices(const Matrix4x4 a, const Matrix4x4 b, Matrix4x4 result) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            result[i * 4 + j] = 0.0f;
            for (int k = 0; k < 4; k++) {
                result[i * 4 + j] += a[i * 4 + k] * b[k * 4 + j];
            }
        }
    }
}

void MotionStrategy::rotationVectorToMatrix(const Quaternion& q, Matrix4x4 matrix) {
    float x = q.x;
    float y = q.y;
    float z = q.z;
    float w = q.w;

    float x2 = x * 2.0f;
    float y2 = y * 2.0f;
    float z2 = z * 2.0f;

    float xx = x * x2;
    float xy = x * y2;
    float xz = x * z2;
    float yy = y * y2;
    float yz = y * z2;
    float zz = z * z2;
    float wx = w * x2;
    float wy = w * y2;
    float wz = w * z2;

    matrix[0] = 1.0f - (yy + zz);
    matrix[1] = xy + wz;
    matrix[2] = xz - wy;
    matrix[3] = 0.0f;

    matrix[4] = xy - wz;
    matrix[5] = 1.0f - (xx + zz);
    matrix[6] = yz + wx;
    matrix[7] = 0.0f;

    matrix[8] = xz + wy;
    matrix[9] = yz - wx;
    matrix[10] = 1.0f - (xx + yy);
    matrix[11] = 0.0f;

    matrix[12] = 0.0f;
    matrix[13] = 0.0f;
    matrix[14] = 0.0f;
    matrix[15] = 1.0f;
}

// 传感器轴定义
#define AXIS_X 1
#define AXIS_Y 2
#define AXIS_Z 3
#define AXIS_MINUS_X 4
#define AXIS_MINUS_Y 5
#define AXIS_MINUS_Z 6

// 屏幕旋转常量定义
enum SurfaceRotation {
    ROTATION_0 = 0,
    ROTATION_90 = 1,
    ROTATION_180 = 2,
    ROTATION_270 = 3
};

// 重新映射坐标系，与 Android SensorManager.remapCoordinateSystem 一致
static bool remapCoordinateSystem(const Matrix4x4 inMatrix, int X, int Y, Matrix4x4 outMatrix) {
    MD_LOGE("applyDisplayRotation: remapCoordinateSystem 12");

    // 复制输入矩阵到输出矩阵
    for (int i = 0; i < 16; i++) {
        outMatrix[i] = inMatrix[i];
    }

    // 创建临时矩阵保存原矩阵的前3x3部分
    float temp[12];
    for (int i = 0; i < 12; i++) {
        temp[i] = inMatrix[i];
    }

    // 根据指定的轴进行重新映射 - X轴映射
    switch (X) {
        case AXIS_X:
            outMatrix[0] = temp[0]; outMatrix[1] = temp[1]; outMatrix[2] = temp[2];
            break;
        case AXIS_Y:
            outMatrix[0] = temp[4]; outMatrix[1] = temp[5]; outMatrix[2] = temp[6];
            break;
        case AXIS_Z:
            outMatrix[0] = temp[8]; outMatrix[1] = temp[9]; outMatrix[2] = temp[10];
            break;
        case AXIS_MINUS_X:
            outMatrix[0] = -temp[0]; outMatrix[1] = -temp[1]; outMatrix[2] = -temp[2];
            break;
        case AXIS_MINUS_Y:
            outMatrix[0] = -temp[4]; outMatrix[1] = -temp[5]; outMatrix[2] = -temp[6];
            break;
        case AXIS_MINUS_Z:
            outMatrix[0] = -temp[8]; outMatrix[1] = -temp[9]; outMatrix[2] = -temp[10];
            break;
        default:
            return false;
    }

    // Y轴映射
    switch (Y) {
        case AXIS_X:
            outMatrix[4] = temp[0]; outMatrix[5] = temp[1]; outMatrix[6] = temp[2];
            break;
        case AXIS_Y:
            outMatrix[4] = temp[4]; outMatrix[5] = temp[5]; outMatrix[6] = temp[6];
            break;
        case AXIS_Z:
            outMatrix[4] = temp[8]; outMatrix[5] = temp[9]; outMatrix[6] = temp[10];
            break;
        case AXIS_MINUS_X:
            outMatrix[4] = -temp[0]; outMatrix[5] = -temp[1]; outMatrix[6] = -temp[2];
            break;
        case AXIS_MINUS_Y:
            outMatrix[4] = -temp[4]; outMatrix[5] = -temp[5]; outMatrix[6] = -temp[6];
            break;
        case AXIS_MINUS_Z:
            outMatrix[4] = -temp[8]; outMatrix[5] = -temp[9]; outMatrix[6] = -temp[10];
            break;
        default:
            return false;
    }

    // 计算Z轴，确保右手坐标系：Z = X × Y
    outMatrix[8] = outMatrix[1] * outMatrix[6] - outMatrix[2] * outMatrix[5];
    outMatrix[9] = outMatrix[2] * outMatrix[4] - outMatrix[0] * outMatrix[6];
    outMatrix[10] = outMatrix[0] * outMatrix[5] - outMatrix[1] * outMatrix[4];

    return true;
}

void MotionStrategy::applyDisplayRotation(int rotation, Matrix4x4 matrix) {
    // 创建临时矩阵保存原矩阵
    Matrix4x4 tempMatrix;
    for (int i = 0; i < 16; i++) {
        tempMatrix[i] = matrix[i];
    }
    
    MD_LOGE("applyDisplayRotation: remapCoordinateSystem ok , rotation = %d" , rotation);
    bool success = false;
    switch (rotation) {
        case SurfaceRotation::ROTATION_0:
            // 0度不需要旋转
            success = true;
            break;
        case SurfaceRotation::ROTATION_90:
            // 使用与安卓一致的轴映射：AXIS_Y -> X轴, AXIS_MINUS_X -> Y轴
            success = remapCoordinateSystem(tempMatrix, AXIS_Y, AXIS_MINUS_X, matrix);
            break;
        case SurfaceRotation::ROTATION_180:
            // 使用与安卓一致的轴映射：AXIS_MINUS_X -> X轴, AXIS_MINUS_Y -> Y轴
            success = remapCoordinateSystem(tempMatrix, AXIS_MINUS_X, AXIS_MINUS_Y, matrix);
            break;
        case SurfaceRotation::ROTATION_270:
            // 使用与安卓一致的轴映射：AXIS_MINUS_Y -> X轴, AXIS_X -> Y轴
            success = remapCoordinateSystem(tempMatrix, AXIS_MINUS_Y, AXIS_X, matrix);
            break;
        default:
            // 其他旋转角度使用默认映射
            success = true;
            break;
    }

    if (!success) {
        MD_LOGE("applyDisplayRotation: remapCoordinateSystem failed");
        // 如果重新映射失败，恢复原矩阵
        for (int i = 0; i < 16; i++) {
            matrix[i] = tempMatrix[i];
        }
    }
}

// 公共方法实现
bool MotionStrategy::handleDrag(int distanceX, int distanceY) {
    // 处理拖拽逻辑，根据需要更新矩阵
    MD_LOGI("handleDrag called: distanceX=%d, distanceY=%d", distanceX, distanceY);
    return false; // 与安卓保持一致，返回false
}

void MotionStrategy::turnOn() {
    MD_LOGI("turnOn called");
    mIsOn = true;
}

void MotionStrategy::turnOff() {
    MD_LOGI("turnOff called");
    mIsOn = false;
}

// 与安卓保持一致的GL线程方法实现
void MotionStrategy::turnOnInGL() {
    MD_LOGI("turnOnInGL called");
    mIsOn = true;
    
    // 重置所有director
    updateDirectorsInGL();
}

void MotionStrategy::turnOffInGL() {
    MD_LOGI("turnOffInGL called");
    mIsOn = false;
}

bool MotionStrategy::isSupport() {
    if (!mIsSupport.load()) {
        MD_LOGI("isSupport called, returning false");
        return false;
    }
    
    // 实现传感器支持检测逻辑
    // 在HarmonyOS中，传感器检测通常通过Sensor API进行
    // 由于当前在C++层，我们假设传感器支持已在ETS层检测
    // 实际实现中可能需要通过NAPI调用HarmonyOS的Sensor API
    MD_LOGI("isSupport called, returning true");
    return true;
}

// 生命周期管理方法实现
void MotionStrategy::onResume() {
    MD_LOGI("onResume called");
    // 在HarmonyOS中，传感器注册通常在ETS层处理
    // 这里可以添加任何需要在resume时执行的C++特定逻辑
}

void MotionStrategy::onPause() {
    MD_LOGI("onPause called");
    // 在HarmonyOS中，传感器注销通常在ETS层处理
    // 这里可以添加任何需要在pause时执行的C++特定逻辑
}

// 传感器数据更新接口（供NAPI调用）
void MotionStrategy::UpdateGyroData(float quatX, float quatY, float quatZ, float quatW) {
    MD_LOGI("UpdateGyroData called: quatX=%f, quatY=%f, quatZ=%f, quatW=%f", quatX, quatY, quatZ, quatW);
    
    // 只有在陀螺仪开启时才处理数据
    if (!mIsOn.load()) {
        MD_LOGW("UpdateGyroData: mIsOn is false, ignoring data");
        return;
    }
    
    // 创建四元数
    Quaternion q;
    q.x = quatX;
    q.y = quatY;
    q.z = quatZ;
    q.w = quatW;
    
    // 将四元数转换为矩阵，与安卓的sensorRotationVector2Matrix保持一致
    Matrix4x4 matrix;
    rotationVectorToMatrix(q, matrix);
    
    // 应用显示旋转
    applyDisplayRotation(mDisplayRotation, matrix);
    
    // 保存到传感器矩阵（线程安全）
    std::lock_guard<std::mutex> lock(mMatrixLock);
    for (int i = 0; i < 16; i++) {
        mSensorMatrix[i] = matrix[i];
    }
    
    // 输出矩阵的前4个值，确认矩阵确实在变化
    MD_LOGI("UpdateGyroData: mSensorMatrix[0-3] = [%.3f, %.3f, %.3f, %.3f]", 
            mSensorMatrix[0], mSensorMatrix[1], mSensorMatrix[2], mSensorMatrix[3]);
}

// OpenGL相关方法实现
void MotionStrategy::updateDirectorsInGL() {
    if (!mIsOn) return;
    
    // 在OpenGL线程中更新传感器矩阵，与安卓的updateSensorRunnable保持一致
    std::lock_guard<std::mutex> lock(mMatrixLock);
    
    // 复制传感器矩阵到临时矩阵
    for (int i = 0; i < 16; i++) {
        mTmpMatrix[i] = mSensorMatrix[i];
    }
    
    // 检查OpenGL上下文是否有效
    GLint error = glGetError();
    if (error != GL_NO_ERROR) {
        MD_LOGE("updateDirectorsInGL: OpenGL error before update: %d", error);
    }
    
    // 在HarmonyOS中，由于C++层不能直接管理ETS层的director，
    // 我们通过getSensorMatrix方法暴露传感器矩阵，让ETS层获取并更新director
    MD_LOGI("updateDirectorsInGL called");
}

void MotionStrategy::applySensorMatrixToProgram(GLuint program, const char* matrixUniformName) {
    if (!mIsOn || program == 0 || matrixUniformName == nullptr) return;
    
    // 保存当前的program
    GLint currentProgram;
    glGetIntegerv(GL_CURRENT_PROGRAM, &currentProgram);
    if (glGetError() != GL_NO_ERROR) {
        MD_LOGE("applySensorMatrixToProgram: Failed to get current program");
        return;
    }
    
    bool needRestore = (currentProgram != program);
    
    // 切换到目标program
    if (needRestore) {
        glUseProgram(program);
        if (glGetError() != GL_NO_ERROR) {
            MD_LOGE("applySensorMatrixToProgram: Failed to use program %u", program);
            return;
        }
    }
    
    // 获取uniform变量位置
    GLint matrixLoc = glGetUniformLocation(program, matrixUniformName);
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        MD_LOGE("applySensorMatrixToProgram: Failed to get uniform location for '%s': %d", matrixUniformName, error);
    } else if (matrixLoc != -1) {
        // 获取传感器矩阵（线程安全）
        std::lock_guard<std::mutex> lock(mMatrixLock);
        
        // 将传感器矩阵应用到shader程序
        glUniformMatrix4fv(matrixLoc, 1, GL_FALSE, mTmpMatrix);
        error = glGetError();
        if (error != GL_NO_ERROR) {
            MD_LOGE("applySensorMatrixToProgram: Failed to set uniform matrix for '%s': %d", matrixUniformName, error);
        }
    } else {
        MD_LOGE("applySensorMatrixToProgram: Uniform '%s' not found in program %u", matrixUniformName, program);
    }
    
    // 恢复之前的program
    if (needRestore) {
        glUseProgram(currentProgram);
        if (glGetError() != GL_NO_ERROR) {
            MD_LOGE("applySensorMatrixToProgram: Failed to restore previous program");
        }
    }
    
    MD_LOGI("applySensorMatrixToProgram called with program %u, uniform %s", program, matrixUniformName);
    
}

// 获取传感器矩阵（供外部调用）
void MotionStrategy::getSensorMatrix(Matrix4x4 matrix) {
    if (!matrix) return;
    
    // 线程安全地获取传感器矩阵
    std::lock_guard<std::mutex> lock(mMatrixLock);
    for (int i = 0; i < 16; i++) {
        matrix[i] = mSensorMatrix[i];
    }
    
    // 每隔一段时间输出一次，确认矩阵被读取
    static int callCount = 0;
    if (++callCount % 60 == 0) {
        MD_LOGI("getSensorMatrix called (count=%d): matrix[0-3] = [%.3f, %.3f, %.3f, %.3f]", 
                callCount, matrix[0], matrix[1], matrix[2], matrix[3]);
    }
}
}
}