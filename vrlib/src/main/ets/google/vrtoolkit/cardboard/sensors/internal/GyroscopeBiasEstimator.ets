/**
 * 陀螺仪偏置估计器类
 */
import { LowPassFilter } from './LowPassFilter';
import { Vector3d } from './Vector3d';

export class GyroscopeBiasEstimator {
  private static readonly ACCEL_LOWPASS_FREQ: number = 1.0;
  private static readonly GYRO_LOWPASS_FREQ: number = 10.0;
  private static readonly GYRO_BIAS_LOWPASS_FREQ: number = 0.15;
  private static readonly NUM_GYRO_BIAS_SAMPLES_THRESHOLD: number = 30;
  private static readonly NUM_GYRO_BIAS_SAMPLES_INITIAL_SMOOTHING: number = 100;
  private accelLowPass: LowPassFilter | null = null;
  private gyroLowPass: LowPassFilter | null = null;
  private gyroBiasLowPass: LowPassFilter | null = null;
  private static readonly ACCEL_DIFF_STATIC_THRESHOLD: number = 0.5;
  private static readonly GYRO_DIFF_STATIC_THRESHOLD: number = 0.008;
  // 使用 definite assignment 断言，实际会在 reset() 中完成初始化
  private smoothedGyroDiff!: Vector3d;
  private smoothedAccelDiff!: Vector3d;
  private static readonly GYRO_FOR_BIAS_THRESHOLD: number = 0.35;
  private static readonly IS_STATIC_NUM_FRAMES_THRESHOLD: number = 10;
  private isAccelStatic!: IsStaticCounter;
  private isGyroStatic!: IsStaticCounter;

  constructor() {
    this.reset();
  }

  reset(): void {
    this.smoothedGyroDiff = new Vector3d();
    this.smoothedAccelDiff = new Vector3d();
    this.accelLowPass = new LowPassFilter(GyroscopeBiasEstimator.ACCEL_LOWPASS_FREQ);
    this.gyroLowPass = new LowPassFilter(GyroscopeBiasEstimator.GYRO_LOWPASS_FREQ);
    this.gyroBiasLowPass = new LowPassFilter(GyroscopeBiasEstimator.GYRO_BIAS_LOWPASS_FREQ);
    this.isAccelStatic = new IsStaticCounter(GyroscopeBiasEstimator.IS_STATIC_NUM_FRAMES_THRESHOLD);
    this.isGyroStatic = new IsStaticCounter(GyroscopeBiasEstimator.IS_STATIC_NUM_FRAMES_THRESHOLD);
  }

  processGyroscope(gyro: Vector3d, sensorTimestampNs: number): void {
    this.gyroLowPass!.addSample(gyro, sensorTimestampNs);
    Vector3d.sub(gyro, this.gyroLowPass!.getFilteredData(), this.smoothedGyroDiff);
    this.isGyroStatic.appendFrame(this.smoothedGyroDiff.length() < GyroscopeBiasEstimator.GYRO_DIFF_STATIC_THRESHOLD);
    if (this.isGyroStatic.isRecentlyStatic() && this.isAccelStatic.isRecentlyStatic()) {
      this.updateGyroBias(gyro, sensorTimestampNs);
    }
  }

  processAccelerometer(accel: Vector3d, sensorTimestampNs: number): void {
    this.accelLowPass!.addSample(accel, sensorTimestampNs);
    Vector3d.sub(accel, this.accelLowPass!.getFilteredData(), this.smoothedAccelDiff);
    this.isAccelStatic.appendFrame(this.smoothedAccelDiff.length() < GyroscopeBiasEstimator.ACCEL_DIFF_STATIC_THRESHOLD);
  }

  getGyroBias(result: Vector3d): void {
    if (this.gyroBiasLowPass!.getNumSamples() < GyroscopeBiasEstimator.NUM_GYRO_BIAS_SAMPLES_THRESHOLD) {
      result.setZero();
    } else {
      result.set(this.gyroBiasLowPass!.getFilteredData());
      const rampUpRatio = Math.min(1.0, (this.gyroBiasLowPass!.getNumSamples() - GyroscopeBiasEstimator.NUM_GYRO_BIAS_SAMPLES_THRESHOLD) / GyroscopeBiasEstimator.NUM_GYRO_BIAS_SAMPLES_INITIAL_SMOOTHING);
      result.scale(rampUpRatio);
    }
  }

  private updateGyroBias(gyro: Vector3d, sensorTimestampNs: number): void {
    if (gyro.length() < GyroscopeBiasEstimator.GYRO_FOR_BIAS_THRESHOLD) {
      const updateWeight = Math.max(0.0, 1.0 - gyro.length() / GyroscopeBiasEstimator.GYRO_FOR_BIAS_THRESHOLD);
      const weightedUpdateWeight = updateWeight * updateWeight;
      this.gyroBiasLowPass!.addWeightedSample(this.gyroLowPass!.getFilteredData(), sensorTimestampNs, weightedUpdateWeight);
    }
  }
}

/**
 * 静态计数器类
 */
class IsStaticCounter {
  private readonly minStaticFrames: number;
  private consecutiveIsStatic: number = 0;

  constructor(minStaticFrames: number) {
    this.minStaticFrames = minStaticFrames;
  }

  appendFrame(isStatic: boolean): void {
    if (!isStatic) {
      this.consecutiveIsStatic = 0;
    } else {
      this.consecutiveIsStatic++;
    }
  }

  isRecentlyStatic(): boolean {
    return this.consecutiveIsStatic >= this.minStaticFrames;
  }
}

