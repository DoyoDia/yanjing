/**
 * EGL辅助类
 */
import { GLTextureView } from './GLTextureView';
import { LogWriter } from './LogWriter';
import { EGL10, EGLDisplay, EGLSurface, EGLConfig, EGLContext, GL, GL10, GLDebugHelper } from './EGLTypes';

const LOG_EGL = false;
const LOG_THREADS = false;
const DEBUG_CHECK_GL_ERROR = 1;
const DEBUG_LOG_GL_CALLS = 2;

export class EglHelper {
  private mGLTextureViewWeakRef: WeakRef<GLTextureView>;
  mEgl: EGL10 | null = null;
  mEglDisplay: EGLDisplay | null = null;
  mEglSurface: EGLSurface | null = null;
  mEglConfig: EGLConfig | null = null;
  mEglContext: EGLContext | null = null;

  constructor(glTextureViewWeakRef: WeakRef<GLTextureView>) {
    this.mGLTextureViewWeakRef = glTextureViewWeakRef;
  }

  /**
   * 初始化EGL
   */
  start(): void {
    if (LOG_EGL) {
      console.warn('EglHelper', `start() tid=${this.getThreadId()}`);
    }
    /*
     * 获取EGL实例
     */
    // TODO: 在HarmonyOS中，需要使用EGL/NAPI获取EGL实例
    // mEgl = (EGL10) EGLContext.getEGL();
    this.mEgl = null as EGL10 | null; // 占位符

    /*
     * 获取默认显示
     */
    // EGL10.EGL_DEFAULT_DISPLAY = 0
    this.mEglDisplay = this.mEgl?.eglGetDisplay(0) ?? null;

    // EGL10.EGL_NO_DISPLAY = null
    if (this.mEglDisplay == null) {
      throw new Error('eglGetDisplay failed');
    }

    /*
     * 初始化EGL显示
     */
    const version: number[] = [0, 0];
    if (!this.mEgl?.eglInitialize(this.mEglDisplay, version)) {
      throw new Error('eglInitialize failed');
    }
    const view = this.mGLTextureViewWeakRef.deref();
    if (view == null) {
      this.mEglConfig = null;
      this.mEglContext = null;
    } else {
      this.mEglConfig = view.mEGLConfigChooser?.chooseConfig(this.mEgl, this.mEglDisplay) ?? null;

      /*
       * 创建EGL上下文
       */
      this.mEglContext = view.mEGLContextFactory?.createContext(
        this.mEgl,
        this.mEglDisplay,
        this.mEglConfig!
      ) ?? null;
    }
    // EGL10.EGL_NO_CONTEXT = null
    if (this.mEglContext == null) {
      this.mEglContext = null;
      EglHelper.throwEglException('createContext', this.mEgl?.eglGetError() ?? 0);
    }
    if (LOG_EGL) {
      console.warn('EglHelper', `createContext ${this.mEglContext} tid=${this.getThreadId()}`);
    }

    this.mEglSurface = null;
  }

  /**
   * 创建EGL表面
   */
  createSurface(): boolean {
    if (LOG_EGL) {
      console.warn('EglHelper', `createSurface() tid=${this.getThreadId()}`);
    }
    /*
     * 检查前置条件
     */
    if (this.mEgl == null) {
      throw new Error('egl not initialized');
    }
    if (this.mEglDisplay == null) {
      throw new Error('eglDisplay not initialized');
    }
    if (this.mEglConfig == null) {
      throw new Error('mEglConfig not initialized');
    }

    /*
     * 窗口大小已改变，需要创建新表面
     */
    this.destroySurfaceImp();

    /*
     * 创建EGL表面
     */
    const view = this.mGLTextureViewWeakRef.deref();
    if (view != null) {
      this.mEglSurface = view.mEGLWindowSurfaceFactory?.createWindowSurface(
        this.mEgl,
        this.mEglDisplay,
        this.mEglConfig,
        view.getSurfaceTexture()
      ) ?? null;
    } else {
      this.mEglSurface = null;
    }

    // EGL10.EGL_NO_SURFACE = null
    if (this.mEglSurface == null) {
      const error = this.mEgl?.eglGetError() ?? 0;
      // EGL10.EGL_BAD_NATIVE_WINDOW = 0x300D
      if (error === 0x300D) {
        console.error('EglHelper', 'createWindowSurface returned EGL_BAD_NATIVE_WINDOW.');
      }
      return false;
    }

    /*
     * 在发出GL命令之前，需要确保上下文是当前的并绑定到表面
     */
    if (!this.mEgl?.eglMakeCurrent(this.mEglDisplay, this.mEglSurface, this.mEglSurface, this.mEglContext)) {
      /*
       * 无法使上下文成为当前上下文，可能是因为底层SurfaceView表面已被销毁
       */
      EglHelper.logEglErrorAsWarning('EGLHelper', 'eglMakeCurrent', this.mEgl?.eglGetError() ?? 0);
      return false;
    }

    return true;
  }

