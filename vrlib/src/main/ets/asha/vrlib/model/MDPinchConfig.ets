/**
 * Created by hzqiujiadi on 16/9/29.
 * hzqiujiadi ashqalcn@gmail.com
 */

/**
 * 捏合配置类
 */
export class MDPinchConfig {
  private max: number = 5;
  private min: number = 1;
  private defaultValue: number = 1;
  private mSensitivity: number = 1;

  setMax(max: number): MDPinchConfig {
    this.max = max;
    return this;
  }

  setMin(min: number): MDPinchConfig {
    this.min = min;
    return this;
  }

  setDefaultValue(defaultValue: number): MDPinchConfig {
    this.defaultValue = defaultValue;
    return this;
  }

  setSensitivity(mSensitivity: number): MDPinchConfig {
    this.mSensitivity = mSensitivity;
    return this;
  }

  getSensitivity(): number {
    return this.mSensitivity;
  }

  getMax(): number {
    return this.max;
  }

  getMin(): number {
    return this.min;
  }

  getDefaultValue(): number {
    return this.defaultValue;
  }
}

