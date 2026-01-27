//
// Created on 2025/8/24.
//


#include "md_nativeimage_ref.h"
#include "../md_log.h"
#include "../md_defines.h"
#include <GLES3/gl3.h>
#include <GLES2/gl2ext.h>
#include <cstring>

namespace asha {
namespace vrlib {

MDNativeImageRef::MDNativeImageRef(int texture_id) {
    texture_id_ = texture_id;
    MD_LOGI("MDNativeImageRef::MDNativeImageRef: Creating NativeImage with texture_id=%d", texture_id);
    oh_image_ = OH_NativeImage_Create(texture_id, GL_TEXTURE_EXTERNAL_OES);
    if (oh_image_) {
        int ret = OH_NativeImage_GetSurfaceId(oh_image_, &surface_id_);
        if (ret == 0) {
            MD_LOGI("MDNativeImageRef::MDNativeImageRef: Successfully created NativeImage, surface_id=%llu", surface_id_);
        } else {
            MD_LOGE("MDNativeImageRef::MDNativeImageRef: Failed to get SurfaceId, error=%d", ret);
        }
    } else {
        MD_LOGE("MDNativeImageRef::MDNativeImageRef: Failed to create OH_NativeImage with texture_id=%d", texture_id);
    }
}

MDNativeImageRef::~MDNativeImageRef() {
    if (oh_image_) {
        OH_NativeImage_Destroy(&oh_image_);
    }
}

// 设置单位矩阵的辅助函数
static void SetIdentityMatrix(float* matrix) {
    if (!matrix) return;
    matrix[0] = 1.0f; matrix[1] = 0.0f; matrix[2] = 0.0f; matrix[3] = 0.0f;
    matrix[4] = 0.0f; matrix[5] = 1.0f; matrix[6] = 0.0f; matrix[7] = 0.0f;
    matrix[8] = 0.0f; matrix[9] = 0.0f; matrix[10] = 1.0f; matrix[11] = 0.0f;
    matrix[12] = 0.0f; matrix[13] = 0.0f; matrix[14] = 0.0f; matrix[15] = 1.0f;
}

// 应用Y轴翻转的辅助函数（用于修复视频上下颠倒）
// 变换矩阵是4x4矩阵，用于纹理坐标变换
// 矩阵格式（列主序）：
// [m0, m4, m8,  m12]
// [m1, m5, m9,  m13]
// [m2, m6, m10, m14]
// [m3, m7, m11, m15]
// 对于纹理坐标(u, v)，Y轴翻转需要：v' = 1 - v
// 这相当于应用翻转矩阵 F = [1, 0, 0, 0]
//                            [0, -1, 0, 1]
//                            [0, 0, 1, 0]
//                            [0, 0, 0, 1]
// 结果 = F * M
static void ApplyYFlip(float* matrix) {
    if (!matrix) return;
    // 保存原始值
    float m0 = matrix[0], m4 = matrix[4], m8 = matrix[8], m12 = matrix[12];
    float m1 = matrix[1], m5 = matrix[5], m9 = matrix[9], m13 = matrix[13];
    float m2 = matrix[2], m6 = matrix[6], m10 = matrix[10], m14 = matrix[14];
    float m3 = matrix[3], m7 = matrix[7], m11 = matrix[11], m15 = matrix[15];
    
    // 应用Y轴翻转矩阵 F * M
    // F的第二行是 [0, -1, 0, 1]
    matrix[0] = m0;  // 不变
    matrix[1] = -m1; // Y轴翻转
    matrix[2] = m2;  // 不变
    matrix[3] = m3;  // 不变
    
    matrix[4] = m4;  // 不变
    matrix[5] = -m5; // Y轴翻转
    matrix[6] = m6;  // 不变
    matrix[7] = m7;  // 不变
    
    matrix[8] = m8;  // 不变
    matrix[9] = -m9; // Y轴翻转
    matrix[10] = m10; // 不变
    matrix[11] = m11; // 不变
    
    matrix[12] = m12;      // 不变
    matrix[13] = 1.0f - m13; // Y轴翻转并平移：v' = -v + 1
    matrix[14] = m14;      // 不变
    matrix[15] = m15;      // 不变
}

// 静态变量用于跟踪错误计数和成功计数
static int g_update_surface_error_count = 0;
static int g_update_surface_success_count = 0;
static bool g_has_ever_succeeded = false; // 标记是否曾经成功过

int MDNativeImageRef::UpdateSurface(float* matrix) {
    if (!matrix) {
        MD_LOGE("MDNativeImageRef::UpdateSurface matrix is null");
        return MD_ERR;
    }
    
    // 如果没有有效的 NativeImage，使用单位矩阵
    if (!oh_image_) {
        MD_LOGE("MDNativeImageRef::UpdateSurface oh_image_ is null!");
        SetIdentityMatrix(matrix);
        return MD_ERR;
    }
    
    // 更新 Surface 图像
    // 注意：需要确保有视频源连接到这个 surface，否则可能会失败
    int ret = OH_NativeImage_UpdateSurfaceImage(oh_image_);
    if (ret != 0) {
        // 如果更新失败，检查是否曾经成功过
        // 如果曾经成功过，说明视频源已连接，偶尔失败是正常的（可能是缓冲区还没准备好）
        if (g_has_ever_succeeded) {
            // 曾经成功过，偶尔失败是正常的，使用上次的矩阵
            // 不重置成功计数，保持连接状态
            g_update_surface_error_count++;
            // 每 300 帧（约 5 秒）记录一次警告，避免日志过多
            if (g_update_surface_error_count % 300 == 0) {
                MD_LOGW("MDNativeImageRef::UpdateSurface: Temporary failure (error code: %d, frame: %d), but connection is established", ret, g_update_surface_error_count);
            }
            // 即使失败，也尝试获取变换矩阵（使用上次的值）
            ret = OH_NativeImage_GetTransformMatrix(oh_image_, matrix);
            if (ret == 0) {
                // 如果获取成功，应用Y轴翻转
                ApplyYFlip(matrix);
            }
            // 如果获取失败，保持当前矩阵不变（不重置为单位矩阵）
            return MD_OK; // 返回成功，因为连接已建立，只是这次更新失败
        } else {
            // 从未成功过，说明视频源还未连接
            if (g_update_surface_error_count == 0) {
                MD_LOGW("MDNativeImageRef::UpdateSurface UpdateSurfaceImage failed: %d (Surface not connected yet, this is normal during initialization)", ret);
            }
            g_update_surface_error_count++;
            // 每 60 帧（约 1 秒）记录一次警告，避免日志过多
            if (g_update_surface_error_count % 60 == 0) {
                MD_LOGW("MDNativeImageRef::UpdateSurface still waiting for video source connection (error count: %d, error code: %d)", g_update_surface_error_count, ret);
            }
            SetIdentityMatrix(matrix);
            return MD_ERR;
        }
    }
    
    // 更新成功
    g_has_ever_succeeded = true; // 标记曾经成功过
    
    // 如果成功，重置错误计数
    if (g_update_surface_error_count > 0) {
        MD_LOGI("MDNativeImageRef::UpdateSurface connected successfully after %d attempts", g_update_surface_error_count);
        g_update_surface_error_count = 0;
    }
    
    // 获取变换矩阵
    ret = OH_NativeImage_GetTransformMatrix(oh_image_, matrix);
    if (ret != 0) {
        // 如果获取失败，使用单位矩阵
        MD_LOGE("MDNativeImageRef::UpdateSurface GetTransformMatrix failed: %d, using identity matrix", ret);
        SetIdentityMatrix(matrix);
        return MD_ERR;
    }
    
    // 应用Y轴翻转以修复视频上下颠倒问题
    // 视频帧的坐标系原点在左上角，而OpenGL纹理坐标原点在左下角
    ApplyYFlip(matrix);
    
    // 每 60 帧记录一次成功日志（避免日志过多）
    g_update_surface_success_count++;
    if (g_update_surface_success_count % 60 == 0) {
        MD_LOGI("MDNativeImageRef::UpdateSurface: Successfully updating surface (frame %d)", g_update_surface_success_count);
    }
    
    return MD_OK;
}

int MDNativeImageRef::GetTextureId() {
    return texture_id_;
}

uint64_t MDNativeImageRef::GetSurfaceId() {
    return surface_id_;
}

bool MDNativeImageRef::IsValid() {
    return oh_image_ != nullptr;
}

}
}


