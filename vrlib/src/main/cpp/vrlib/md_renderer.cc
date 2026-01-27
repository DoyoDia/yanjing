//
// Created on 2025/8/23.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "md_renderer.h"
#include "md_log.h"
#include "md_defines.h"
#include "device/md_egl.h"
#include "device/md_nativeimage_ref.h"
#include "md_object_3d.h"
#include <unistd.h>
#include <thread>
#include <memory>
#include <GLES3/gl3.h>
#include <GLES2/gl2ext.h>
#include <cmath>
#include <mutex>
#include <vector>

namespace asha {
namespace vrlib {

const char* VERTEX_SHADER = R"(
    attribute vec4 a_Position;
    attribute vec2 a_TexCoordinate;
    uniform mat4 u_MVPMatrix;
    uniform mat4 u_STMatrix;
    varying vec2 v_TexCoordinate;
    void main() {
        v_TexCoordinate = (u_STMatrix * vec4(a_TexCoordinate, 0, 1)).xy;
        gl_Position = u_MVPMatrix * a_Position;
    }
)";

const char* FRAGMENT_SHADER = R"(
    #extension GL_OES_EGL_image_external : require
    precision mediump float;
    uniform samplerExternalOES u_Texture;
    varying vec2 v_TexCoordinate;
    void main() {
        // 使用视频纹理
        gl_FragColor = texture2D(u_Texture, v_TexCoordinate);
    }
)";

const char* VR_VERTEX_SHADER = R"(
    attribute vec4 a_Position;
    attribute vec2 a_TexCoordinate;
    uniform mat4 u_MVPMatrix;
    uniform mat4 u_STMatrix;
    varying vec2 vTexCoord;
    void main() {
        vTexCoord = (u_STMatrix * vec4(a_TexCoordinate, 0, 1)).xy;
        gl_Position = u_MVPMatrix * a_Position;
    }
)";

const char* VR_FRAGMENT_SHADER = R"(
    #extension GL_OES_EGL_image_external : require
    precision mediump float;
    varying vec2 vTexCoord;
    uniform samplerExternalOES u_Texture;
    uniform vec4 u_DistortionParams;

    vec2 BarrelDistortion(vec2 texCoord) {
        vec2 coords = texCoord - vec2(0.5);
        float rSq = coords.x * coords.x + coords.y * coords.y;
        vec2 distorted = coords * (u_DistortionParams.x + u_DistortionParams.y * rSq);
        return distorted + vec2(0.5);
    }

    void main() {
        vec2 distortedCoord = vTexCoord;
        
        // 只有当u_DistortionParams.y不为0时才应用桶形畸变
        if (u_DistortionParams.y != 0.0) {
            distortedCoord = BarrelDistortion(vTexCoord);
        }
        
        // 边界处理
        if (distortedCoord.x < 0.0 || distortedCoord.x > 1.0 || 
            distortedCoord.y < 0.0 || distortedCoord.y > 1.0) {
            gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        } else {
            gl_FragColor = texture2D(u_Texture, distortedCoord);
        }
    }
)";

class MD360RendererPrivate : public MD360RendererAPI, public std::enable_shared_from_this<MD360RendererPrivate> {
public:
    virtual int SetSurface(std::shared_ptr<MDNativeWindowRef> ref) override {
        int result = egl_->SetRenderWindow(ref);
        if (result == MD_OK) {
            // 设置一个标志，在 RunGL 线程中实际获取尺寸
            surface_size_dirty_ = true;
            pending_window_ref_ = ref;
            MD_LOGI("MD360RendererPrivate::SetSurface: surface set, will update size in GL thread");
        } else {
            MD_LOGW("MD360RendererPrivate::SetSurface: SetRenderWindow failed, result=%d", result);
            // 即使SetRenderWindow失败，也设置默认值
            surface_width_ = 1920;
            surface_height_ = 1080;
        }
        return result;
    }

    void UpdateProjectionMatrixForCurrentSurface() {
        std::lock_guard<std::mutex> lock(mutex_);
        
        if (surface_width_ <= 0 || surface_height_ <= 0) {
            MD_LOGW("UpdateProjectionMatrixForCurrentSurface: Invalid surface size %dx%d", 
                   surface_width_, surface_height_);
            return;
        }
        
        // 计算基于实际屏幕尺寸的投影矩阵
        float aspectRatio = static_cast<float>(surface_width_) / static_cast<float>(surface_height_);
        float fovY = 60.0f; // 视野角度
        float nearPlane = 0.1f;
        float farPlane = 100.0f;
        
        // 计算透视投影矩阵
        float f = 1.0f / tan(fovY * 0.5f * M_PI / 180.0f);
        float range = nearPlane - farPlane;
        
        current_mvp_matrix_[0] = f / aspectRatio;
        current_mvp_matrix_[1] = 0.0f;
        current_mvp_matrix_[2] = 0.0f;
        current_mvp_matrix_[3] = 0.0f;
        
        current_mvp_matrix_[4] = 0.0f;
        current_mvp_matrix_[5] = f;
        current_mvp_matrix_[6] = 0.0f;
        current_mvp_matrix_[7] = 0.0f;
        
        current_mvp_matrix_[8] = 0.0f;
        current_mvp_matrix_[9] = 0.0f;
        current_mvp_matrix_[10] = (farPlane + nearPlane) / range;
        current_mvp_matrix_[11] = -1.0f;
        
        current_mvp_matrix_[12] = 0.0f;
        current_mvp_matrix_[13] = 0.0f;
        current_mvp_matrix_[14] = 2.0f * farPlane * nearPlane / range;
        current_mvp_matrix_[15] = 0.0f;
        
        MD_LOGI("UpdateProjectionMatrixForCurrentSurface: Updated MVP matrix for aspect ratio %.3f", aspectRatio);
    }

    // VR模式专用的投影矩阵计算
    void CalculateVRProjectionMatrix(float* projection_matrix, float aspect_ratio) {
        // 安卓的frustumM逻辑，但用于VR模式
        float left = -aspect_ratio / 2.0f;
        float right = aspect_ratio / 2.0f;
        float bottom = -0.5f;
        float top = 0.5f;
        float near = 0.7f;
        float far = 500.0f;
        
        // 计算frustum投影矩阵
        float rl = 1.0f / (right - left);
        float tb = 1.0f / (top - bottom);
        float fn = 1.0f / (far - near);
        
        projection_matrix[0] = 2.0f * near * rl;
        projection_matrix[1] = 0.0f;
        projection_matrix[2] = 0.0f;
        projection_matrix[3] = 0.0f;
        
        projection_matrix[4] = 0.0f;
        projection_matrix[5] = 2.0f * near * tb;
        projection_matrix[6] = 0.0f;
        projection_matrix[7] = 0.0f;
        
        projection_matrix[8] = (right + left) * rl;
        projection_matrix[9] = (top + bottom) * tb;
        projection_matrix[10] = -(far + near) * fn;
        projection_matrix[11] = -1.0f;
        
        projection_matrix[12] = 0.0f;
        projection_matrix[13] = 0.0f;
        projection_matrix[14] = -2.0f * far * near * fn;
        projection_matrix[15] = 0.0f;
    }

