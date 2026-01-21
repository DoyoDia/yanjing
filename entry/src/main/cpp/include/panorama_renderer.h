/**
 * panorama_renderer.h - 全景渲染器头文件
 * 负责 OpenGL ES 3.0 渲染 360° 等距柱状投影全景
 */

#ifndef PANORAMA_RENDERER_H
#define PANORAMA_RENDERER_H

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <native_image/native_image.h>
#include <string>

namespace PanoramaVR {

/**
 * 全景渲染器类
 * 负责初始化 OpenGL 上下文、加载着色器、渲染全景球面
 */
class PanoramaRenderer {
public:
    PanoramaRenderer();
    ~PanoramaRenderer();

    /**
     * 初始化 EGL 和 OpenGL 上下文
     * @param window Native window 句柄
     * @return 是否初始化成功
     */
    bool Initialize(EGLNativeWindowType window);

    /**
     * 设置视口大小
     * @param width 视口宽度
     * @param height 视口高度
     */
    void SetViewport(int width, int height);

    /**
     * 设置视图矩阵（来自传感器的姿态数据）
     * @param viewMatrix 4x4 视图矩阵，列主序，16个浮点数
     */
    void SetViewMatrix(const float* viewMatrix);

    /**
     * 获取视频纹理的 Surface ID
     * @return Surface ID 字符串，用于视频播放器绑定
     */
    std::string GetSurfaceId();

    /**
     * 更新视频纹理（从绑定的 Surface 获取最新帧）
     */
    void UpdateVideoTexture();

    /**
     * 设置是否启用分屏模式（双眼立体视图）
     * @param enabled 是否启用
     */
    void SetStereoMode(bool enabled);

    /**
     * 设置瞳距（IPD），用于分屏模式
     * @param ipd 瞳距，单位：米，默认 0.064m
     */
    void SetIPD(float ipd);

    /**
     * 设置视场角（FOV）
     * @param fov 视场角，单位：度
     */
    void SetFOV(float fov);

    /**
     * 渲染一帧
     */
    void Render();

    /**
     * 释放资源
     */
    void Destroy();

    /**
     * 检查渲染器是否已初始化
     */
    bool IsInitialized() const { return m_initialized; }

private:
    /**
     * 初始化 EGL
     */
    bool InitEGL(EGLNativeWindowType window);

    /**
     * 初始化 OpenGL 资源
     */
    bool InitGL();

    /**
     * 编译着色器
     */
    GLuint CompileShader(GLenum type, const char* source);

    /**
     * 链接着色器程序
     */
    GLuint LinkProgram(GLuint vertexShader, GLuint fragmentShader);

    /**
     * 创建投影矩阵
     */
    void CreateProjectionMatrix(float fov, float aspect, float near, float far, float* matrix);

    /**
     * 渲染单眼视图
     * @param eyeOffset 眼睛偏移量（左眼负值，右眼正值）
     * @param viewportX 视口 X 起点
     * @param viewportWidth 视口宽度
     */
    void RenderEye(float eyeOffset, int viewportX, int viewportWidth);

private:
    // EGL 相关
    EGLDisplay m_eglDisplay = EGL_NO_DISPLAY;
    EGLSurface m_eglSurface = EGL_NO_SURFACE;
    EGLContext m_eglContext = EGL_NO_CONTEXT;
    EGLConfig m_eglConfig = nullptr;

    // OpenGL 资源
    GLuint m_program = 0;
    GLuint m_vao = 0;
    GLuint m_vbo = 0;
    GLuint m_ibo = 0;
    GLuint m_texture = 0;

    // Uniform 位置
    GLint m_projMatrixLoc = -1;
    GLint m_viewMatrixLoc = -1;
    GLint m_modelMatrixLoc = -1;
    GLint m_textureLoc = -1;

    // 球体网格数据
    int m_sphereVertexCount = 0;
    int m_sphereIndexCount = 0;

    // 视口尺寸
    int m_viewportWidth = 0;
    int m_viewportHeight = 0;

    // 视图矩阵（来自传感器）
    float m_viewMatrix[16];

    // 投影矩阵
    float m_projMatrix[16];

    // 模型矩阵（单位矩阵）
    float m_modelMatrix[16];

    // 渲染设置
    bool m_stereoMode = true;     // 是否启用分屏模式
    float m_ipd = 0.064f;         // 瞳距（米）
    float m_fov = 90.0f;          // 视场角（度）

    // 状态标志
    bool m_initialized = false;
    bool m_textureLoaded = false;
    
    // NativeImage 相关
    OH_NativeImage* m_nativeImage = nullptr;
    std::string m_surfaceId;
};

} // namespace PanoramaVR

#endif // PANORAMA_RENDERER_H
