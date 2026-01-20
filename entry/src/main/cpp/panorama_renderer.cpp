/**
 * panorama_renderer.cpp - 全景渲染器实现
 */

#include "include/panorama_renderer.h"
#include "include/sphere_mesh.h"
#include <hilog/log.h>
#include <cstring>
#include <cmath>
#include <vector>

#undef LOG_TAG
#define LOG_TAG "PanoramaRenderer"
#define LOGD(...) OH_LOG_DEBUG(LOG_APP, __VA_ARGS__)
#define LOGI(...) OH_LOG_INFO(LOG_APP, __VA_ARGS__)
#define LOGE(...) OH_LOG_ERROR(LOG_APP, __VA_ARGS__)

// OES 纹理目标定义
#ifndef GL_TEXTURE_EXTERNAL_OES
#define GL_TEXTURE_EXTERNAL_OES 0x8D65
#endif

namespace PanoramaVR {

// 顶点着色器
static const char* VERTEX_SHADER = R"(#version 300 es
precision highp float;

layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec2 aTexCoord;

uniform mat4 uProjection;
uniform mat4 uView;
uniform mat4 uModel;

out vec2 vTexCoord;

void main() {
    // 移除视图矩阵中的位移部分，只保留旋转
    mat4 viewRotation = uView;
    viewRotation[3] = vec4(0.0, 0.0, 0.0, 1.0);
    
    gl_Position = uProjection * viewRotation * uModel * vec4(aPosition, 1.0);
    vTexCoord = aTexCoord;
}
)";

// 片段着色器 (适配 OES 外部纹理)
static const char* FRAGMENT_SHADER = R"(#version 300 es
#extension GL_OES_EGL_image_external_essl3 : require
precision mediump float;

in vec2 vTexCoord;
uniform samplerExternalOES uTexture;

out vec4 fragColor;

void main() {
    // 翻转 Y 坐标 (视频通常是倒置的或坐标系差异)
    // vec2 texCoord = vec2(vTexCoord.x, 1.0 - vTexCoord.y);
    // 这里暂时不做翻转，视情况而定
    fragColor = texture(uTexture, vTexCoord);
}
)";

PanoramaRenderer::PanoramaRenderer() {
    // 初始化矩阵为单位矩阵
    std::memset(m_viewMatrix, 0, sizeof(m_viewMatrix));
    std::memset(m_projMatrix, 0, sizeof(m_projMatrix));
    std::memset(m_modelMatrix, 0, sizeof(m_modelMatrix));
    
    m_viewMatrix[0] = m_viewMatrix[5] = m_viewMatrix[10] = m_viewMatrix[15] = 1.0f;
    m_projMatrix[0] = m_projMatrix[5] = m_projMatrix[10] = m_projMatrix[15] = 1.0f;
    m_modelMatrix[0] = m_modelMatrix[5] = m_modelMatrix[10] = m_modelMatrix[15] = 1.0f;
}

PanoramaRenderer::~PanoramaRenderer() {
    Destroy();
}

bool PanoramaRenderer::Initialize(EGLNativeWindowType window) {
    LOGI("Initializing PanoramaRenderer...");
    
    if (!InitEGL(window)) {
        LOGE("Failed to initialize EGL");
        return false;
    }
    
    if (!InitGL()) {
        LOGE("Failed to initialize OpenGL");
        return false;
    }
    
    m_initialized = true;
    LOGI("PanoramaRenderer initialized successfully");
    return true;
}