    virtual void UpdateMVPMatrix(float* matrix) override {
        std::lock_guard<std::mutex> lock(mutex_);
        if (matrix) {
            std::copy(matrix, matrix + 16, current_mvp_matrix_);
            // 外部设置矩阵时，如果当前是VR模式，只更新current_mvp_matrix_但不改变触控标志
            if (!vr_config_.enabled) {
                // 普通模式下，外部设置矩阵则禁用触控
                use_touch_control_ = false;
            }
        }
    }

    virtual void UpdateTouchDelta(float deltaX, float deltaY) override {
        std::lock_guard<std::mutex> lock(mutex_);
        
        // 累积触摸delta值
        float old_touch_x = touch_delta_x_;
        float old_touch_y = touch_delta_y_;
        touch_delta_x_ += deltaX;
        touch_delta_y_ += deltaY;
        
        use_touch_control_ = true;
        mvp_matrix_dirty_ = true;
    }

    virtual uint64_t GetVideoSurfaceId() override {
        return surface_id_;
    }

    virtual void SetClearColor(float r, float g, float b, float a) override {
        std::lock_guard<std::mutex> lock(mutex_);
        MD_LOGI("MD360RendererPrivate::SetClearColor called: r=%.3f, g=%.3f, b=%.3f, a=%.3f", r, g, b, a);
        clear_color_[0] = r;
        clear_color_[1] = g;
        clear_color_[2] = b;
        clear_color_[3] = a;
    }

    virtual void SetCullFaceEnabled(bool enabled) override {
        std::lock_guard<std::mutex> lock(mutex_);
        MD_LOGI("MD360RendererPrivate::SetCullFaceEnabled called: enabled=%s", enabled ? "true" : "false");
        cull_face_enabled_ = enabled;
        // 状态会在 OnDrawFrame 中应用
    }

    virtual void SetDepthTestEnabled(bool enabled) override {
        std::lock_guard<std::mutex> lock(mutex_);
        MD_LOGI("MD360RendererPrivate::SetDepthTestEnabled called: enabled=%s", enabled ? "true" : "false");
        depth_test_enabled_ = enabled;
        // 状态会在 OnDrawFrame 中应用
    }

    virtual void SetViewport(int x, int y, int width, int height) override {
        std::lock_guard<std::mutex> lock(mutex_);
        viewport_x_ = x;
        viewport_y_ = y;
        viewport_width_ = width;
        viewport_height_ = height;
        viewport_set_ = true;
    }

    virtual void SetScissor(int x, int y, int width, int height) override {
        std::lock_guard<std::mutex> lock(mutex_);
        scissor_x_ = x;
        scissor_y_ = y;
        scissor_width_ = width;
        scissor_height_ = height;
    }

    virtual void SetScissorEnabled(bool enabled) override {
        std::lock_guard<std::mutex> lock(mutex_);
        scissor_enabled_ = enabled;
    }

    virtual void SetBlendEnabled(bool enabled) override {
        std::lock_guard<std::mutex> lock(mutex_);
        MD_LOGI("MD360RendererPrivate::SetBlendEnabled called: enabled=%s", enabled ? "true" : "false");
        blend_enabled_ = enabled;
    }

    virtual void SetBlendFunc(int src, int dst) override {
        std::lock_guard<std::mutex> lock(mutex_);
        MD_LOGI("MD360RendererPrivate::SetBlendFunc called: src=0x%x, dst=0x%x", src, dst);
        blend_src_ = src;
        blend_dst_ = dst;
    }

    virtual void SetProjectionMode(int mode) override {
        std::lock_guard<std::mutex> lock(mutex_);
        MD_LOGI("MD360RendererPrivate::SetProjectionMode called: mode=%d", mode);
        
        // 在 GL 线程中重新创建 3D 对象
        // 注意：这里只是标记需要更新，实际更新在 OnDrawFrame 中进行
        pending_projection_mode_change_ = true;
        pending_projection_mode_ = mode;
    }
    
    // 在 GL 线程中更新投影模式（由 OnDrawFrame 调用）
    void UpdateProjectionModeIfNeeded() {
        std::lock_guard<std::mutex> lock(mutex_);
        if (pending_projection_mode_change_) {
            pending_projection_mode_change_ = false;
            int mode = pending_projection_mode_;
            
            // 销毁旧的 3D 对象
            if (object3d_) {
                object3d_->Destroy();
                object3d_ = nullptr;
            }
            
            // 创建新的 3D 对象
            object3d_ = std::make_shared<MDObject3D>();
            
            // 根据模式加载不同的几何体
            switch (mode) {
                case 201: // PROJECTION_MODE_SPHERE
                    object3d_->LoadSphere();
                    MD_LOGI("MD360RendererPrivate::UpdateProjectionMode: Loaded SPHERE");
                    break;
                case 202: // PROJECTION_MODE_DOME180
                    object3d_->LoadDome(180.0f, false);
                    MD_LOGI("MD360RendererPrivate::UpdateProjectionMode: Loaded DOME180");
                    break;
                case 203: // PROJECTION_MODE_DOME230
                    object3d_->LoadDome(230.0f, false);
                    MD_LOGI("MD360RendererPrivate::UpdateProjectionMode: Loaded DOME230");
                    break;
                case 204: // PROJECTION_MODE_DOME180_UPPER
                    object3d_->LoadDome(180.0f, true);
                    MD_LOGI("MD360RendererPrivate::UpdateProjectionMode: Loaded DOME180_UPPER");
                    break;
                case 205: // PROJECTION_MODE_DOME230_UPPER
                    object3d_->LoadDome(230.0f, true);
                    MD_LOGI("MD360RendererPrivate::UpdateProjectionMode: Loaded DOME230_UPPER");
                    break;
                case 214: // PROJECTION_MODE_CUBE
                    object3d_->LoadCube();
                    MD_LOGI("MD360RendererPrivate::UpdateProjectionMode: Loaded CUBE");
                    break;
                default:
                    object3d_->LoadSphere();
                    MD_LOGW("MD360RendererPrivate::UpdateProjectionMode: Unknown mode %d, using SPHERE", mode);
                    break;
            }
        }
    }

    // 在 GL 线程中清理 VR 资源（由 OnDrawFrame 调用）
    void CleanupVRResourcesIfNeeded() {
        std::lock_guard<std::mutex> lock(mutex_);
        if (pending_vr_cleanup_) {
            pending_vr_cleanup_ = false;
            
            // 清理VR shader程序
            if (vr_program_ != 0) {
                glDeleteProgram(vr_program_);
                vr_program_ = 0;
            }
            
            vr_shaders_initialized_ = false;
            vr_mvp_matrix_loc_ = -1;
            vr_st_matrix_loc_ = -1;
            vr_texture_loc_ = -1;
            vr_distortion_params_loc_ = -1;
            vr_eye_offset_loc_ = -1;
        }
    }

