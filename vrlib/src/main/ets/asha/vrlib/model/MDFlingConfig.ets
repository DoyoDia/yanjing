/**
 * Created by hzqiujiadi on 2017/5/15.
 * hzqiujiadi ashqalcn@gmail.com
 */

/**
 * 插值器接口
 * 注意：在鸿蒙中可以使用对应的动画插值器
 */
export interface TimeInterpolator {
  getInterpolation(input: number): number;
}

/**
 * 减速插值器实现
 */
class DecelerateInterpolator implements TimeInterpolator {
  getInterpolation(input: number): number {
    return (1.0 - (1.0 - input) * (1.0 - input));
  }
}

/**
 * 滑动配置类
 */
export class MDFlingConfig {
  private mInterpolator: TimeInterpolator = new DecelerateInterpolator();
  private mDuring: number = 400; // 持续时间（毫秒）
  private mSensitivity: number = 1.0; // 灵敏度

  setInterpolator(i: TimeInterpolator): MDFlingConfig {
    this.mInterpolator = i;
    return this;
  }

  /**
   * 设置持续时间
   * @param during 持续时间（毫秒）
   */
  setDuring(during: number): MDFlingConfig {
    this.mDuring = during;
    return this;
  }

  /**
   * 设置灵敏度
   * @param sensitivity 默认值为 1.0，10.0 比 0.1 更快
   */
  setSensitivity(sensitivity: number): MDFlingConfig {
    this.mSensitivity = sensitivity;
    return this;
  }

  getInterpolator(): TimeInterpolator {
    return this.mInterpolator;
  }

  getDuring(): number {
    return this.mDuring;
  }

  getSensitivity(): number {
    return this.mSensitivity;
  }
}