bool PanoramaRenderer::InitEGL(EGLNativeWindowType window) {
    // 获取 EGL 显示连接
    m_eglDisplay = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (m_eglDisplay == EGL_NO_DISPLAY) {
        LOGE("eglGetDisplay failed");
        return false;
    }
    
    // 初始化 EGL
    EGLint majorVersion, minorVersion;
    if (!eglInitialize(m_eglDisplay, &majorVersion, &minorVersion)) {
        LOGE("eglInitialize failed");
        return false;
    }
    LOGI("EGL version: %d.%d", majorVersion, minorVersion);
    
    // 选择 EGL 配置
    EGLint configAttribs[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_DEPTH_SIZE, 24,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
        EGL_NONE
    };
    
    EGLint numConfigs;
    if (!eglChooseConfig(m_eglDisplay, configAttribs, &m_eglConfig, 1, &numConfigs)) {
        LOGE("eglChooseConfig failed");
        return false;
    }
    
    // 创建 EGL 上下文
    EGLint contextAttribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 3,
        EGL_NONE
    };
    
    m_eglContext = eglCreateContext(m_eglDisplay, m_eglConfig, EGL_NO_CONTEXT, contextAttribs);
    if (m_eglContext == EGL_NO_CONTEXT) {
        LOGE("eglCreateContext failed");
        return false;
    }
    
    // 创建 EGL 表面
    m_eglSurface = eglCreateWindowSurface(m_eglDisplay, m_eglConfig, window, nullptr);
    if (m_eglSurface == EGL_NO_SURFACE) {
        LOGE("eglCreateWindowSurface failed");
        return false;
    }
    
    // 绑定上下文
    if (!eglMakeCurrent(m_eglDisplay, m_eglSurface, m_eglSurface, m_eglContext)) {
        LOGE("eglMakeCurrent failed");
        return false;
    }
    
    return true;
}

bool PanoramaRenderer::InitGL() {
    LOGI("OpenGL ES version: %s", glGetString(GL_VERSION));
    LOGI("OpenGL ES renderer: %s", glGetString(GL_RENDERER));
    
    // 编译着色器
    GLuint vertexShader = CompileShader(GL_VERTEX_SHADER, VERTEX_SHADER);
    if (vertexShader == 0) {
        LOGE("Failed to compile vertex shader");
        return false;
    }
    
    GLuint fragmentShader = CompileShader(GL_FRAGMENT_SHADER, FRAGMENT_SHADER);
    if (fragmentShader == 0) {
        glDeleteShader(vertexShader);
        LOGE("Failed to compile fragment shader");
        return false;
    }
    
    // 链接着色器程序
    m_program = LinkProgram(vertexShader, fragmentShader);
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    if (m_program == 0) {
        LOGE("Failed to link shader program");
        return false;
    }
    
    // 获取 uniform 位置
    m_projMatrixLoc = glGetUniformLocation(m_program, "uProjection");
    m_viewMatrixLoc = glGetUniformLocation(m_program, "uView");
    m_modelMatrixLoc = glGetUniformLocation(m_program, "uModel");
    m_textureLoc = glGetUniformLocation(m_program, "uTexture");
    
    // 生成球体网格
    std::vector<SphereVertex> vertices;
    std::vector<unsigned short> indices;
    SphereMesh::Generate(40, 80, 50.0f, true, vertices, indices);
    
    m_sphereVertexCount = static_cast<int>(vertices.size());
    m_sphereIndexCount = static_cast<int>(indices.size());
    
    LOGI("Sphere mesh: %d vertices, %d indices", m_sphereVertexCount, m_sphereIndexCount);
    
    // 创建 VAO
    glGenVertexArrays(1, &m_vao);
    glBindVertexArray(m_vao);
    
    // 创建 VBO
    glGenBuffers(1, &m_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(SphereVertex), vertices.data(), GL_STATIC_DRAW);
    
    // 创建 IBO
    glGenBuffers(1, &m_ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.size() * sizeof(unsigned short), indices.data(), GL_STATIC_DRAW);
    
    // 设置顶点属性
    // 位置
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(SphereVertex), (void*)offsetof(SphereVertex, x));
    glEnableVertexAttribArray(0);
    
    // 纹理坐标
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(SphereVertex), (void*)offsetof(SphereVertex, u));
    glEnableVertexAttribArray(1);
    
    glBindVertexArray(0);
    
    // 创建 OES 纹理
    glGenTextures(1, &m_texture);
    glBindTexture(GL_TEXTURE_EXTERNAL_OES, m_texture);
    glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 启用深度测试
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    
    // 禁用背面剔除（因为我们从球体内部观看）
    glDisable(GL_CULL_FACE);
    
    return true;
}

