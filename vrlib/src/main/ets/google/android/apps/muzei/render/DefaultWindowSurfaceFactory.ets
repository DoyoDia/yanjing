/**
 * 默认EGL窗口表面工厂
 */
import { EGLWindowSurfaceFactory } from './GLTextureView';
import { EGL10, EGLDisplay, EGLConfig, EGLSurface } from './EGLTypes';

export class DefaultWindowSurfaceFactory implements EGLWindowSurfaceFactory {
  createWindowSurface(egl: EGL10, display: EGLDisplay, config: EGLConfig, nativeWindow: ESObject): EGLSurface | null {
    let result: EGLSurface | null = null;
    try {
      // TODO: 在HarmonyOS中，需要使用EGL/NAPI创建窗口表面
      result = egl.eglCreateWindowSurface(display, config, nativeWindow, null);
    } catch (e) {
      // 此异常表示surface flinger surface无效
      console.error('GLTextureView', 'eglCreateWindowSurface', e);
    }
    return result;
  }

  destroySurface(egl: EGL10, display: EGLDisplay, surface: EGLSurface): void {
    // TODO: 在HarmonyOS中，需要使用EGL/NAPI销毁表面
    egl.eglDestroySurface(display, surface);
  }
}

