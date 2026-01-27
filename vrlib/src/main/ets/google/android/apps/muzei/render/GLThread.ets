/**
 * GL线程类
 * 注意：在HarmonyOS中，此类需要使用Worker或TaskPool替代Java的Thread
 */
import { GLTextureView, Renderer } from './GLTextureView';
import { EglHelper } from './EglHelper';
import { sGLThreadManager } from './GLThreadManager';
import { GL10, EGLConfig, EGL11 } from './EGLTypes';

const LOG_THREADS = false;
const LOG_PAUSE_RESUME = false;
const LOG_SURFACE = false;
const LOG_RENDERER = false;
const LOG_RENDERER_DRAW_FRAME = false;
const TAG = 'GLTextureView';

// EGL常量
const EGL_SUCCESS = 0x3000;
const EGL_CONTEXT_LOST = 0x300E;

// 渲染模式常量
const RENDERMODE_WHEN_DIRTY = 0;
const RENDERMODE_CONTINUOUSLY = 1;

export class GLThread {
  mWidth: number = 0;
  mHeight: number = 0;
  mExited: boolean = false;

  private mShouldExit: boolean = false;
  private mRequestPaused: boolean = false;
  private mPaused: boolean = false;
  private mHasSurface: boolean = false;
  private mSurfaceIsBad: boolean = false;
  private mWaitingForSurface: boolean = false;
  private mHaveEglContext: boolean = false;
  private mHaveEglSurface: boolean = false;
  private mFinishedCreatingEglSurface: boolean = false;
  private mShouldReleaseEglContext: boolean = false;
  private mRenderMode: number = RENDERMODE_CONTINUOUSLY;
  private mRequestRender: boolean = true;
  private mRenderComplete: boolean = false;
  private mEventQueue: (() => void)[] = [];
  private mSizeChanged: boolean = true;
  private mEglHelper: EglHelper | null = null;
  private mGLTextureViewWeakRef: WeakRef<GLTextureView>;
  private glTextureView: GLTextureView;
  private threadId: number = 0;
  private isRunning: boolean = false;

  constructor(glTextureViewWeakRef: WeakRef<GLTextureView>, glTextureView: GLTextureView) {
    this.mGLTextureViewWeakRef = glTextureViewWeakRef;
    this.glTextureView = glTextureView;
    this.threadId = Math.floor(Math.random() * 1000000); // 临时ID生成
  }

  /**
   * 启动线程
   * 注意：在HarmonyOS中，需要使用Worker或TaskPool
   */
  start(): void {
    if (this.isRunning) {
      return;
    }
    this.isRunning = true;
    // TODO: 在HarmonyOS中，需要使用Worker或TaskPool创建线程
    // 这里使用Promise模拟异步执行
    Promise.resolve().then(() => {
      this.run();
    });
  }

  private run(): void {
    if (LOG_THREADS) {
      console.log('GLThread', `starting tid=${this.getId()}`);
    }

    try {
      this.guardedRun();
    } catch (e) {
      // 中断异常，正常退出
    } finally {
      sGLThreadManager.threadExiting(this);
    }
  }

  private stopEglSurfaceLocked(): void {
    if (this.mHaveEglSurface) {
      this.mHaveEglSurface = false;
      this.mEglHelper?.destroySurface();
    }
  }

  private stopEglContextLocked(): void {
    if (this.mHaveEglContext) {
      this.mEglHelper?.finish();
      this.mHaveEglContext = false;
      sGLThreadManager.releaseEglContextLocked(this);
    }
  }

