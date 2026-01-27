/**
 * GLTextureView类
 * 提供类似GLSurfaceView的功能，但使用TextureView作为底层
 * 
 * 注意：此类依赖Android的TextureView、SurfaceTexture、EGL等API
 * 在HarmonyOS中需要使用XComponent + EGL/NAPI替代
 * 
 * 参考：http://stackoverflow.com/questions/12061419/converting-from-glsurfaceview-to-textureview-via-gltextureview
 */

// 导入内部类
import { DefaultContextFactory } from './DefaultContextFactory';
import { DefaultWindowSurfaceFactory } from './DefaultWindowSurfaceFactory';
import { SimpleEGLConfigChooser, ComponentSizeChooser } from './EGLConfigChooser';
import { GLThread } from './GLThread';
import { Context, AttributeSet, TextureView, SurfaceTexture, SurfaceHolder } from './ViewTypes';
import { EGL10, EGL11, EGLConfig, EGLContext, EGLDisplay, EGLSurface, GL, GL10, GLDebugHelper } from './EGLTypes';

/**
 * GLSurfaceView.Renderer接口
 */
export interface Renderer {
  onSurfaceCreated(gl: GL10, config: EGLConfig): void;
  onSurfaceChanged(gl: GL10, width: number, height: number): void;
  onDrawFrame(gl: GL10): void;
}

/**
 * GLWrapper接口
 */
export interface GLWrapper {
  wrap(gl: GL): GL;
}

/**
 * EGLContextFactory接口
 */
export interface EGLContextFactory {
  createContext(egl: EGL10, display: EGLDisplay, eglConfig: EGLConfig): EGLContext;
  destroyContext(egl: EGL10, display: EGLDisplay, context: EGLContext): void;
}

/**
 * EGLWindowSurfaceFactory接口
 */
export interface EGLWindowSurfaceFactory {
  createWindowSurface(egl: EGL10, display: EGLDisplay, config: EGLConfig, nativeWindow: ESObject): EGLSurface | null;
  destroySurface(egl: EGL10, display: EGLDisplay, surface: EGLSurface): void;
}

/**
 * EGLConfigChooser接口
 */
export interface EGLConfigChooser {
  chooseConfig(egl: EGL10, display: EGLDisplay): EGLConfig;
}

/**
 * GLTextureView类
 * 注意：在HarmonyOS中，此类需要适配为XComponent + EGL/NAPI的实现
 */
export class GLTextureView {
  private static readonly TAG: string = 'GLTextureView';
  private static readonly LOG_ATTACH_DETACH: boolean = false;
  private static readonly LOG_THREADS: boolean = false;
  private static readonly LOG_PAUSE_RESUME: boolean = false;
  private static readonly LOG_SURFACE: boolean = false;
  private static readonly LOG_RENDERER: boolean = false;
  private static readonly LOG_RENDERER_DRAW_FRAME: boolean = false;
  private static readonly LOG_EGL: boolean = false;

  /**
   * 渲染模式：仅在需要时渲染
   */
  public static readonly RENDERMODE_WHEN_DIRTY: number = 0;

  /**
   * 渲染模式：连续渲染
   */
  public static readonly RENDERMODE_CONTINUOUSLY: number = 1;

  /**
   * 调试标志：检查GL错误
   */
  public static readonly DEBUG_CHECK_GL_ERROR: number = 1;

  /**
   * 调试标志：记录GL调用
   */
  public static readonly DEBUG_LOG_GL_CALLS: number = 2;

  private mGLThread: GLThread | null = null;
  mRenderer: Renderer | null = null;
  private mDetached: boolean = false;
  mEGLConfigChooser: EGLConfigChooser | null = null;
  mEGLContextFactory: EGLContextFactory | null = null;
  mEGLWindowSurfaceFactory: EGLWindowSurfaceFactory | null = null;
  mGLWrapper: GLWrapper | null = null;
  mDebugFlags: number = 0;
  mEGLContextClientVersion: number = 0;
  mPreserveEGLContextOnPause: boolean = false;
  private readonly mThisWeakRef: WeakRef<GLTextureView>;

