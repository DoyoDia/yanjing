/**
 * 头部追踪器类
 * 注意：此类依赖Android的Context、SensorManager、Display、WindowManager、Sensor、SensorEvent、SensorEventListener、Matrix等API
 * 在HarmonyOS中需要使用相应的API替代
 */
import { Clock } from './Clock';
import { SensorEventProvider } from './SensorEventProvider';
import { SystemClock } from './SystemClock';
import { DeviceSensorLooper } from './DeviceSensorLooper';
import { OrientationEKF } from './internal/OrientationEKF';
import { GyroscopeBiasEstimator } from './internal/GyroscopeBiasEstimator';
import { Vector3d } from './internal/Vector3d';
import { Matrix3x3d } from './internal/Matrix3x3d';
import { MatrixUtil } from '../../../../asha/vrlib/common/MatrixUtil';
import { Context, SensorManager, Display, WindowManager, Sensor, SensorEvent, SensorEventListener } from './AndroidTypes';

export class HeadTracker implements SensorEventListener {
  private static readonly DEFAULT_NECK_HORIZONTAL_OFFSET: number = 0.08;
  private static readonly DEFAULT_NECK_VERTICAL_OFFSET: number = 0.075;
  private static readonly DEFAULT_NECK_MODEL_FACTOR: number = 1.0;
  private static readonly PREDICTION_TIME_IN_SECONDS: number = 0.058;
  
  private readonly display: Display | null;
  private readonly ekfToHeadTracker: number[] = new Array(16).fill(0);
  private readonly sensorToDisplay: number[] = new Array(16).fill(0);
  private displayRotation: number = -1.0;
  private readonly neckModelTranslation: number[] = new Array(16).fill(0);
  private readonly tmpHeadView: number[] = new Array(16).fill(0);
  private readonly tmpHeadView2: number[] = new Array(16).fill(0);
  private neckModelFactor: number = 1.0;
  private readonly neckModelFactorMutex: object = new Object();
  private tracking: boolean = false;
  private readonly tracker: OrientationEKF;
  private readonly gyroBiasEstimatorMutex: object = new Object();
  private gyroBiasEstimator: GyroscopeBiasEstimator | null = null;
  private sensorEventProvider: SensorEventProvider | null = null;
  private clock: Clock | null = null;
  private latestGyroEventClockTimeNs: number = 0;
  private firstGyroValue: boolean = true;
  private initialSystemGyroBias: number[] = [0, 0, 0];
  private readonly gyroBias: Vector3d = new Vector3d();
  private readonly latestGyro: Vector3d = new Vector3d();
  private readonly latestAcc: Vector3d = new Vector3d();

  /**
   * 从Context创建HeadTracker实例
   * 注意：此方法依赖Android的Context、SensorManager、WindowManager、Display等API
   */
  static createFromContext(context: Context): HeadTracker {
    // TODO: 在HarmonyOS中需要使用相应的系统服务API
    // SensorManager sensorManager = context.getSystemService(Context.SENSOR_SERVICE);
    // Display display = ((WindowManager)context.getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay();
    // 占位实现：实际项目中应通过 context.getSystemService 获取真实对象
    const sensorService: Object = context.getSystemService('sensor');
    const sensorManager = sensorService as SensorManager;
    const display = null as Display | null;
    return new HeadTracker(new DeviceSensorLooper(sensorManager), new SystemClock(), display);
  }

  constructor(sensorEventProvider: SensorEventProvider, clock: Clock, display: Display | null) {
    this.clock = clock;
    this.sensorEventProvider = sensorEventProvider;
    this.tracker = new OrientationEKF();
    this.display = display;
    this.setGyroBiasEstimationEnabled(true);
    MatrixUtil.setIdentityM(this.neckModelTranslation, 0);
  }

  onSensorChanged(event: SensorEvent): void {
    // Sensor.TYPE_ACCELEROMETER = 1
    if (event.sensor.getType() === 1) {
      this.latestAcc.set(event.values[0], event.values[1], event.values[2]);
      this.tracker.processAcc(this.latestAcc, event.timestamp);
      
      // 在ETS中，可以使用锁或其他同步机制
      if (this.gyroBiasEstimator != null) {
        this.gyroBiasEstimator.processAccelerometer(this.latestAcc, event.timestamp);
      }
    } else if (event.sensor.getType() === 4 || event.sensor.getType() === 16) {
      // Sensor.TYPE_GYROSCOPE = 4
      // Sensor.TYPE_GYROSCOPE_UNCALIBRATED = 16
      this.latestGyroEventClockTimeNs = this.clock?.nanoTime() ?? 0;
      
      if (event.sensor.getType() === 16) {
        if (this.firstGyroValue && event.values.length === 6) {
          this.initialSystemGyroBias[0] = event.values[3];
          this.initialSystemGyroBias[1] = event.values[4];
          this.initialSystemGyroBias[2] = event.values[5];
        }
        
        this.latestGyro.set(
          event.values[0] - this.initialSystemGyroBias[0],
          event.values[1] - this.initialSystemGyroBias[1],
          event.values[2] - this.initialSystemGyroBias[2]
        );
      } else {
        this.latestGyro.set(event.values[0], event.values[1], event.values[2]);
      }
      
      this.firstGyroValue = false;
      
      // 在ETS中，可以使用锁或其他同步机制
      if (this.gyroBiasEstimator != null) {
        this.gyroBiasEstimator.processGyroscope(this.latestGyro, event.timestamp);
        this.gyroBiasEstimator.getGyroBias(this.gyroBias);
        Vector3d.sub(this.latestGyro, this.gyroBias, this.latestGyro);
      }
      
      this.tracker.processGyro(this.latestGyro, event.timestamp);
    }
  }