    // VR模式接口实现
    virtual void SetVRModeEnabled(bool enabled) override {
        std::lock_guard<std::mutex> lock(mutex_);
        
        // 如果切换到VR模式，需要先清理旧的VR shader资源
        if (enabled && vr_shaders_initialized_) {
            // 标记需要清理，下一帧会在GL线程中清理旧资源
            // 然后 InitVRShaders 会创建新的
            pending_vr_cleanup_ = true;
        }
        
        vr_config_.enabled = enabled;
        
        // 设置合理的默认参数
        if (enabled) {
            // 默认瞳距64mm
            vr_config_.ipd = 0.064f;
            // 默认眼偏移
            vr_config_.eyeOffset = 0.03f;
            // 默认桶形畸变参数（轻微畸变）
            vr_config_.k1 = 0.9f;
            vr_config_.k2 = 0.1f;
            vr_config_.scale = 0.95f;
            vr_config_.barrelDistortionEnabled = true;
            
            // 重置着色器状态，下次渲染时会重新初始化
            // 注意：不要在这里删除shader，因为不在GL线程
            vr_shaders_initialized_ = false;
            
            // VR模式下也启用触控
            use_touch_control_ = true;
        } else {
            // 切换到非VR模式时，标记需要清理VR资源
            // 实际清理会在GL线程的下一帧进行
            pending_vr_cleanup_ = true;
        }
    }

    virtual void SetIPD(float ipd) override {
        std::lock_guard<std::mutex> lock(mutex_);
        vr_config_.ipd = ipd;
        MD_LOGI("MD360RendererPrivate::SetIPD: %f", ipd);
    }

    virtual void SetBarrelDistortionEnabled(bool enabled) override {
        std::lock_guard<std::mutex> lock(mutex_);
        vr_config_.barrelDistortionEnabled = enabled;
        MD_LOGI("MD360RendererPrivate::SetBarrelDistortionEnabled: %s", enabled ? "true" : "false");
    }

    virtual void SetBarrelDistortionParams(float k1, float k2, float scale) override {
        std::lock_guard<std::mutex> lock(mutex_);
        
        if (k1 < 0.1f || k1 > 2.0f) {
            MD_LOGW("MD360RendererPrivate::SetBarrelDistortionParams: k1=%f out of range (0.1-2.0), clamping", k1);
            k1 = std::max(0.1f, std::min(k1, 2.0f));
        }
        
        if (k2 < -1.0f || k2 > 1.0f) {
            MD_LOGW("MD360RendererPrivate::SetBarrelDistortionParams: k2=%f out of range (-1.0-1.0), clamping", k2);
            k2 = std::max(-1.0f, std::min(k2, 1.0f));
        }
        
        if (scale < 0.1f || scale > 2.0f) {
            MD_LOGW("MD360RendererPrivate::SetBarrelDistortionParams: scale=%f out of range (0.1-2.0), clamping", scale);
            scale = std::max(0.1f, std::min(scale, 2.0f));
        }
        
        vr_config_.k1 = k1;
        vr_config_.k2 = k2;
        vr_config_.scale = scale;
        
        MD_LOGI("MD360RendererPrivate::SetBarrelDistortionParams: k1=%f, k2=%f, scale=%f", k1, k2, scale);
    }

    virtual void SetEyeOffset(float offset) override {
        std::lock_guard<std::mutex> lock(mutex_);
        vr_config_.eyeOffset = offset;
        MD_LOGI("MD360RendererPrivate::SetEyeOffset: %f", offset);
    }

    virtual bool IsVRModeEnabled() const override {
        return vr_config_.enabled;
    }
    
    virtual void UpdateSensorMatrix(float* matrix) override {
        std::lock_guard<std::mutex> lock(mutex_);
        if (matrix) {
            std::copy(matrix, matrix + 16, sensor_matrix_);
            sensor_matrix_updated_ = true;
            MD_LOGI("UpdateSensorMatrix: matrix[0-3]=[%.3f, %.3f, %.3f, %.3f]", 
                   sensor_matrix_[0], sensor_matrix_[1], sensor_matrix_[2], sensor_matrix_[3]);
        }
    }

    virtual int OnDrawFrame() override {
        // 检查是否需要更新投影模式
        UpdateProjectionModeIfNeeded();
        
        // 检查是否需要清理VR资源（在GL线程中执行）
        CleanupVRResourcesIfNeeded();
        
        // 设置清除颜色和渲染状态
        {
            std::lock_guard<std::mutex> lock(mutex_);
            glClearColor(clear_color_[0], clear_color_[1], clear_color_[2], clear_color_[3]);
            
            // 应用渲染状态
            if (cull_face_enabled_) {
                glEnable(GL_CULL_FACE);
                // 对于360度视频，需要从球体内部看，所以设置顺时针为正面
                glFrontFace(GL_CW);
            } else {
                glDisable(GL_CULL_FACE);
            }
            
            if (depth_test_enabled_) {
                glEnable(GL_DEPTH_TEST);
                glDepthFunc(GL_LEQUAL);
            } else {
                glDisable(GL_DEPTH_TEST);
            }
            
            // VR模式下不在这里设置viewport，由RenderVRStereo处理
            if (!vr_config_.enabled) {
                if (viewport_set_) {
                    glViewport(viewport_x_, viewport_y_, viewport_width_, viewport_height_);
                } else {
                    int viewport_width = surface_width_ > 0 ? surface_width_ : 1920;
                    int viewport_height = surface_height_ > 0 ? surface_height_ : 1080;
                    glViewport(0, 0, viewport_width, viewport_height);
                }
                
                // 应用裁剪状态
                if (scissor_enabled_) {
                    glEnable(GL_SCISSOR_TEST);
                    glScissor(scissor_x_, scissor_y_, scissor_width_, scissor_height_);
                } else {
                    glDisable(GL_SCISSOR_TEST);
                }
            }
            
            // 应用混合状态
            if (blend_enabled_) {
                glEnable(GL_BLEND);
                glBlendFunc(blend_src_, blend_dst_);
            } else {
                glDisable(GL_BLEND);
            }
        }
        
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        if (vr_config_.enabled) {
            return RenderVRStereo();
        } else {
            return RenderNormalMode();
        }
    }