  /**
   * 为当前EGL上下文创建GL对象
   */
  createGL(): GL {
    const gl = this.mEglContext?.getGL() ?? null;
    if (gl == null) {
      throw new Error('GL context is null');
    }
    const view = this.mGLTextureViewWeakRef.deref();
    if (view != null) {
      let resultGL: GL = gl;
      if (view.mGLWrapper != null) {
        resultGL = view.mGLWrapper.wrap(gl);
      }

      if ((view.mDebugFlags & (DEBUG_CHECK_GL_ERROR | DEBUG_LOG_GL_CALLS)) != 0) {
        let configFlags = 0;
        let log: ESObject = null;
        if ((view.mDebugFlags & DEBUG_CHECK_GL_ERROR) != 0) {
          // GLDebugHelper.CONFIG_CHECK_GL_ERROR
          configFlags |= 1;
        }
        if ((view.mDebugFlags & DEBUG_LOG_GL_CALLS) != 0) {
          log = new LogWriter();
        }
        // TODO: 在HarmonyOS中，需要使用GLDebugHelper
        // resultGL = GLDebugHelper.wrap(resultGL, configFlags, log);
      }
      return resultGL;
    }
    return gl;
  }

  /**
   * 显示当前渲染表面
   */
  swap(): number {
    // EGL10.EGL_SUCCESS = 0x3000
    if (this.mEgl == null || this.mEglDisplay == null || this.mEglSurface == null) {
      return 0;
    }
    if (!this.mEgl.eglSwapBuffers(this.mEglDisplay, this.mEglSurface)) {
      return this.mEgl.eglGetError() ?? 0;
    }
    return 0x3000; // EGL_SUCCESS
  }

  /**
   * 销毁表面
   */
  destroySurface(): void {
    if (LOG_EGL) {
      console.warn('EglHelper', `destroySurface() tid=${this.getThreadId()}`);
    }
    this.destroySurfaceImp();
  }

  private destroySurfaceImp(): void {
    // EGL10.EGL_NO_SURFACE = null
    if (this.mEglSurface != null) {
      // EGL10.EGL_NO_CONTEXT = null
      if (this.mEgl != null && this.mEglDisplay != null) {
        this.mEgl.eglMakeCurrent(
          this.mEglDisplay,
          null, // EGL10.EGL_NO_SURFACE
          null, // EGL10.EGL_NO_SURFACE
          null  // EGL10.EGL_NO_CONTEXT
        );
      }
      const view = this.mGLTextureViewWeakRef.deref();
      if (view != null && this.mEgl != null && this.mEglDisplay != null) {
        view.mEGLWindowSurfaceFactory?.destroySurface(this.mEgl, this.mEglDisplay, this.mEglSurface);
      }
      this.mEglSurface = null;
    }
  }

  /**
   * 完成EGL
   */
  finish(): void {
    if (LOG_EGL) {
      console.warn('EglHelper', `finish() tid=${this.getThreadId()}`);
    }
    if (this.mEglContext != null) {
      const view = this.mGLTextureViewWeakRef.deref();
      if (view != null && this.mEgl != null && this.mEglDisplay != null) {
        view.mEGLContextFactory?.destroyContext(this.mEgl, this.mEglDisplay, this.mEglContext);
      }
      this.mEglContext = null;
    }
    if (this.mEglDisplay != null) {
      this.mEgl?.eglTerminate(this.mEglDisplay);
      this.mEglDisplay = null;
    }
  }

  static throwEglException(functionName: string, error: number): void {
    const message = EglHelper.formatEglError(functionName, error);
    if (LOG_THREADS) {
      console.error('EglHelper', `throwEglException tid=${EglHelper.getThreadId()} ${message}`);
    }
    throw new Error(message);
  }

  static logEglErrorAsWarning(tag: string, functionName: string, error: number): void {
    console.warn(tag, EglHelper.formatEglError(functionName, error));
  }

  static formatEglError(functionName: string, error: number): string {
    return `${functionName} failed`; // + EGLLogWrapper.getErrorString(error);
  }

  private getThreadId(): number {
    // TODO: 在HarmonyOS中，需要使用相应的线程ID获取方法
    return 0;
  }

  private static getThreadId(): number {
    // TODO: 在HarmonyOS中，需要使用相应的线程ID获取方法
    return 0;
  }
}

