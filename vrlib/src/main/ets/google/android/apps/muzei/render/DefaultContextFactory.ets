/**
 * 默认EGL上下文工厂
 */
import { EGLContextFactory } from './GLTextureView';
import { EGL10, EGLDisplay, EGLConfig, EGLContext } from './EGLTypes';

export class DefaultContextFactory implements EGLContextFactory {
  private static readonly EGL_CONTEXT_CLIENT_VERSION: number = 0x3098;
  private readonly mEGLContextClientVersion: number;
  private readonly glTextureView: ESObject; // GLTextureView

  constructor(glTextureView: ESObject) {
    this.glTextureView = glTextureView;
    this.mEGLContextClientVersion = glTextureView.mEGLContextClientVersion ?? 0;
  }

  createContext(egl: EGL10, display: EGLDisplay, config: EGLConfig): EGLContext {
    const attrib_list: number[] = [
      DefaultContextFactory.EGL_CONTEXT_CLIENT_VERSION,
      this.mEGLContextClientVersion,
      // EGL10.EGL_NONE
      0x3038
    ];

    // TODO: 在HarmonyOS中，需要使用EGL/NAPI创建上下文
    return egl.eglCreateContext(
      display,
      config,
      null, // EGL10.EGL_NO_CONTEXT
      this.mEGLContextClientVersion != 0 ? attrib_list : null
    );
  }

  destroyContext(egl: EGL10, display: EGLDisplay, context: EGLContext): void {
    if (!egl.eglDestroyContext(display, context)) {
      console.error('DefaultContextFactory', `display: ${display} context: ${context}`);
      // TODO: 在HarmonyOS中，需要使用EGL/NAPI获取错误
      const error = egl.eglGetError();
      throw new Error(`eglDestroyContext failed with error: ${error}`);
    }
  }
}