  private async guardedRun(): Promise<void> {
    this.mEglHelper = new EglHelper(this.mGLTextureViewWeakRef);
    this.mHaveEglContext = false;
    this.mHaveEglSurface = false;
    try {
      let gl: GL10 | null = null;
      let createEglContext = false;
      let createEglSurface = false;
      let createGlInterface = false;
      let lostEglContext = false;
      let sizeChanged = false;
      let wantRenderNotification = false;
      let doRenderNotification = false;
      let askedToReleaseEglContext = false;
      let w = 0;
      let h = 0;
      let event: (() => void) | null = null;

      while (true) {
        // 在ETS中，可以使用锁或其他同步机制
        if (this.mShouldExit) {
          return;
        }

        if (this.mEventQueue.length > 0) {
          event = this.mEventQueue.shift() ?? null;
          if (event != null) {
            event();
            event = null;
            continue;
          }
        }

        // 更新暂停状态
        let pausing = false;
        if (this.mPaused !== this.mRequestPaused) {
          pausing = this.mRequestPaused;
          this.mPaused = this.mRequestPaused;
        }

        // 是否需要释放EGL上下文？
        if (this.mShouldReleaseEglContext) {
          this.stopEglSurfaceLocked();
          this.stopEglContextLocked();
          this.mShouldReleaseEglContext = false;
          askedToReleaseEglContext = true;
        }

        // 是否丢失了EGL上下文？
        if (lostEglContext) {
          this.stopEglSurfaceLocked();
          this.stopEglContextLocked();
          lostEglContext = false;
        }

        // 暂停时释放EGL表面
        if (pausing && this.mHaveEglSurface) {
          this.stopEglSurfaceLocked();
        }

        // 暂停时可选释放EGL上下文
        if (pausing && this.mHaveEglContext) {
          const view = this.mGLTextureViewWeakRef.deref();
          const preserveEglContextOnPause = view?.mPreserveEGLContextOnPause ?? false;
          if (!preserveEglContextOnPause || sGLThreadManager.shouldReleaseEGLContextWhenPausing()) {
            this.stopEglContextLocked();
          }
        }

        // 暂停时可选终止EGL
        if (pausing) {
          if (sGLThreadManager.shouldTerminateEGLWhenPausing()) {
            this.mEglHelper?.finish();
          }
        }

        // 是否丢失了SurfaceView表面？
        if ((!this.mHasSurface) && (!this.mWaitingForSurface)) {
          if (this.mHaveEglSurface) {
            this.stopEglSurfaceLocked();
          }
          this.mWaitingForSurface = true;
          this.mSurfaceIsBad = false;
        }

        // 是否获取了SurfaceView表面？
        if (this.mHasSurface && this.mWaitingForSurface) {
          this.mWaitingForSurface = false;
        }

        if (doRenderNotification) {
          wantRenderNotification = false;
          doRenderNotification = false;
          this.mRenderComplete = true;
        }

        // 准备绘制？
        if (this.readyToDraw()) {
          // 如果没有EGL上下文，尝试获取一个
          if (!this.mHaveEglContext) {
            if (askedToReleaseEglContext) {
              askedToReleaseEglContext = false;
            } else if (sGLThreadManager.tryAcquireEglContextLocked(this)) {
              try {
                this.mEglHelper?.start();
              } catch (t) {
                sGLThreadManager.releaseEglContextLocked(this);
                throw new Error(String(t));
              }
              this.mHaveEglContext = true;
              createEglContext = true;
            }
          }

          if (this.mHaveEglContext && !this.mHaveEglSurface) {
            this.mHaveEglSurface = true;
            createEglSurface = true;
            createGlInterface = true;
            sizeChanged = true;
          }

          if (this.mHaveEglSurface) {
            if (this.mSizeChanged) {
              sizeChanged = true;
              w = this.mWidth;
              h = this.mHeight;
              wantRenderNotification = true;
              createEglSurface = true;
              this.mSizeChanged = false;
            }
            this.mRequestRender = false;
            // 跳出循环进行渲染
          }
        }

        // 等待条件满足
        if (!this.readyToDraw()) {
          // TODO: 在HarmonyOS中，需要使用适当的等待机制
          await new Promise<void>(resolve => setTimeout(() => resolve(), 16)); // 模拟等待
          continue;
        }

        if (createEglSurface) {
          if (this.mEglHelper?.createSurface()) {
            this.mFinishedCreatingEglSurface = true;
          } else {
            this.mFinishedCreatingEglSurface = true;
            this.mSurfaceIsBad = true;
            continue;
          }
          createEglSurface = false;
        }

        if (createGlInterface) {
          gl = this.mEglHelper?.createGL() as GL10;
          if (gl) {
            sGLThreadManager.checkGLDriver(gl);
          }
          createGlInterface = false;
        }

        if (createEglContext) {
          const view = this.mGLTextureViewWeakRef.deref();
          if (view != null && view.mRenderer != null && gl != null) {
            const config = this.mEglHelper?.mEglConfig;
            if (config != null) {
              view.mRenderer.onSurfaceCreated(gl, config);
            }
          }
          createEglContext = false;
        }

        if (sizeChanged) {
          const view = this.mGLTextureViewWeakRef.deref();
          if (view != null && view.mRenderer != null && gl != null) {
            view.mRenderer.onSurfaceChanged(gl, w, h);
          }
          sizeChanged = false;
        }

        {
          const view = this.mGLTextureViewWeakRef.deref();
          if (view != null && view.mRenderer != null && gl != null) {
            view.mRenderer.onDrawFrame(gl);
          }
        }

        const swapError = this.mEglHelper?.swap() ?? EGL_SUCCESS;
        switch (swapError) {
          case EGL_SUCCESS:
            break;
          case EGL_CONTEXT_LOST:
            lostEglContext = true;
            break;
          default:
            EglHelper.logEglErrorAsWarning('GLThread', 'eglSwapBuffers', swapError);
            this.mSurfaceIsBad = true;
            break;
        }

        if (wantRenderNotification) {
          doRenderNotification = true;
        }

        // 控制帧率
        await new Promise<void>(resolve => setTimeout(() => resolve(), 16)); // 约60fps
      }
    } finally {
      /*
       * 清理所有内容...
       */
      this.stopEglSurfaceLocked();
      this.stopEglContextLocked();
      this.mExited = true;  // 标记线程已退出
      console.error(TAG, `guardedRun exit: ${this}`);
    }
  }

