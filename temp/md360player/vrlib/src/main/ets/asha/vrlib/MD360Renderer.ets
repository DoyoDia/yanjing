/**
 * Created by hzqiujiadi on 16/1/22.
 * hzqiujiadi ashqalcn@gmail.com
 *
 * @see Builder
 * @see #with(Context)
 */

import { Fps } from './common/Fps';
import { MDGLHandler } from './common/MDGLHandler';
import { GLUtil } from './common/GLUtil';
import { MDAbsLinePipe } from './plugins/MDAbsLinePipe';
import { MDAbsPlugin } from './plugins/MDAbsPlugin';
import { MDBarrelDistortionLinePipe } from './plugins/MDBarrelDistortionLinePipe';
import { MDPluginManager } from './plugins/MDPluginManager';
import { DisplayModeManager } from './strategy/display/DisplayModeManager';
import { ProjectionModeManager } from './strategy/projection/ProjectionModeManager';
import { MD360Director } from './MD360Director';
import { MD360Player } from 'libmd360player.so';
import { Context } from '../../google/android/apps/muzei/render/ViewTypes';
import { display } from '@kit.ArkUI';
// import { MD360Program } from './model/MDTypes';

// TODO: 当相关类型迁移后，取消注释并删除类型占位符
import { MD360Program } from './MD360Program';
import { ContentType } from './MDVRLibrary';
// import { MDPosition } from './model/MDPosition';

// type Context = any;
type GL10 = Object;
type EGLConfig = Object;
// type MD360Program = any;
// type MDPosition = any;

/**
 * 360度渲染器类
 */
export class MD360Renderer {
  private static readonly TAG: string = "MD360Renderer";
  private mDisplayModeManager: DisplayModeManager | null = null;
  private mProjectionModeManager: ProjectionModeManager | null = null;
  private mPluginManager: MDPluginManager | null = null;
  private mMainLinePipe: MDAbsLinePipe | null = null;
  private mGLHandler: MDGLHandler | null = null;
  private mFps: Fps = new Fps();
  private mWidth: number = 0;
  private mHeight: number = 0;
  private readonly mContext: Context;
  private mNapi: MD360Player | null = null;
  private mSurfaceReady: boolean = false;
  private lastVisibleSize: number = 1; // 用于检测visibleSize变化

  public constructor(params: Builder) {
    this.mContext = params.context;
    this.mDisplayModeManager = params.displayModeManager;
    this.mProjectionModeManager = params.projectionModeManager;
    this.mPluginManager = params.pluginManager;
    this.mGLHandler = params.glHandler;

    this.mMainLinePipe = new MDBarrelDistortionLinePipe(this.mDisplayModeManager!);
  }

  /**
   * 表面创建时调用
   */
  onSurfaceCreated(glUnused: GL10, config: EGLConfig): void {
    // 设置背景清除颜色为黑色（RGBA: 0.0, 0.0, 0.0, 1.0）
    // 在 HarmonyOS 中，通过 NAPI 调用 C++ 侧的 glClearColor
    if (this.mNapi) {
      // 参数：r, g, b, a (范围 0.0 - 1.0)
      // 默认黑色：0.0, 0.0, 0.0, 1.0
      // 如果需要透明背景，可以设置为：0.0, 0.0, 0.0, 0.0
      this.mNapi.setClearColor(0.0, 0.0, 0.0, 1.0);
      
      // 启用面剔除（移除背面，提高渲染性能）
      // GL_CULL_FACE: 使用剔除来移除背面
      this.mNapi.setCullFaceEnabled(true);
      
      // 启用深度测试（确保正确的深度排序）
      // GL_DEPTH_TEST: 启用深度测试
      this.mNapi.setDepthTestEnabled(true);
    }
  }

  /**
   * 表面改变时调用
   */
  onSurfaceChanged(glUnused: GL10, width: number, height: number): void {
    this.mWidth = width;
    this.mHeight = height;
    // 表面尺寸有效时，认为 Surface 已准备好
    if (width > 0 && height > 0) {
      this.mSurfaceReady = true;
    }

    this.mGLHandler?.dealMessage();
  }

