/**
 * Created by hzqiujiadi on 16/7/29.
 * hzqiujiadi ashqalcn@gmail.com
 *
 * http://mipav.cit.nih.gov/pubwiki/index.php/Barrel_Distortion_Correction
 */

/**
 * 桶形畸变配置类
 */
export class BarrelDistortionConfig {
  private paramA: number = -0.068; // affects only the outermost pixels of the image
  private paramB: number = 0.320000; // most cases only require b optimization
  private paramC: number = -0.2; // most uniform correction
  private scale: number = 0.95;
  private defaultEnabled: boolean = false;

  constructor() {
    // 使用默认值
  }

  setParamA(paramA: number): BarrelDistortionConfig {
    this.paramA = paramA;
    return this;
  }

  setParamB(paramB: number): BarrelDistortionConfig {
    this.paramB = paramB;
    return this;
  }

  setParamC(paramC: number): BarrelDistortionConfig {
    this.paramC = paramC;
    return this;
  }

  setScale(scale: number): BarrelDistortionConfig {
    this.scale = scale;
    return this;
  }

  setDefaultEnabled(defaultEnabled: boolean): BarrelDistortionConfig {
    this.defaultEnabled = defaultEnabled;
    return this;
  }

  getParamA(): number {
    return this.paramA;
  }

  getParamB(): number {
    return this.paramB;
  }

  getParamC(): number {
    return this.paramC;
  }

  getScale(): number {
    return this.scale;
  }

  isDefaultEnabled(): boolean {
    return this.defaultEnabled;
  }
}