  // TODO: 在HarmonyOS中，需要使用XComponent替代TextureView
  private textureView: TextureView | null = null;

  constructor(context: Context, attrs?: AttributeSet) {
    // TODO: 在HarmonyOS中，需要初始化XComponent
    // super(context, attrs);
    this.mThisWeakRef = new WeakRef(this);
    this.init();
  }

  private init(): void {
    // TODO: 在HarmonyOS中，需要设置XComponent的回调
    // setSurfaceTextureListener(this);
  }

  /**
   * 设置GL包装器
   */
  setGLWrapper(glWrapper: GLWrapper): void {
    this.mGLWrapper = glWrapper;
  }

  /**
   * 设置调试标志
   */
  setDebugFlags(debugFlags: number): void {
    this.mDebugFlags = debugFlags;
  }

  /**
   * 获取调试标志
   */
  getDebugFlags(): number {
    return this.mDebugFlags;
  }

  /**
   * 设置是否在暂停时保留EGL上下文
   */
  setPreserveEGLContextOnPause(preserveOnPause: boolean): void {
    this.mPreserveEGLContextOnPause = preserveOnPause;
  }

  /**
   * 获取是否在暂停时保留EGL上下文
   */
  getPreserveEGLContextOnPause(): boolean {
    return this.mPreserveEGLContextOnPause;
  }

  /**
   * 设置渲染器
   */
  setRenderer(renderer: Renderer): void {
    this.checkRenderThreadState();
    if (this.mEGLConfigChooser == null) {
      this.mEGLConfigChooser = new SimpleEGLConfigChooser(this, true);
    }
    if (this.mEGLContextFactory == null) {
      this.mEGLContextFactory = new DefaultContextFactory(this);
    }
    if (this.mEGLWindowSurfaceFactory == null) {
      this.mEGLWindowSurfaceFactory = new DefaultWindowSurfaceFactory();
    }
    this.mRenderer = renderer;
    this.mGLThread = new GLThread(this.mThisWeakRef, this);
    this.mGLThread.start();
  }

  /**
   * 设置EGL上下文工厂
   */
  setEGLContextFactory(factory: EGLContextFactory): void {
    this.checkRenderThreadState();
    this.mEGLContextFactory = factory;
  }

  /**
   * 设置EGL窗口表面工厂
   */
  setEGLWindowSurfaceFactory(factory: EGLWindowSurfaceFactory): void {
    this.checkRenderThreadState();
    this.mEGLWindowSurfaceFactory = factory;
  }

  /**
   * 设置EGL配置选择器
   */
  setEGLConfigChooser(configChooser: EGLConfigChooser): void;
  setEGLConfigChooser(needDepth: boolean): void;
  setEGLConfigChooser(redSize: number, greenSize: number, blueSize: number, alphaSize: number, depthSize: number, stencilSize: number): void;
  setEGLConfigChooser(
    configChooserOrNeedDepthOrRedSize: EGLConfigChooser | boolean | number,
    greenSize?: number,
    blueSize?: number,
    alphaSize?: number,
    depthSize?: number,
    stencilSize?: number
  ): void {
    this.checkRenderThreadState();
    if (typeof configChooserOrNeedDepthOrRedSize === 'object') {
      this.mEGLConfigChooser = configChooserOrNeedDepthOrRedSize;
    } else if (typeof configChooserOrNeedDepthOrRedSize === 'boolean') {
      this.mEGLConfigChooser = new SimpleEGLConfigChooser(this, configChooserOrNeedDepthOrRedSize);
    } else {
      this.mEGLConfigChooser = new ComponentSizeChooser(
        this,
        configChooserOrNeedDepthOrRedSize,
        greenSize!,
        blueSize!,
        alphaSize!,
        depthSize!,
        stencilSize!
      );
    }
  }