    //// MD360LifecycleAPI
    virtual int Init() override {
        if (is_init_) {
            return MD_OK;
        }
        is_init_ = true;
        // 使用 this->shared_from_this() 来明确调用基类的方法
        std::weak_ptr<MD360RendererPrivate> weak_this = this->shared_from_this();
        thread_ = std::thread([=]() {
            auto shared_this = weak_this.lock();
            if (shared_this == nullptr) {
                return;
            }
            shared_this->RunGL();
            MD_LOGI("MD360RendererPrivate gl thread exit ok.");
        });
        return MD_OK;
    }
    virtual int Destroy() override {
        if (is_destroyed_) {
            return MD_OK;
        }
        is_destroyed_ = true;
        MD_LOGI("MD360RendererPrivate::Destroy");
        
        // 等待渲染线程退出
        if (thread_.joinable()) {
            thread_.join();
            MD_LOGI("MD360RendererPrivate::Destroy thread joined");
        }
        
        return MD_OK;
    }
    virtual int Resume() override {
        is_paused_ = false;
        return MD_OK;
    }
    virtual int Pause() override {
        is_paused_ = true;
        return MD_OK;
    }
private:

    int RenderNormalMode() {
        if (program_ == 0) {
            MD_LOGE("MD360RendererPrivate::OnDrawFrame: program_ is 0!");
            return MD_ERR;
        }

        glUseProgram(program_);
        
        // 检查 OpenGL 错误
        GLenum gl_error = glGetError();
        if (gl_error != GL_NO_ERROR) {
            MD_LOGE("MD360RendererPrivate::OnDrawFrame: OpenGL error after glUseProgram: 0x%x", gl_error);
        }
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, texture_id_);
        glUniform1i(u_texture_loc_, 0);
        
        // 检查纹理绑定是否成功
        gl_error = glGetError();
        if (gl_error != GL_NO_ERROR) {
            MD_LOGE("MD360RendererPrivate::OnDrawFrame: OpenGL error after texture bind: 0x%x, texture_id=%u", gl_error, texture_id_);
        }
        
        // 验证纹理是否有效（每 60 帧检查一次）
        static int texture_check_count = 0;
        texture_check_count++;
        if (texture_check_count % 60 == 0) {
            GLint texture_params[4] = {0};
            // 注意：GL_TEXTURE_EXTERNAL_OES 不支持 glGetTexParameteriv，所以这里只检查错误
            gl_error = glGetError();
            if (gl_error == GL_NO_ERROR) {
                MD_LOGI("MD360RendererPrivate::OnDrawFrame: Texture %u bound successfully", texture_id_);
            } else {
                MD_LOGE("MD360RendererPrivate::OnDrawFrame: Texture binding error: 0x%x", gl_error);
            }
        }
        