  onAccuracyChanged(sensor: Sensor, accuracy: number): void {
    // 空实现
  }

  startTracking(): void {
    if (!this.tracking) {
      this.tracker.reset();
      
      // 在ETS中，可以使用锁或其他同步机制
      if (this.gyroBiasEstimator != null) {
        this.gyroBiasEstimator.reset();
      }
      
      this.firstGyroValue = true;
      this.sensorEventProvider?.registerListener(this);
      this.sensorEventProvider?.start();
      this.tracking = true;
    }
  }

  resetTracker(): void {
    this.tracker.reset();
  }

  stopTracking(): void {
    if (this.tracking) {
      this.sensorEventProvider?.unregisterListener(this);
      this.sensorEventProvider?.stop();
      this.tracking = false;
    }
  }

  setNeckModelEnabled(enabled: boolean): void {
    if (enabled) {
      this.setNeckModelFactor(1.0);
    } else {
      this.setNeckModelFactor(0.0);
    }
  }

  getNeckModelFactor(): number {
    // 在ETS中，可以使用锁或其他同步机制
    return this.neckModelFactor;
  }

  setNeckModelFactor(factor: number): void {
    // 在ETS中，可以使用锁或其他同步机制
    if (factor >= 0.0 && factor <= 1.0) {
      this.neckModelFactor = factor;
    } else {
      throw new Error('factor should be within [0.0, 1.0]');
    }
  }

  setGyroBiasEstimationEnabled(enabled: boolean): void {
    // 在ETS中，可以使用锁或其他同步机制
    if (!enabled) {
      this.gyroBiasEstimator = null;
    } else if (this.gyroBiasEstimator == null) {
      this.gyroBiasEstimator = new GyroscopeBiasEstimator();
    }
  }

  getGyroBiasEstimationEnabled(): boolean {
    // 在ETS中，可以使用锁或其他同步机制
    return this.gyroBiasEstimator != null;
  }

  getLastHeadView(headView: number[], offset: number): void {
    if (offset + 16 > headView.length) {
      throw new Error('Not enough space to write the result');
    }
    
    // TODO: 在HarmonyOS中需要使用相应的Display API获取旋转角度
    // Display.ROTATION_0 = 0, ROTATION_90 = 1, ROTATION_180 = 2, ROTATION_270 = 3
    let rotation: number = 0.0;
    const displayRotation: number = this.display?.getRotation() ?? 0;
    switch (displayRotation) {
      case 0:
        rotation = 0.0;
        break;
      case 1:
        rotation = 90.0;
        break;
      case 2:
        rotation = 180.0;
        break;
      case 3:
        rotation = 270.0;
        break;
    }
    
    if (rotation !== this.displayRotation) {
      this.displayRotation = rotation;
      MatrixUtil.setRotateEulerM(this.sensorToDisplay, 0, 0.0, 0.0, -rotation);
      MatrixUtil.setRotateEulerM(this.ekfToHeadTracker, 0, -90.0, 0.0, rotation);
    }
    
    // 在ETS中，可以使用锁或其他同步机制
    if (!this.tracker.isReady()) {
      return;
    }
    
    const secondsSinceLastGyroEvent: number = (this.clock?.nanoTime() ?? 0 - this.latestGyroEventClockTimeNs) / 1_000_000_000;
    const secondsToPredictForward: number = secondsSinceLastGyroEvent + HeadTracker.PREDICTION_TIME_IN_SECONDS;
    const mat: number[] = this.tracker.getPredictedGLMatrix(secondsToPredictForward);
    
    for (let i = 0; i < mat.length && i < this.tmpHeadView.length; i++) {
      this.tmpHeadView[i] = mat[i];
    }
    
    MatrixUtil.multiplyMM(this.tmpHeadView2, 0, this.sensorToDisplay, 0, this.tmpHeadView, 0);
    MatrixUtil.multiplyMM(headView, offset, this.tmpHeadView2, 0, this.ekfToHeadTracker, 0);
    MatrixUtil.setIdentityM(this.neckModelTranslation, 0);
    MatrixUtil.translateM(
      this.neckModelTranslation,
      0,
      0.0,
      -this.neckModelFactor * HeadTracker.DEFAULT_NECK_VERTICAL_OFFSET,
      this.neckModelFactor * HeadTracker.DEFAULT_NECK_HORIZONTAL_OFFSET
    );
    MatrixUtil.multiplyMM(this.tmpHeadView, 0, this.neckModelTranslation, 0, headView, offset);
    // 将 neck 模型平移后的结果写回 headView，然后在其基础上再做一次平移
    for (let i = 0; i < 16; i++) {
      headView[offset + i] = this.tmpHeadView[i];
    }
    MatrixUtil.translateM(
      headView,
      offset,
      0.0,
      this.neckModelFactor * HeadTracker.DEFAULT_NECK_VERTICAL_OFFSET,
      0.0
    );
  }

  /**
   * 测试方法：获取当前姿态
   */
  getCurrentPoseForTest(): Matrix3x3d {
    return new Matrix3x3d(this.tracker.getRotationMatrix());
  }

  /**
   * 测试方法：设置陀螺仪偏置估计器
   */
  setGyroBiasEstimator(estimator: GyroscopeBiasEstimator): void {
    // 在ETS中，可以使用锁或其他同步机制
    this.gyroBiasEstimator = estimator;
  }
}