  /**
   * 设置EGL上下文客户端版本
   */
  setEGLContextClientVersion(version: number): void {
    this.checkRenderThreadState();
    this.mEGLContextClientVersion = version;
  }

  /**
   * 设置渲染模式
   */
  setRenderMode(renderMode: number): void {
    this.mGLThread?.setRenderMode(renderMode);
  }

  /**
   * 获取渲染模式
   */
  getRenderMode(): number {
    return this.mGLThread?.getRenderMode() ?? GLTextureView.RENDERMODE_CONTINUOUSLY;
  }

  /**
   * 请求渲染
   */
  requestRender(): void {
    this.mGLThread?.requestRender();
  }

  /**
   * 表面纹理可用
   */
  onSurfaceTextureAvailable(surfaceTexture: SurfaceTexture, width: number, height: number): void {
    this.mGLThread?.surfaceCreated();
  }

  /**
   * 表面纹理大小改变
   */
  onSurfaceTextureSizeChanged(surfaceTexture: SurfaceTexture, width: number, height: number): void {
    this.mGLThread?.onWindowResize(width, height);
  }

  /**
   * 大小改变
   */
  onSizeChanged(w: number, h: number, oldw: number, oldh: number): void {
    this.mGLThread?.onWindowResize(w, h);
  }

  /**
   * 表面纹理销毁
   */
  onSurfaceTextureDestroyed(surfaceTexture: SurfaceTexture): boolean {
    this.mGLThread?.surfaceDestroyed();
    return true;
  }

  /**
   * 表面纹理更新
   */
  onSurfaceTextureUpdated(surfaceTexture: SurfaceTexture): void {
    this.requestRender();
  }

  /**
   * SurfaceHolder回调
   */
  on(holder: SurfaceHolder): void {
    this.mGLThread?.surfaceCreated();
  }

  /**
   * 暂停
   */
  onPause(): void {
    this.mGLThread?.onPause();
  }

  /**
   * 恢复
   */
  onResume(): void {
    this.mGLThread?.onResume();
  }

  /**
   * 队列事件
   */
  queueEvent(r: () => void): void {
    this.mGLThread?.queueEvent(r);
  }

  /**
   * 附加到窗口
   */
  onAttachedToWindow(): void {
    if (GLTextureView.LOG_ATTACH_DETACH) {
      console.log(`${GLTextureView.TAG} onAttachedToWindow reattach = ${this.mDetached}`);
    }
    if (this.mDetached && (this.mRenderer != null)) {
      let renderMode = GLTextureView.RENDERMODE_CONTINUOUSLY;
      let w = 0, h = 0;

      if (this.mGLThread != null) {
        renderMode = this.mGLThread.getRenderMode();
        w = this.mGLThread.mWidth;
        h = this.mGLThread.mHeight;
      }
      this.mGLThread = new GLThread(this.mThisWeakRef, this);
      if (renderMode != GLTextureView.RENDERMODE_CONTINUOUSLY) {
        this.mGLThread.setRenderMode(renderMode);
      }
      if (w != 0 && h != 0) {
        this.mGLThread.mWidth = w;
        this.mGLThread.mHeight = h;
      }
      this.mGLThread.start();
    }
    this.mDetached = false;
  }

  /**
   * 从窗口分离
   */
  onDetachedFromWindow(): void {
    if (GLTextureView.LOG_ATTACH_DETACH) {
      console.log(`${GLTextureView.TAG} onDetachedFromWindow: ${this.mGLThread}`);
    }
    if (this.mGLThread != null) {
      this.mGLThread.requestExitAndWait();
    }
    this.mDetached = true;
  }

  /**
   * 获取SurfaceTexture
   */
  getSurfaceTexture(): SurfaceTexture | null {
    // TODO: 在HarmonyOS中，需要从XComponent获取SurfaceTexture
    return this.textureView?.getSurfaceTexture() ?? null;
  }

  private checkRenderThreadState(): void {
    if (this.mGLThread != null) {
      throw new Error('setRenderer has already been called for this instance.');
    }
  }
}