        float mvp[16];
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (use_touch_control_ && mvp_matrix_dirty_) {
                // 使用触摸控制：根据 deltaX/deltaY 计算旋转矩阵并更新 MVP
                UpdateMVPMatrixFromTouch();
                mvp_matrix_dirty_ = false;
                
            }
            std::copy(current_mvp_matrix_, current_mvp_matrix_ + 16, mvp);
        }
        
        glUniformMatrix4fv(u_mvp_matrix_loc_, 1, GL_FALSE, mvp);
        
        glUniformMatrix4fv(u_st_matrix_loc_, 1, GL_FALSE, st_matrix_);
        
        // 每 60 帧记录一次渲染状态
        static int draw_frame_count = 0;
        draw_frame_count++;
        if (draw_frame_count % 60 == 0) {
            MD_LOGI("MD360RendererPrivate::OnDrawFrame: Frame %d, video_connected_=%s, texture_id=%u", 
                    draw_frame_count, video_connected_ ? "true" : "false", texture_id_);
        }
        
        if (object3d_) {
            object3d_->Draw();
        } else {
            MD_LOGE("MD360RendererPrivate::OnDrawFrame: object3d_ is null!");
        }
        
        // 最终检查 OpenGL 错误
        gl_error = glGetError();
        if (gl_error != GL_NO_ERROR) {
            MD_LOGE("MD360RendererPrivate::OnDrawFrame: OpenGL error at end: 0x%x", gl_error);
        }
        
        return MD_OK;
    }

    int RenderVRStereo() {
        if (surface_width_ <= 0 || surface_height_ <= 0) {
            return MD_ERR;
        }
        
        if (!vr_shaders_initialized_) {
            int result = InitVRShaders();
            if (result != MD_OK) {
                return result;
            }
        }
        
        // VR模式也处理触控更新
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (use_touch_control_ && mvp_matrix_dirty_) {
                UpdateMVPMatrixFromTouch();
                mvp_matrix_dirty_ = false;
                
            }
        }
        // 计算每个眼睛的视口
        int eye_width = surface_width_ / 2;
        int eye_height = surface_height_;
        
        // 渲染左右眼
        for (int eye_index = 0; eye_index < 2; eye_index++) {
            RenderEye(eye_index, eye_width, eye_height);
        }
        
        return MD_OK;
    }

    void RenderEye(int eye_index, int width, int height) {
        if (!vr_shaders_initialized_) {
            if (InitVRShaders() != MD_OK) return;
        }
        
        glUseProgram(vr_program_);
        
        // 设置视口
        int viewport_x = (width * eye_index);
        int viewport_y = 0;
        glViewport(viewport_x, viewport_y, width, height);
        
        // 启用裁剪
        glEnable(GL_SCISSOR_TEST);
        glScissor(viewport_x, viewport_y, width, height);
        
        // 清空当前眼睛区域
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        // 计算MVP矩阵
        EyeType eye = (eye_index == 0) ? LEFT_EYE : RIGHT_EYE;
        float eye_mvp_matrix[16];
        CalculateEyeMVPMatrix(eye, eye_mvp_matrix);
        
        // 传递矩阵到shader
        glUniformMatrix4fv(vr_mvp_matrix_loc_, 1, GL_FALSE, eye_mvp_matrix);
        glUniformMatrix4fv(vr_st_matrix_loc_, 1, GL_FALSE, st_matrix_);
        
        // 设置桶形畸变参数
        if (vr_config_.barrelDistortionEnabled) {
            float distortion_params[4] = {vr_config_.k1, vr_config_.k2, 0.0f, 0.0f};
            glUniform4f(vr_distortion_params_loc_, 
                    distortion_params[0], distortion_params[1], 
                    distortion_params[2], distortion_params[3]);
        } else {
            // 禁用桶形畸变
            glUniform4f(vr_distortion_params_loc_, 1.0f, 0.0f, 0.0f, 0.0f);
        }
        
        // 绑定纹理
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, texture_id_);
        glUniform1i(vr_texture_loc_, 0);
        
        // 渲染
        if (object3d_) {
            object3d_->Draw();
        }
        
        glDisable(GL_SCISSOR_TEST);
    }

    void CalculateEyeViewport(EyeType eye, int& x, int& y, int& width, int& height) {
        // 确保使用有效的表面尺寸
        int surfaceWidth = surface_width_;
        int surfaceHeight = surface_height_;
        
        if (surfaceWidth <= 0 || surfaceHeight <= 0) {
            // 使用默认值
            surfaceWidth = 1920;
            surfaceHeight = 1080;
        }
        
        // VR模式：将屏幕水平分成两半
        // 注意：这里需要确保每个眼睛的视口精确分割屏幕
        width = surfaceWidth / 2;
        height = surfaceHeight;
        x = (eye == LEFT_EYE) ? 0 : width;
        y = 0;
        
        // 如果屏幕宽度是奇数，需要调整第二个眼睛的宽度
        if (eye == RIGHT_EYE && surfaceWidth % 2 != 0) {
            // 第二个眼睛的宽度需要增加1个像素，确保覆盖整个屏幕
            width = surfaceWidth - (surfaceWidth / 2);
            x = surfaceWidth / 2; // 从中间开始
        }
    }
    void CalculateEyeMVPMatrixSimple(EyeType eye, float* resultMvp) {
        // 使用统一的MVP矩阵作为基础
        std::lock_guard<std::mutex> lock(mutex_);
        
        // 复制当前的MVP矩阵
        float base_mvp[16];
        std::copy(current_mvp_matrix_, current_mvp_matrix_ + 16, base_mvp);
        
        // 计算眼睛的宽高比
        float eye_width = static_cast<float>(surface_width_) / 2.0f;
        float eye_height = static_cast<float>(surface_height_);
        float eye_aspect_ratio = eye_width / eye_height;
        
        // 创建VR专用的投影矩阵
        float vr_projection[16];
        CalculateVRProjectionMatrix(vr_projection, eye_aspect_ratio);
        
        // 使用当前视图矩阵和模型矩阵，但用VR投影矩阵
        float mv_matrix[16];
        MultiplyMatrix(mv_matrix, view_matrix_, model_matrix_);
        MultiplyMatrix(resultMvp, vr_projection, mv_matrix);
        
        // 应用眼偏移（通过调整视图矩阵实现立体效果）
        float eye_offset = (eye == LEFT_EYE) ? -vr_config_.ipd * 0.5f : vr_config_.ipd * 0.5f;
        resultMvp[12] += eye_offset;
    }
    int InitVRShaders() {
        if (vr_shaders_initialized_) {
            return MD_OK;
        }
        
        // 先清理旧的shader资源（如果存在）
        if (vr_program_ != 0) {
            glDeleteProgram(vr_program_);
            vr_program_ = 0;
        }
        // shader对象在之前的InitVRShaders中已经被删除了，所以不需要再删除
        
        // 加载顶点着色器
        vr_vertex_shader_ = LoadShader(GL_VERTEX_SHADER, VR_VERTEX_SHADER);
        if (vr_vertex_shader_ == 0) {
            MD_LOGE("InitVRShaders: Failed to load vertex shader");
            return MD_ERR_SHADER_COMPILE;
        }
        
        // 加载片段着色器
        vr_fragment_shader_ = LoadShader(GL_FRAGMENT_SHADER, VR_FRAGMENT_SHADER);
        if (vr_fragment_shader_ == 0) {
            MD_LOGE("InitVRShaders: Failed to load fragment shader");
            glDeleteShader(vr_vertex_shader_);
            vr_vertex_shader_ = 0;
            return MD_ERR_SHADER_COMPILE;
        }
        
        // 创建程序
        vr_program_ = glCreateProgram();
        glAttachShader(vr_program_, vr_vertex_shader_);
        glAttachShader(vr_program_, vr_fragment_shader_);
        
        // 绑定属性
        glBindAttribLocation(vr_program_, 0, "a_Position");
        glBindAttribLocation(vr_program_, 1, "a_TexCoordinate");
        
        // 链接程序
        glLinkProgram(vr_program_);
        
        GLint linked;
        glGetProgramiv(vr_program_, GL_LINK_STATUS, &linked);
        if (!linked) {
            MD_LOGE("InitVRShaders: Program link failed");
            GLint infoLen = 0;
            glGetProgramiv(vr_program_, GL_INFO_LOG_LENGTH, &infoLen);
            if (infoLen > 1) {
                char* infoLog = new char[infoLen];
                glGetProgramInfoLog(vr_program_, infoLen, nullptr, infoLog);
                MD_LOGE("InitVRShaders: Link error: %s", infoLog);
                delete[] infoLog;
            }
            glDeleteProgram(vr_program_);
            glDeleteShader(vr_vertex_shader_);
            glDeleteShader(vr_fragment_shader_);
            vr_program_ = 0;
            vr_vertex_shader_ = 0;
            vr_fragment_shader_ = 0;
            return MD_ERR_SHADER_LINK;
        }
        
        // 获取uniform位置
        vr_mvp_matrix_loc_ = glGetUniformLocation(vr_program_, "u_MVPMatrix");
        vr_st_matrix_loc_ = glGetUniformLocation(vr_program_, "u_STMatrix");
        vr_texture_loc_ = glGetUniformLocation(vr_program_, "u_Texture");
        vr_distortion_params_loc_ = glGetUniformLocation(vr_program_, "u_DistortionParams");
        
        // 清理着色器对象
        glDeleteShader(vr_vertex_shader_);
        glDeleteShader(vr_fragment_shader_);
        
        vr_shaders_initialized_ = true;
        return MD_OK;
    }

    void CalculateEyeMVPMatrix(EyeType eye, float* resultMvp) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        // 对于VR模式，使用透视投影矩阵
        float eye_width = static_cast<float>(surface_width_) / 2.0f;
        float eye_height = static_cast<float>(surface_height_);
        float eye_aspect_ratio = eye_width / eye_height;
        
        // 使用适当的视野角度
        const float fovY = 120.0f; // 垂直视野120度
        const float nearPlane = 0.1f;
        const float farPlane = 100.0f;
        
        // 计算透视投影矩阵
        float f = 1.0f / tan(fovY * 0.5f * M_PI / 180.0f);
        float range = nearPlane - farPlane;
        
        float eye_projection[16];
        eye_projection[0] = f / eye_aspect_ratio;
        eye_projection[1] = 0.0f;
        eye_projection[2] = 0.0f;
        eye_projection[3] = 0.0f;
        
        eye_projection[4] = 0.0f;
        eye_projection[5] = f;
        eye_projection[6] = 0.0f;
        eye_projection[7] = 0.0f;
        
        eye_projection[8] = 0.0f;
        eye_projection[9] = 0.0f;
        eye_projection[10] = (farPlane + nearPlane) / range;
        eye_projection[11] = -1.0f;
        
        eye_projection[12] = 0.0f;
        eye_projection[13] = 0.0f;
        eye_projection[14] = 2.0f * farPlane * nearPlane / range;
        eye_projection[15] = 0.0f;
        
        // 组合视图矩阵：传感器矩阵 × 触控旋转矩阵
        float combined_view[16];
        if (sensor_matrix_updated_) {
            // 如果有传感器数据，使用传感器矩阵 × 触控视图矩阵
            MultiplyMatrix(combined_view, sensor_matrix_, view_matrix_);
        } else {
            // 否则只使用触控视图矩阵
            std::copy(view_matrix_, view_matrix_ + 16, combined_view);
        }
        
        // 应用眼偏移（实现立体效果）
        float eye_offset = (eye == LEFT_EYE) ? -vr_config_.ipd * 0.5f : vr_config_.ipd * 0.5f;
        combined_view[12] += eye_offset;
        
        // 模型矩阵
        float model_matrix[16] = {
            1.0f, 0.0f, 0.0f, 0.0f,
            0.0f, 1.0f, 0.0f, 0.0f,
            0.0f, 0.0f, 1.0f, 0.0f,
            0.0f, 0.0f, 0.0f, 1.0f
        };
        
        // 计算MVP矩阵：Projection × View × Model
        float mv_matrix[16];
        MultiplyMatrix(mv_matrix, combined_view, model_matrix);
        MultiplyMatrix(resultMvp, mv_matrix, eye_projection);
    }

    int OnSurfaceIdChanged(uint64_t surface_id) {
        // Notify ArkTS about the surfaceId (via callback or event, but here we just log)
        MD_LOGI("OnSurfaceIdChanged: %llu", surface_id);
        return MD_OK;
    }

    GLuint LoadShader(GLenum type, const char* shaderSrc) {
        GLuint shader = glCreateShader(type);
        glShaderSource(shader, 1, &shaderSrc, nullptr);
        glCompileShader(shader);
        GLint compiled;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
        if (!compiled) {
            GLint infoLen = 0;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
            if (infoLen > 1) {
                char* infoLog = new char[infoLen];
                glGetShaderInfoLog(shader, infoLen, nullptr, infoLog);
                MD_LOGE("Error compiling shader: %s", infoLog);
                delete[] infoLog;
            }
            glDeleteShader(shader);
            return 0;
        }
        return shader;
    }

    void InitShaders() {
        GLuint vertexShader = LoadShader(GL_VERTEX_SHADER, VERTEX_SHADER);
        GLuint fragmentShader = LoadShader(GL_FRAGMENT_SHADER, FRAGMENT_SHADER);
        
        program_ = glCreateProgram();
        glAttachShader(program_, vertexShader);
        glAttachShader(program_, fragmentShader);
        
        // Bind attributes before linking
        glBindAttribLocation(program_, 0, "a_Position");
        glBindAttribLocation(program_, 1, "a_TexCoordinate");
        
        glLinkProgram(program_);
        
        GLint linked;
        glGetProgramiv(program_, GL_LINK_STATUS, &linked);
        if (!linked) {
            MD_LOGE("Error linking program");
            glDeleteProgram(program_);
            program_ = 0;
            return;
        }
        
        u_mvp_matrix_loc_ = glGetUniformLocation(program_, "u_MVPMatrix");
        u_texture_loc_ = glGetUniformLocation(program_, "u_Texture");
        u_st_matrix_loc_ = glGetUniformLocation(program_, "u_STMatrix");
        
        glDeleteShader(vertexShader);
        glDeleteShader(fragmentShader);
    }

    int RunGL() {
        if (is_destroyed_) {
            return MD_OK;
        }
        int ret = egl_->Prepare();
        if (ret != MD_OK) {
            MD_LOGE("egl_->Prepare failed");
        }
        ret = egl_->MakeCurrent(true);
        if (ret != MD_OK) {
            MD_LOGE("egl_->MakeCurrent failed");
        }

        if (surface_size_dirty_) {
            UpdateSurfaceSizeInGLThread();
        }

        // Init GL resources
        InitShaders();
        
        // 初始化默认投影矩阵（确保球体可见）
        InitDefaultProjectionMatrix();
        
        object3d_ = std::make_shared<MDObject3D>();
        
        // 始终使用球面投影（对于360度视频）
        object3d_->SetProjectionType(MDObject3D::SPHERE);
        MD_LOGI("MD360RendererPrivate::RunGL: Using SPHERE projection for 360 video");
        
        // 初始化渲染状态（默认启用）
        {
            std::lock_guard<std::mutex> lock(mutex_);
            MD_LOGI("MD360RendererPrivate::RunGL initializing render states");
            
            // 对于360度视频，需要从球体内部看，所以禁用面剔除或设置正确的正面
            glDisable(GL_CULL_FACE);
            glEnable(GL_DEPTH_TEST);
            glDepthFunc(GL_LEQUAL);
            
            cull_face_enabled_ = false;  // 禁用面剔除
            depth_test_enabled_ = true;  // 启用深度测试
        }
        
        glGenTextures(1, &texture_id_);
        MD_LOGI("MD360RendererPrivate::RunGL: Generated texture_id=%u", texture_id_);
        
        // 绑定纹理并设置纹理参数（必须在创建 NativeImage 之前）
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, texture_id_);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        MD_LOGI("MD360RendererPrivate::RunGL: Set texture parameters for texture_id=%u", texture_id_);
        
        // 创建NativeImage
        std::shared_ptr<MDNativeImageRef> native_image_ref = std::make_shared<MDNativeImageRef>(texture_id_);
        if (!native_image_ref->IsValid()) {
            MD_LOGE("MD360RendererPrivate::RunGL: Failed to create valid MDNativeImageRef!");
        }
        surface_id_ = native_image_ref->GetSurfaceId();
        MD_LOGI("MD360RendererPrivate::RunGL: Created NativeImage, surface_id=%llu", surface_id_);
        OnSurfaceIdChanged(surface_id_);
        
        // 解绑纹理
        glBindTexture(GL_TEXTURE_EXTERNAL_OES, 0);
        
        // 渲染循环
        while (!is_destroyed_) {
            ret = egl_->Prepare();
            if (ret != MD_OK) {
                MD_LOGE("egl_->Prepare failed");
                break;
            }
            
            if (!is_paused_) {
                egl_->MakeCurrent(true);

                // 在渲染循环中检查是否需要更新surface尺寸
                if (surface_size_dirty_) {
                    UpdateSurfaceSizeInGLThread();
                }

                // 更新Surface
                int update_result = native_image_ref->UpdateSurface(st_matrix_);
                
                // 检查视频连接状态
                static int consecutive_success_count = 0;
                static int consecutive_fail_count = 0;
                
                if (update_result == MD_OK) {
                    consecutive_success_count++;
                    consecutive_fail_count = 0;
                    
                    if (consecutive_success_count >= 3) {
                        if (!video_connected_) {
                            MD_LOGI("MD360RendererPrivate: Video surface connected!");
                        }
                        video_connected_ = true;
                    }
                } else {
                    consecutive_fail_count++;
                    consecutive_success_count = 0;
                    
                    if (consecutive_fail_count >= 3) {
                        if (video_connected_) {
                            MD_LOGW("MD360RendererPrivate: Video surface disconnected");
                        }
                        video_connected_ = false;
                    }
                }
                
                // 每60帧记录一次状态
                static int frame_count = 0;
                frame_count++;
                if (frame_count % 60 == 0) {
                    MD_LOGI("MD360RendererPrivate: Frame %d, video_connected_=%s", 
                            frame_count, video_connected_ ? "true" : "false");
                }
                
                OnDrawFrame();
                egl_->SwapBuffer();
                egl_->MakeCurrent(false);
            }
            usleep(17 * 1000); // 约60fps
        }
        
        // 清理资源
        if (object3d_) {
            object3d_->Destroy();
            object3d_ = nullptr;
        }
        if (program_ != 0) {
            glDeleteProgram(program_);
            program_ = 0;
        }
        // 清理VR shader程序
        if (vr_program_ != 0) {
            glDeleteProgram(vr_program_);
            vr_program_ = 0;
        }
        // 清理纹理（必须在EGL context有效时删除）
        if (texture_id_ != 0) {
            glDeleteTextures(1, &texture_id_);
            texture_id_ = 0;
        }
        
        OnSurfaceIdChanged(0);
        egl_->Terminate();
        return MD_OK;
    }

