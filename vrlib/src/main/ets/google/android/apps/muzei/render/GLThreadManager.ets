/**
 * GL线程管理器
 */
import { GLThread } from './GLThread';
import { GL10 } from './EGLTypes';

const LOG_THREADS = false;
const LOG_SURFACE = false;

export class GLThreadManager {
  private static readonly TAG: string = 'GLThreadManager';
  private static readonly kGLES_20: number = 0x20000;
  private static readonly kMSM7K_RENDERER_PREFIX: string = 'Q3Dimension MSM7500 ';

  private mGLESVersionCheckComplete: boolean = false;
  private mGLESVersion: number = 0;
  private mGLESDriverCheckComplete: boolean = false;
  private mMultipleGLESContextsAllowed: boolean = true;
  private mLimitedGLESContexts: boolean = false;
  private mEglOwner: GLThread | null = null;
  private readonly lock: object = new Object(); // 用于同步

  /**
   * 线程退出
   */
  threadExiting(thread: GLThread): void {
    // 在ETS中，可以使用锁或其他同步机制
    if (LOG_THREADS) {
      console.log('GLThread', `exiting tid=${thread.getId()}`);
    }
    thread.mExited = true;
    if (this.mEglOwner === thread) {
      this.mEglOwner = null;
    }
    // notifyAll() - 在ETS中需要使用相应的通知机制
  }

  /**
   * 尝试获取EGL上下文
   */
  tryAcquireEglContextLocked(thread: GLThread): boolean {
    // 在ETS中，可以使用锁或其他同步机制
    if (this.mEglOwner === thread || this.mEglOwner == null) {
      this.mEglOwner = thread;
      // notifyAll() - 在ETS中需要使用相应的通知机制
      return true;
    }
    this.checkGLESVersion();
    if (this.mMultipleGLESContextsAllowed) {
      return true;
    }
    // 通知拥有线程应该释放上下文
    if (this.mEglOwner != null) {
      this.mEglOwner.requestReleaseEglContextLocked();
    }
    return false;
  }

  /**
   * 释放EGL上下文
   */
  releaseEglContextLocked(thread: GLThread): void {
    // 在ETS中，可以使用锁或其他同步机制
    if (this.mEglOwner === thread) {
      this.mEglOwner = null;
    }
    // notifyAll() - 在ETS中需要使用相应的通知机制
  }

  /**
   * 是否应该在暂停时释放EGL上下文
   */
  shouldReleaseEGLContextWhenPausing(): boolean {
    // 在ETS中，可以使用锁或其他同步机制
    // 即使硬件支持多个EGL上下文，在暂停时也释放EGL上下文
    // 否则设备可能会耗尽EGL上下文
    return this.mLimitedGLESContexts;
  }

  /**
   * 是否应该在暂停时终止EGL
   */
  shouldTerminateEGLWhenPausing(): boolean {
    // 在ETS中，可以使用锁或其他同步机制
    this.checkGLESVersion();
    return !this.mMultipleGLESContextsAllowed;
  }

  /**
   * 检查GL驱动
   */
  checkGLDriver(gl: GL10): void {
    // 在ETS中，可以使用锁或其他同步机制
    if (!this.mGLESDriverCheckComplete) {
      this.checkGLESVersion();
      // TODO: 在HarmonyOS中，需要使用相应的GL API获取渲染器字符串
      const renderer: string = gl?.glGetString(0x1F01) ?? ''; // GL10.GL_RENDERER
      if (this.mGLESVersion < GLThreadManager.kGLES_20) {
        this.mMultipleGLESContextsAllowed = !renderer.startsWith(GLThreadManager.kMSM7K_RENDERER_PREFIX);
        // notifyAll() - 在ETS中需要使用相应的通知机制
      }
      this.mLimitedGLESContexts = !this.mMultipleGLESContextsAllowed;
      if (LOG_SURFACE) {
        console.warn(
          GLThreadManager.TAG,
          `checkGLDriver renderer = "${renderer}" multipleContextsAllowed = ${this.mMultipleGLESContextsAllowed} mLimitedGLESContexts = ${this.mLimitedGLESContexts}`
        );
      }
      this.mGLESDriverCheckComplete = true;
    }
  }

  private checkGLESVersion(): void {
    if (!this.mGLESVersionCheckComplete) {
      // TODO: 在HarmonyOS中，需要检查OpenGL ES版本
      // mGLESVersion = SystemProperties.getInt("ro.opengles.version", ConfigurationInfo.GL_ES_VERSION_UNDEFINED);
      // if (mGLESVersion >= kGLES_20) {
      this.mMultipleGLESContextsAllowed = true;
      // }
      if (LOG_SURFACE) {
        console.warn(
          GLThreadManager.TAG,
          `checkGLESVersion mGLESVersion = ${this.mGLESVersion} mMultipleGLESContextsAllowed = ${this.mMultipleGLESContextsAllowed}`
        );
      }
      this.mGLESVersionCheckComplete = true;
    }
  }
}

// 单例实例
export const sGLThreadManager = new GLThreadManager();