std::string PanoramaRenderer::GetSurfaceId() {
    if (m_texture == 0) {
        LOGE("Texture not created yet");
        return "";
    }
    
    // 如果已经创建过，直接返回
    if (m_nativeImage != nullptr) {
        return m_surfaceId;
    }
    
    // 创建 NativeImage 并绑定到 OES 纹理
    m_nativeImage = OH_NativeImage_Create(m_texture, GL_TEXTURE_EXTERNAL_OES);
    if (m_nativeImage == nullptr) {
        LOGE("Failed to create NativeImage");
        return "";
    }
    
    // 获取 SurfaceId
    uint64_t surfaceId = 0;
    if (OH_NativeImage_GetSurfaceId(m_nativeImage, &surfaceId) != 0) {
        LOGE("Failed to get SurfaceId");
        return "";
    }
    
    m_surfaceId = std::to_string(surfaceId);
    LOGI("NativeImage created, SurfaceId: %s", m_surfaceId.c_str());
    
    return m_surfaceId;
}

void PanoramaRenderer::UpdateVideoTexture() {
    if (m_nativeImage == nullptr) return;
    
    // 更新纹理图像
    int32_t ret = OH_NativeImage_UpdateSurfaceImage(m_nativeImage);
    if (ret != 0) {
        // 这一步可能会在没有新帧时失败，通常可以忽略
        // LOGE("Failed to update surface image: %d", ret);
    } else {
        // 如果需要获取转换矩阵，可以使用 OH_NativeImage_GetTransformMatrix
    }
}

GLuint PanoramaRenderer::CompileShader(GLenum type, const char* source) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);
    
    GLint compiled;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 1) {
            std::vector<char> infoLog(infoLen);
            glGetShaderInfoLog(shader, infoLen, nullptr, infoLog.data());
            LOGE("Shader compile error: %s", infoLog.data());
        }
        glDeleteShader(shader);
        return 0;
    }
    
    return shader;
}

GLuint PanoramaRenderer::LinkProgram(GLuint vertexShader, GLuint fragmentShader) {
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    GLint linked;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (!linked) {
        GLint infoLen = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 1) {
            std::vector<char> infoLog(infoLen);
            glGetProgramInfoLog(program, infoLen, nullptr, infoLog.data());
            LOGE("Program link error: %s", infoLog.data());
        }
        glDeleteProgram(program);
        return 0;
    }
    
    return program;
}

void PanoramaRenderer::SetViewport(int width, int height) {
    m_viewportWidth = width;
    m_viewportHeight = height;
    
    // 根据分屏模式计算投影矩阵
    float aspectRatio;
    if (m_stereoMode) {
        // 分屏模式：每只眼睛使用一半的宽度
        aspectRatio = (static_cast<float>(width) / 2.0f) / static_cast<float>(height);
    } else {
        aspectRatio = static_cast<float>(width) / static_cast<float>(height);
    }
    
    CreateProjectionMatrix(m_fov, aspectRatio, 0.1f, 1000.0f, m_projMatrix);
    
    LOGI("Viewport set: %dx%d, aspect: %.2f", width, height, aspectRatio);
}

void PanoramaRenderer::CreateProjectionMatrix(float fov, float aspect, float near, float far, float* matrix) {
    float fovRad = fov * M_PI / 180.0f;
    float tanHalfFov = std::tan(fovRad / 2.0f);
    
    std::memset(matrix, 0, 16 * sizeof(float));
    
    matrix[0] = 1.0f / (aspect * tanHalfFov);
    matrix[5] = 1.0f / tanHalfFov;
    matrix[10] = -(far + near) / (far - near);
    matrix[11] = -1.0f;
    matrix[14] = -(2.0f * far * near) / (far - near);
}

void PanoramaRenderer::SetViewMatrix(const float* viewMatrix) {
    std::memcpy(m_viewMatrix, viewMatrix, 16 * sizeof(float));
}

