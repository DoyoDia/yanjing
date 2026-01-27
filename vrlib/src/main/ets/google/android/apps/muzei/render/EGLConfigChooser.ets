/**
 * EGL配置选择器相关类
 */
import { EGLConfigChooser } from './GLTextureView';
import { EGL10, EGLDisplay, EGLConfig } from './EGLTypes';

/**
 * 基础配置选择器
 */
abstract class BaseConfigChooser implements EGLConfigChooser {
  protected mConfigSpec: number[];
  private readonly mEGLContextClientVersion: number;

  constructor(configSpec: number[], eglContextClientVersion: number) {
    this.mEGLContextClientVersion = eglContextClientVersion;
    this.mConfigSpec = this.filterConfigSpec(configSpec);
  }

  chooseConfig(egl: EGL10, display: EGLDisplay): EGLConfig {
    const num_config: number[] = [0];
    // TODO: 在HarmonyOS中，需要使用EGL/NAPI选择配置
    if (!egl.eglChooseConfig(display, this.mConfigSpec, null, 0, num_config)) {
      throw new Error('eglChooseConfig failed');
    }

    const numConfigs = num_config[0];

    if (numConfigs <= 0) {
      throw new Error('No configs match configSpec');
    }

    const configs: EGLConfig[] = new Array(numConfigs);
    if (!egl.eglChooseConfig(display, this.mConfigSpec, configs, numConfigs, num_config)) {
      throw new Error('eglChooseConfig#2 failed');
    }
    const config = this.chooseConfigInternal(egl, display, configs);
    if (config == null) {
      throw new Error('No config chosen');
    }
    return config;
  }

  protected abstract chooseConfigInternal(egl: EGL10, display: EGLDisplay, configs: EGLConfig[]): EGLConfig | null;

  private filterConfigSpec(configSpec: number[]): number[] {
    if (this.mEGLContextClientVersion != 2) {
      return configSpec;
    }
    // 我们知道没有子类定义EGL_RENDERABLE_TYPE
    const len = configSpec.length;
    const newConfigSpec: number[] = new Array(len + 2);
    // System.arraycopy(configSpec, 0, newConfigSpec, 0, len-1);
    for (let i = 0; i < len - 1; i++) {
      newConfigSpec[i] = configSpec[i];
    }
    // EGL10.EGL_RENDERABLE_TYPE = 0x3040
    newConfigSpec[len - 1] = 0x3040;
    // EGL_OPENGL_ES2_BIT = 4
    newConfigSpec[len] = 4;
    // EGL10.EGL_NONE = 0x3038
    newConfigSpec[len + 1] = 0x3038;
    return newConfigSpec;
  }
}

/**
 * 组件大小选择器
 */
export class ComponentSizeChooser extends BaseConfigChooser {
  private mValue: number[] = [0];
  protected mRedSize: number;
  protected mGreenSize: number;
  protected mBlueSize: number;
  protected mAlphaSize: number;
  protected mDepthSize: number;
  protected mStencilSize: number;

  constructor(
    glTextureView: ESObject,
    redSize: number,
    greenSize: number,
    blueSize: number,
    alphaSize: number,
    depthSize: number,
    stencilSize: number
  ) {
    // EGL常量
    const EGL_RED_SIZE = 0x3024;
    const EGL_GREEN_SIZE = 0x3023;
    const EGL_BLUE_SIZE = 0x3022;
    const EGL_ALPHA_SIZE = 0x3021;
    const EGL_DEPTH_SIZE = 0x3025;
    const EGL_STENCIL_SIZE = 0x3026;
    const EGL_NONE = 0x3038;

    super(
      [
        EGL_RED_SIZE, redSize,
        EGL_GREEN_SIZE, greenSize,
        EGL_BLUE_SIZE, blueSize,
        EGL_ALPHA_SIZE, alphaSize,
        EGL_DEPTH_SIZE, depthSize,
        EGL_STENCIL_SIZE, stencilSize,
        EGL_NONE
      ],
      glTextureView.mEGLContextClientVersion ?? 0
    );
    this.mRedSize = redSize;
    this.mGreenSize = greenSize;
    this.mBlueSize = blueSize;
    this.mAlphaSize = alphaSize;
    this.mDepthSize = depthSize;
    this.mStencilSize = stencilSize;
  }

  protected override chooseConfigInternal(egl: EGL10, display: EGLDisplay, configs: EGLConfig[]): EGLConfig | null {
    // EGL常量
    const EGL_DEPTH_SIZE = 0x3025;
    const EGL_STENCIL_SIZE = 0x3026;
    const EGL_RED_SIZE = 0x3024;
    const EGL_GREEN_SIZE = 0x3023;
    const EGL_BLUE_SIZE = 0x3022;
    const EGL_ALPHA_SIZE = 0x3021;

    for (const config of configs) {
      const d = this.findConfigAttrib(egl, display, config, EGL_DEPTH_SIZE, 0);
      const s = this.findConfigAttrib(egl, display, config, EGL_STENCIL_SIZE, 0);
      if ((d >= this.mDepthSize) && (s >= this.mStencilSize)) {
        const r = this.findConfigAttrib(egl, display, config, EGL_RED_SIZE, 0);
        const g = this.findConfigAttrib(egl, display, config, EGL_GREEN_SIZE, 0);
        const b = this.findConfigAttrib(egl, display, config, EGL_BLUE_SIZE, 0);
        const a = this.findConfigAttrib(egl, display, config, EGL_ALPHA_SIZE, 0);
        if ((r == this.mRedSize) && (g == this.mGreenSize)
          && (b == this.mBlueSize) && (a == this.mAlphaSize)) {
          return config;
        }
      }
    }
    return null;
  }

  private findConfigAttrib(egl: EGL10, display: EGLDisplay, config: EGLConfig, attribute: number, defaultValue: number): number {
    if (egl.eglGetConfigAttrib(display, config, attribute, this.mValue)) {
      return this.mValue[0];
    }
    return defaultValue;
  }
}

/**
 * 简单EGL配置选择器
 */
export class SimpleEGLConfigChooser extends ComponentSizeChooser {
  constructor(glTextureView: ESObject, withDepthBuffer: boolean) {
    super(glTextureView, 8, 8, 8, 0, withDepthBuffer ? 16 : 0, 0);
  }
}