  /**
   * 绘制帧时调用
   */
  onDrawFrame(glUnused: GL10): void {
    // GL线程
    // 切换策略
    // 热点拾取
    this.mGLHandler?.dealMessage();

    // 关键修复：确保 mWidth/mHeight 有有效值
    // 如果 onSurfaceChanged 没被调用，使用实际屏幕尺寸
    if (this.mWidth === 0 || this.mHeight === 0) {
      try {
        // 从 display 模块获取实际屏幕尺寸
        const defaultDisplay = display.getDefaultDisplaySync();
        if (defaultDisplay) {
          this.mWidth = defaultDisplay.width;
          this.mHeight = defaultDisplay.height;
          console.log('MD360Renderer: Auto-initialized from display:', this.mWidth, 'x', this.mHeight);
        } else {
          // Fallback: 使用标准手机屏幕尺寸
          this.mWidth = 1080;
          this.mHeight = 2340;
          console.warn('MD360Renderer: Using fallback size:', this.mWidth, 'x', this.mHeight);
        }
      } catch (e) {
        // Fallback: 使用标准手机屏幕尺寸
        this.mWidth = 1080;
        this.mHeight = 2340;
        console.warn('MD360Renderer: Failed to get display, using fallback size:', e);
      }
    }

    // 从 Native 获取陀螺仪矩阵并同步给所有 director
    this.updateSensorMatrixFromNative();

    // GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT | GLES20.GL_DEPTH_BUFFER_BIT);
    // GLUtil.glCheck("MD360Renderer onDrawFrame begin. ");
    // 在鸿蒙中，需要使用对应的OpenGL API

    const size = this.mDisplayModeManager?.getVisibleSize() || 1;
    
    // 添加调试日志（仅在size变化时输出）
    if (this.lastVisibleSize !== size) {
      console.log('MD360Renderer.onDrawFrame: visibleSize changed from', this.lastVisibleSize, 'to', size);
      this.lastVisibleSize = size;
    }

    const width = Math.floor(this.mWidth * 1.0 / size);
    const height = this.mHeight;

    // take over
    this.mMainLinePipe?.setup(this.mContext);
    // 将 napi 传递给 LinePipe，以便 LinePipe 可以使用 OpenGL 方法
    if (this.mNapi && this.mMainLinePipe) {
      this.mMainLinePipe.setNapi(this.mNapi);
    }
    this.mMainLinePipe?.takeOver(this.mWidth, this.mHeight, size);

    const directors = this.mProjectionModeManager?.getDirectors() || [];

    // main plugin
    const mainPlugin = this.mProjectionModeManager?.getMainPlugin();
    if (mainPlugin != null) {
      mainPlugin.setupInGL(this.mContext);
      mainPlugin.beforeRenderer(this.mWidth, this.mHeight);
    }

    const plugins = this.mPluginManager?.getPlugins() || [];
    for (const plugin of plugins) {
      plugin.setupInGL(this.mContext);
      plugin.beforeRenderer(this.mWidth, this.mHeight);
      // 将 napi 传递给插件，以便插件可以使用 OpenGL 方法
      if (this.mNapi) {
        plugin.setNapi(this.mNapi);
      }
    }

    for (let i = 0; i < size; i++) {
      if (i >= directors.length) break;

      const director = directors[i];
      
      // 设置视口和裁剪区域（用于多屏/分屏渲染）
      // 注意：当前 C++ 侧实现只支持单个渲染器，所以这里只为第一个屏幕设置
      // 如果未来需要支持真正的多屏渲染，需要在 C++ 侧实现多渲染器支持
      if (this.mNapi && this.mWidth > 0 && this.mHeight > 0) {
        if (size > 1) {
          // 多屏模式：为每个屏幕设置独立的视口和裁剪区域
          const viewportX = width * i;
          const viewportY = 0;
          this.mNapi.setViewport(viewportX, viewportY, width, height);
          this.mNapi.setScissor(viewportX, viewportY, width, height);
          this.mNapi.setScissorEnabled(true);
        } else {
          // 单屏模式：使用全屏视口，禁用裁剪
          this.mNapi.setViewport(0, 0, this.mWidth, this.mHeight);
          this.mNapi.setScissorEnabled(false);
        }
      }

      if (mainPlugin != null) {
        mainPlugin.renderer(i, width, height, director);
      }

      for (const plugin of plugins) {
        plugin.renderer(i, width, height, director);
      }

      // Send MVP Matrix to Native
      // 仅在 Surface 准备好且矩阵有效时才更新
      // 注意：必须在 director.shot() 之后获取 MVP 矩阵，因为 shot() 会计算 MVP 矩阵
      // mainPlugin.renderer() 应该已经调用了 director.beforeShot() 和 director.shot()
      // 注意：在Glass模式下，需要为每个视口（左右眼）更新MVP矩阵
      // 当前C++侧实现可能只支持单个渲染器，所以暂时只更新第一个director
      // 如果未来C++侧支持多渲染器，应该为每个director更新MVP矩阵
      
      // 完全模拟触摸手势的 MVP 更新逻辑
      if (this.mNapi && (i === 0 || size === 1)) {
        const mvpMatrix = director.getMVPMatrix();
        
        // 简化验证：只检查基本条件，直接更新（跟触摸手势一样）
        if (mvpMatrix != null && mvpMatrix.length >= 16) {
          this.mNapi.updateMVPMatrix(mvpMatrix);
        }
      }
    }

    this.mMainLinePipe?.commit(this.mWidth, this.mHeight, size);
    // GLUtil.glCheck("MD360Renderer onDrawFrame end. ");
    // this.mFps.step();
  }