void PanoramaRenderer::SetStereoMode(bool enabled) {
    m_stereoMode = enabled;
    
    // 重新计算投影矩阵
    if (m_viewportWidth > 0 && m_viewportHeight > 0) {
        SetViewport(m_viewportWidth, m_viewportHeight);
    }
}

void PanoramaRenderer::SetIPD(float ipd) {
    m_ipd = ipd;
}

void PanoramaRenderer::Render() {
    if (!m_initialized) return;
    
    // 更新视频纹理
    UpdateVideoTexture();
    
    // 清除缓冲区
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    if (m_stereoMode) {
        // 分屏模式：左右眼分别渲染
        int halfWidth = m_viewportWidth / 2;
        
        // 左眼
        RenderEye(-m_ipd / 2.0f, 0, halfWidth);
        
        // 右眼
        RenderEye(m_ipd / 2.0f, halfWidth, halfWidth);
    } else {
        // 单眼模式
        glViewport(0, 0, m_viewportWidth, m_viewportHeight);
        RenderEye(0.0f, 0, m_viewportWidth);
    }
    
    // 交换缓冲区
    eglSwapBuffers(m_eglDisplay, m_eglSurface);
}

void PanoramaRenderer::RenderEye(float eyeOffset, int viewportX, int viewportWidth) {
    // 设置视口
    glViewport(viewportX, 0, viewportWidth, m_viewportHeight);
    
    // 使用着色器程序
    glUseProgram(m_program);
    
    // 设置 uniform
    glUniformMatrix4fv(m_projMatrixLoc, 1, GL_FALSE, m_projMatrix);
    glUniformMatrix4fv(m_viewMatrixLoc, 1, GL_FALSE, m_viewMatrix);
    glUniformMatrix4fv(m_modelMatrixLoc, 1, GL_FALSE, m_modelMatrix);
    
    // 绑定 OES 纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_EXTERNAL_OES, m_texture);
    glUniform1i(m_textureLoc, 0);
    
    // 绘制球体
    glBindVertexArray(m_vao);
    glDrawElements(GL_TRIANGLES, m_sphereIndexCount, GL_UNSIGNED_SHORT, nullptr);
    glBindVertexArray(0);
}

void PanoramaRenderer::Destroy() {
    if (!m_initialized) return;
    
    LOGI("Destroying PanoramaRenderer...");
    
    // 销毁 NativeImage
    if (m_nativeImage != nullptr) {
        OH_NativeImage_Destroy(&m_nativeImage);
        m_nativeImage = nullptr;
    }
    
    // 删除 OpenGL 资源
    if (m_texture != 0) {
        glDeleteTextures(1, &m_texture);
        m_texture = 0;
    }
    
    if (m_vao != 0) {
        glDeleteVertexArrays(1, &m_vao);
        m_vao = 0;
    }
    
    if (m_vbo != 0) {
        glDeleteBuffers(1, &m_vbo);
        m_vbo = 0;
    }
    
    if (m_ibo != 0) {
        glDeleteBuffers(1, &m_ibo);
        m_ibo = 0;
    }
    
    if (m_program != 0) {
        glDeleteProgram(m_program);
        m_program = 0;
    }
    
    // 销毁 EGL
    if (m_eglDisplay != EGL_NO_DISPLAY) {
        eglMakeCurrent(m_eglDisplay, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        
        if (m_eglSurface != EGL_NO_SURFACE) {
            eglDestroySurface(m_eglDisplay, m_eglSurface);
            m_eglSurface = EGL_NO_SURFACE;
        }
        
        if (m_eglContext != EGL_NO_CONTEXT) {
            eglDestroyContext(m_eglDisplay, m_eglContext);
            m_eglContext = EGL_NO_CONTEXT;
        }
        
        eglTerminate(m_eglDisplay);
        m_eglDisplay = EGL_NO_DISPLAY;
    }
    
    m_initialized = false;
    LOGI("PanoramaRenderer destroyed");
}

} // namespace PanoramaVR