  ableToDraw(): boolean {
    return this.mHaveEglContext && this.mHaveEglSurface && this.readyToDraw();
  }

  private readyToDraw(): boolean {
    return (!this.mPaused) && this.mHasSurface && (!this.mSurfaceIsBad)
      && (this.mWidth > 0) && (this.mHeight > 0)
      && (this.mRequestRender || (this.mRenderMode === RENDERMODE_CONTINUOUSLY));
  }

  setRenderMode(renderMode: number): void {
    if (!((RENDERMODE_WHEN_DIRTY <= renderMode) && (renderMode <= RENDERMODE_CONTINUOUSLY))) {
      throw new Error('renderMode');
    }
    this.mRenderMode = renderMode;
  }

  getRenderMode(): number {
    return this.mRenderMode;
  }

  requestRender(): void {
    this.mRequestRender = true;
  }

  surfaceCreated(): void {
    if (LOG_THREADS) {
      console.log('GLThread', `surfaceCreated tid=${this.getId()}`);
    }
    this.mHasSurface = true;
    this.mFinishedCreatingEglSurface = false;
    while (this.mWaitingForSurface
      && !this.mFinishedCreatingEglSurface
      && !this.mExited) {
      // TODO: 在HarmonyOS中，需要使用适当的等待机制
    }
  }

  surfaceDestroyed(): void {
    if (LOG_THREADS) {
      console.log('GLThread', `surfaceDestroyed tid=${this.getId()}`);
    }
    this.mHasSurface = false;
    while ((!this.mWaitingForSurface) && (!this.mExited)) {
      // TODO: 在HarmonyOS中，需要使用适当的等待机制
    }
  }

  onPause(): void {
    if (LOG_PAUSE_RESUME) {
      console.log('GLThread', `onPause tid=${this.getId()}`);
    }
    this.mRequestPaused = true;
    while ((!this.mExited) && (!this.mPaused)) {
      // TODO: 在HarmonyOS中，需要使用适当的等待机制
    }
  }

  onResume(): void {
    if (LOG_PAUSE_RESUME) {
      console.log('GLThread', `onResume tid=${this.getId()}`);
    }
    this.mRequestPaused = false;
    this.mRequestRender = true;
    this.mRenderComplete = false;
    while ((!this.mExited) && this.mPaused && (!this.mRenderComplete)) {
      // TODO: 在HarmonyOS中，需要使用适当的等待机制
    }
  }

  onWindowResize(w: number, h: number): void {
    this.mWidth = w;
    this.mHeight = h;
    this.mSizeChanged = true;
    this.mRequestRender = true;
    this.mRenderComplete = false;

    // 等待线程响应调整大小并渲染一帧
    while (!this.mExited && !this.mPaused && !this.mRenderComplete
      && this.ableToDraw()) {
      // TODO: 在HarmonyOS中，需要使用适当的等待机制
    }
  }

  requestExitAndWait(): void {
    // 不要从GLThread线程调用此方法，否则会导致死锁！
    // 在 ArkTS/JavaScript 单线程环境中，不能使用同步等待
    // 只设置退出标志，让渲染循环自己检测并退出
    this.mShouldExit = true;
    // 注意：原 Android 代码使用 wait/notify，这里改为异步模式
    // 调用者需要通过检查 mExited 来确认退出完成
  }

  /**
   * 检查线程是否已退出
   */
  isExited(): boolean {
    return this.mExited;
  }

  requestReleaseEglContextLocked(): void {
    this.mShouldReleaseEglContext = true;
  }

  /**
   * 队列事件
   */
  queueEvent(r: () => void): void {
    if (r == null) {
      throw new Error('r must not be null');
    }
    this.mEventQueue.push(r);
  }

  getId(): number {
    return this.threadId;
  }
}