  /**
   * 拉取 native 侧的传感器矩阵并更新到所有 directors
   * 在 GL 线程每帧调用一次
   */
  private updateSensorMatrixFromNative(): void {
    if (!this.mNapi || !this.mProjectionModeManager) {
      return;
    }
    try {
      const matrix = this.mNapi.getSensorMatrix();
      if (Array.isArray(matrix) && matrix.length >= 16) {
        const directors = this.mProjectionModeManager.getDirectors() || [];
        for (const director of directors) {
          director.updateSensorMatrix(matrix);
        }
      }
    } catch (error) {
      console.warn('MD360Renderer: Failed to update sensor matrix from native', error);
    }
  }

  setNapi(napi: MD360Player | null): void {
    this.mNapi = napi;
  }

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   */
  destroy(): void {
    this.mNapi = null;
    this.mDisplayModeManager = null;
    this.mProjectionModeManager = null;
    this.mPluginManager = null;
    this.mMainLinePipe = null;
    this.mGLHandler = null;
    this.mSurfaceReady = false;
  }

  /**
   * 验证矩阵是否有效（无 NaN、无 Infinity，且长度正确）
   * 注：已废弃，改为简化的直接更新策略
   */
  private static isMatrixValid(matrix: number[]): boolean {
    if (matrix == null || matrix.length < 16) {
      return false;
    }
    for (let i = 0; i < 16; i++) {
      const val = matrix[i];
      if (!Number.isFinite(val)) {
        return false;
      }
    }
    return true;
  }

  static with(context: Context): Builder {
    const builder = new Builder();
    builder.context = context;
    return builder;
  }
}

/**
 * 构建器类
 */
export class Builder {
  context: Context = new Context();
  displayModeManager: DisplayModeManager | null = null;
  projectionModeManager: ProjectionModeManager | null = null;
  glHandler: MDGLHandler | null = null;
  pluginManager: MDPluginManager | null = null;

  public constructor() {
  }

  build(): MD360Renderer {
    return new MD360Renderer(this);
  }

  setGLHandler(glHandler: MDGLHandler): Builder {
    this.glHandler = glHandler;
    return this;
  }

  setPluginManager(pluginManager: MDPluginManager): Builder {
    this.pluginManager = pluginManager;
    return this;
  }

  setDisplayModeManager(displayModeManager: DisplayModeManager): Builder {
    this.displayModeManager = displayModeManager;
    return this;
  }

  setProjectionModeManager(projectionModeManager: ProjectionModeManager): Builder {
    this.projectionModeManager = projectionModeManager;
    return this;
  }
}