private:
    bool is_init_ = false;
    bool is_destroyed_ = false;
    bool is_paused_ = false;
    uint64_t surface_id_ = 0;
    int surface_width_ = 0;
    int surface_height_ = 0; 
    GLuint texture_id_ = 0;
    std::thread thread_;
    std::shared_ptr<MDEgl> egl_ = MDEgl::CreateEgl();
    
    std::shared_ptr<MDObject3D> object3d_;
    GLuint program_ = 0;
    GLint u_mvp_matrix_loc_ = -1;
    GLint u_texture_loc_ = -1;
    GLint u_st_matrix_loc_ = -1;
    bool video_connected_ = false; // 标记视频源是否已连接
    // 初始化 ST 矩阵为单位矩阵
    float st_matrix_[16] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f
    };
    
    std::mutex mutex_;
    // 初始化 MVP 矩阵为单位矩阵
    // 注意：如果 MVP 矩阵是单位矩阵，球体可能不可见
    // 这里设置一个简单的投影矩阵，确保球体可见
    // 球体半径是 18.0，我们需要一个合适的投影矩阵
    float current_mvp_matrix_[16] = {
        1,0,0,0, 
        0,1,0,0, 
        0,0,1,0, 
        0,0,0,1
    };

    // VR模式相关成员变量
    VRModeConfig vr_config_;
    bool vr_shaders_initialized_ = false;
    bool pending_vr_cleanup_ = false;  // 标记是否需要清理VR资源
    GLuint vr_program_ = 0;
    GLuint vr_vertex_shader_ = 0;
    GLuint vr_fragment_shader_ = 0;
    GLint vr_mvp_matrix_loc_ = -1;
    GLint vr_st_matrix_loc_ = -1;
    GLint vr_texture_loc_ = -1;
    GLint vr_distortion_params_loc_ = -1;
    GLint vr_eye_offset_loc_ = -1;

    // 初始化投影矩阵（透视投影）
    // 使用 frustum 投影：left=-ratio/2, right=ratio/2, bottom=-0.5, top=0.5, near=0.7, far=500
    // 这应该与 MD360Director 的投影矩阵一致
    void InitDefaultProjectionMatrix() {
        // 同时初始化分离的投影矩阵
        InitProjectionMatrix();
        // 使用简单的透视投影矩阵
        // 参考 MD360Director.updateProjection() 的实现
        // 假设 viewport 宽高比为 16:9 (1920x1080)
        float aspect_ratio = 1920.0f / 1080.0f;  // 宽高比
        // 增大视野范围，确保能看到整个球体
        // 对于 360 度视频，需要更大的视野范围来看到整个球体
        // 使用更大的视野角度（FOV），相当于放大 top/bottom 和 left/right
        // 球体半径是 18，相机在球心，需要足够大的视野才能看到整个球体
        const float fov_scale = 2.5f;  // 视野缩放因子，增大视野范围（从 1.5 增加到 2.5）
        const float left = -aspect_ratio / 2.0f * fov_scale;  // -ratio/2 * scale
        const float right = aspect_ratio / 2.0f * fov_scale;  // ratio/2 * scale
        const float bottom = -0.5f * fov_scale;
        const float top = 0.5f * fov_scale;
        const float near = 0.7f;
        const float far = 500.0f;
        
        // 计算 frustum 投影矩阵
        const float rl = 1.0f / (right - left);
        const float tb = 1.0f / (top - bottom);
        const float fn = 1.0f / (far - near);
        
        current_mvp_matrix_[0] = 2.0f * near * rl;
        current_mvp_matrix_[1] = 0.0f;
        current_mvp_matrix_[2] = 0.0f;
        current_mvp_matrix_[3] = 0.0f;
        
        current_mvp_matrix_[4] = 0.0f;
        current_mvp_matrix_[5] = 2.0f * near * tb;
        current_mvp_matrix_[6] = 0.0f;
        current_mvp_matrix_[7] = 0.0f;
        
        current_mvp_matrix_[8] = (right + left) * rl;
        current_mvp_matrix_[9] = (top + bottom) * tb;
        current_mvp_matrix_[10] = -(far + near) * fn;
        current_mvp_matrix_[11] = -1.0f;
        
        current_mvp_matrix_[12] = 0.0f;
        current_mvp_matrix_[13] = 0.0f;
        current_mvp_matrix_[14] = -2.0f * far * near * fn;
        current_mvp_matrix_[15] = 0.0f;
        
        // 初始化时也设置使用触摸控制
        use_touch_control_ = true;
        mvp_matrix_dirty_ = true;
        MD_LOGI("MD360RendererPrivate: Initialized default projection matrix");
    }

    // 在GL线程中更新surface尺寸
    void UpdateSurfaceSizeInGLThread() {
        if (!surface_size_dirty_) {
            return;
        }
        
        if (egl_->IsEglValid()) {
            // 获取当前surface的宽度和高度
            EGLint width = 0;
            EGLint height = 0;
            
            // 使用eglQuerySurface获取surface尺寸
            if (egl_->QuerySurface(EGL_WIDTH, &width) && 
                egl_->QuerySurface(EGL_HEIGHT, &height)) {
                if (width > 0 && height > 0) {
                    surface_width_ = width;
                    surface_height_ = height;
                    MD_LOGI("UpdateSurfaceSizeInGLThread: actual surface size %dx%d", 
                           surface_width_, surface_height_);
                    
                    // 更新投影矩阵
                    UpdateProjectionMatrixForCurrentSurface();
                    
                    // 重置视口标志，确保使用新尺寸
                    viewport_set_ = false;
                    
                    // 清除脏标志
                    surface_size_dirty_ = false;
                    pending_window_ref_ = nullptr;
                    
                    return;
                }
            }
        }
        
        // 如果EGL查询失败，使用一个合理的默认值
        surface_width_ = 1920;
        surface_height_ = 1080;
        MD_LOGW("UpdateSurfaceSizeInGLThread: using default size %dx%d", 
               surface_width_, surface_height_);
        
        // 仍然清除脏标志，避免无限重试
        surface_size_dirty_ = false;
        pending_window_ref_ = nullptr;
    }

    // 初始化投影矩阵（分离的投影矩阵，用于触摸控制）
    void InitProjectionMatrix() {
        float aspect_ratio = 1920.0f / 1080.0f;  // 宽高比
        const float fov_scale = 2.5f;
        const float left = -aspect_ratio / 2.0f * fov_scale;
        const float right = aspect_ratio / 2.0f * fov_scale;
        const float bottom = -0.5f * fov_scale;
        const float top = 0.5f * fov_scale;
        const float near = 0.7f;
        const float far = 500.0f;
        
        const float rl = 1.0f / (right - left);
        const float tb = 1.0f / (top - bottom);
        const float fn = 1.0f / (far - near);
        
        projection_matrix_[0] = 2.0f * near * rl;
        projection_matrix_[1] = 0.0f;
        projection_matrix_[2] = 0.0f;
        projection_matrix_[3] = 0.0f;
        
        projection_matrix_[4] = 0.0f;
        projection_matrix_[5] = 2.0f * near * tb;
        projection_matrix_[6] = 0.0f;
        projection_matrix_[7] = 0.0f;
        
        projection_matrix_[8] = (right + left) * rl;
        projection_matrix_[9] = (top + bottom) * tb;
        projection_matrix_[10] = -(far + near) * fn;
        projection_matrix_[11] = -1.0f;
        
        projection_matrix_[12] = 0.0f;
        projection_matrix_[13] = 0.0f;
        projection_matrix_[14] = -2.0f * far * near * fn;
        projection_matrix_[15] = 0.0f;
    }
    
    // 根据触摸 delta 更新 MVP 矩阵
    void UpdateMVPMatrixFromTouch() {
        // 使用触摸delta计算旋转
        float rotation_x[16], rotation_y[16], combined_rotation[16];
        
        SetIdentityMatrix(rotation_x);
        SetIdentityMatrix(rotation_y);
        SetIdentityMatrix(combined_rotation);
        
        // 绕X轴旋转（上下）
        RotateMatrix(rotation_x, -touch_delta_y_, 1.0f, 0.0f, 0.0f);
        
        // 绕Y轴旋转（左右）
        RotateMatrix(rotation_y, -touch_delta_x_, 0.0f, 1.0f, 0.0f);
        
        // 组合旋转：先绕Y轴，再绕X轴
        MultiplyMatrix(combined_rotation, rotation_y, rotation_x);
        
        // 更新视图矩阵
        float camera_matrix[16] = {
            1.0f, 0.0f, 0.0f, 0.0f,
            0.0f, 1.0f, 0.0f, 0.0f,
            0.0f, 0.0f, 1.0f, 0.0f,
            0.0f, 0.0f, 0.0f, 1.0f
        };
        
        MultiplyMatrix(view_matrix_, camera_matrix, combined_rotation);
        
    }
    
    // 矩阵工具函数
    void SetIdentityMatrix(float* matrix) {
        for (int i = 0; i < 16; i++) {
            matrix[i] = (i % 5 == 0) ? 1.0f : 0.0f;  // 对角线为 1，其他为 0
        }
    }
    
    void RotateMatrix(float* matrix, float angle, float x, float y, float z) {
        // 绕轴旋转矩阵计算
        // angle 是角度（度），需要转换为弧度
        float radians = angle * M_PI / 180.0f;
        float c = cosf(radians);
        float s = sinf(radians);
        float t = 1.0f - c;
        
        // 归一化旋转轴
        float length = sqrtf(x*x + y*y + z*z);
        if (length > 0.0001f) {
            x /= length;
            y /= length;
            z /= length;
        }
        
        float temp[16];
        std::copy(matrix, matrix + 16, temp);
        
        // 绕任意轴旋转的旋转矩阵（Rodrigues 旋转公式）
        float rot[16] = {
            t*x*x + c,      t*x*y - s*z,    t*x*z + s*y,    0.0f,
            t*x*y + s*z,    t*y*y + c,      t*y*z - s*x,    0.0f,
            t*x*z - s*y,    t*y*z + s*x,    t*z*z + c,      0.0f,
            0.0f,           0.0f,           0.0f,           1.0f
        };
        
        MultiplyMatrix(matrix, temp, rot);
    }
    
    void MultiplyMatrix(float* result, const float* a, const float* b) {
        float temp[16];
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                temp[i * 4 + j] = 0.0f;
                for (int k = 0; k < 4; k++) {
                    temp[i * 4 + j] += a[i * 4 + k] * b[k * 4 + j];
                }
            }
        }
        std::copy(temp, temp + 16, result);
    }

    float clear_color_[4] = {0.0f, 0.0f, 0.0f, 1.0f}; // RGBA: 黑色（恢复正常）
    bool cull_face_enabled_ = false;  // 禁用面剔除（VR 中需要从球体内部看，需要看到"背面"）
    bool depth_test_enabled_ = true; // 默认启用深度测试

    // 触摸控制相关
    float touch_delta_x_ = 0.0f;
    float touch_delta_y_ = 0.0f;
    bool use_touch_control_ = false;  // 是否使用触摸控制（如果外部设置了 MVP 矩阵，则使用外部矩阵）
    bool mvp_matrix_dirty_ = false;   // MVP 矩阵是否需要更新
    
    // 投影矩阵和视图矩阵（分离存储，用于计算 MVP）
    float projection_matrix_[16] = {0};
    float view_matrix_[16] = {0};
    float model_matrix_[16] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f
    };
    
    // Viewport 相关
    int viewport_x_ = 0;
    int viewport_y_ = 0;
    int viewport_width_ = 0;
    int viewport_height_ = 0;
    bool viewport_set_ = false; // 是否设置了自定义 viewport
    
    // Scissor 相关
    int scissor_x_ = 0;
    int scissor_y_ = 0;
    int scissor_width_ = 0;
    int scissor_height_ = 0;
    bool scissor_enabled_ = false;
    
    // Blend 相关
    bool blend_enabled_ = false;
    int blend_src_ = GL_SRC_ALPHA; // 默认混合源因子
    int blend_dst_ = GL_ONE_MINUS_SRC_ALPHA; // 默认混合目标因子
    
    // 投影模式相关
    bool pending_projection_mode_change_ = false;
    int pending_projection_mode_ = 201; // 默认 SPHERE

    bool surface_size_dirty_ = false;
    std::shared_ptr<MDNativeWindowRef> pending_window_ref_ = nullptr;
    
    // 运动传感器相关
    float sensor_matrix_[16] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f
    };
    bool sensor_matrix_updated_ = false;
};

std::shared_ptr<MD360RendererAPI> MD360RendererAPI::CreateRenderer() {
    auto renderer = std::make_shared<MD360RendererPrivate>();
    return std::static_pointer_cast<MD360RendererAPI>(renderer);
} 


}
};