/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { AbsInteractiveStrategy, InteractiveModeManagerParams } from './AbsInteractiveStrategy';
import { MD360Director } from '../../MD360Director';
import { SensorEvent, SensorEventListener } from '../../AndroidTypes';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';

// TODO: 当相关类型迁移后，取消注释并删除类型占位符
// import { HeadTracker } from '../../google/vrtoolkit/cardboard/sensors/HeadTracker';
// import { DeviceSensorLooper } from '../../google/vrtoolkit/cardboard/sensors/DeviceSensorLooper';

type HeadTracker = Object;
type DeviceSensorLooper = Object;

/**
 * Cardboard运动交互策略类
 */
export class CardboardMotionStrategy extends AbsInteractiveStrategy implements SensorEventListener {
  private static readonly TAG: string = "CardboardMotionStrategy";
  // 传感器更新节流间隔（约60fps）
  private static readonly SENSOR_THROTTLE_MS: number = 16;

  private mRegistered: boolean = false;
  private mIsSupport: boolean | null = null;
  private mTmpMatrix: number[] = new Array(16).fill(0);
  private readonly matrixLock: object = new Object();
  private headTracker: HeadTracker | null = null;
  private mDeviceSensorLooper: DeviceSensorLooper | null = null;
  private isOn: boolean = false;
  private updateSensorRunnable: () => void;
  // 节流：上次 post 时间
  private lastPostTime: number = 0;

  constructor(params: InteractiveModeManagerParams) {
    super(params);
    this.updateSensorRunnable = () => {
      if (!this.mRegistered || !this.isOn) return;

      // 在ETS中，可以使用锁或其他同步机制
      for (const director of this.getDirectorList()) {
        director.updateSensorMatrix(this.mTmpMatrix);
      }
    };
  }

  onResume(context: Context): void {
    this.registerSensor(context);
  }

  onPause(context: Context): void {
    this.unregisterSensor(context);
  }

  handleDrag(distanceX: number, distanceY: number): boolean {
    return false;
  }

  onOrientationChanged(context: Context): void {
    // 空实现
  }

  turnOnInGL(context: Context): void {
    this.isOn = true;
    for (const director of this.getDirectorList()) {
      director.reset();
    }
  }

  turnOffInGL(context: Context): void {
    this.isOn = false;
    this.runOnUiThread(() => {
      this.unregisterSensor(context);
    });
  }

  isSupport(context: Context): boolean {
    if (this.mIsSupport == null) {
      // 在鸿蒙中，需要检查传感器支持
      // SensorManager mSensorManager = context.getSystemService(Context.SENSOR_SERVICE);
      // Sensor sensor1 = mSensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
      // Sensor sensor2 = mSensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
      // this.mIsSupport = (sensor1 != null || sensor2 != null);
      this.mIsSupport = true; // 占位实现
    }
    return this.mIsSupport;
  }

  private registerSensor(context: Context): void {
    if (this.mRegistered) return;

    // 在鸿蒙中，需要使用对应的传感器API和Cardboard SDK
    // 这里保留接口，具体实现需要根据鸿蒙的传感器API和Cardboard SDK完成

    // if (mDeviceSensorLooper == null) {
    //   mDeviceSensorLooper = new DeviceSensorLooper(mSensorManager, getParams().mMotionDelay);
    // }
    // if (headTracker == null) {
    //   Display display = windowManager.getDefaultDisplay();
    //   headTracker = new HeadTracker(mDeviceSensorLooper, new SystemClock(), display);
    // }
    // mDeviceSensorLooper.registerListener(this);
    // headTracker.startTracking();

    this.mRegistered = true;
  }

  private unregisterSensor(context: Context): void {
    if (!this.mRegistered) return;

    // 在鸿蒙中，需要使用对应的传感器API和Cardboard SDK
    // mDeviceSensorLooper.unregisterListener(this);
    // headTracker.stopTracking();

    this.mRegistered = false;
  }

  onSensorChanged(event: SensorEvent): void {
    if (this.isOn && event.accuracy !== 0) {
      const params = this.getParams();
      if (params?.mSensorListener != null) {
        params.mSensorListener.onSensorChanged(event);
      }

      // 在ETS中，可以使用锁或其他同步机制
      // Matrix.setIdentityM(mTmpMatrix, 0);
      // headTracker.getLastHeadView(mTmpMatrix, 0);
      // 设置单位矩阵
      for (let i = 0; i < 16; i++) {
        this.mTmpMatrix[i] = 0;
      }
      this.mTmpMatrix[0] = 1;
      this.mTmpMatrix[5] = 1;
      this.mTmpMatrix[10] = 1;
      this.mTmpMatrix[15] = 1;
      // headTracker.getLastHeadView(mTmpMatrix, 0);

      // 节流：避免高频 post 导致队列堆积
      const now = Date.now();
      if (now - this.lastPostTime >= CardboardMotionStrategy.SENSOR_THROTTLE_MS) {
        this.lastPostTime = now;
        params?.glHandler?.post(this.updateSensorRunnable);
      }
    }
  }

  onAccuracyChanged(sensor: Object, accuracy: number): void {
    const params = this.getParams();
    if (params?.mSensorListener != null) {
      params.mSensorListener.onAccuracyChanged(sensor, accuracy);
    }

    // 在ETS中，可以使用锁或其他同步机制
    // Matrix.setIdentityM(mTmpMatrix, 0);
    // headTracker.getLastHeadView(mTmpMatrix, 0);
    // 设置单位矩阵
    for (let i = 0; i < 16; i++) {
      this.mTmpMatrix[i] = 0;
    }
    this.mTmpMatrix[0] = 1;
    this.mTmpMatrix[5] = 1;
    this.mTmpMatrix[10] = 1;
    this.mTmpMatrix[15] = 1;
    // headTracker.getLastHeadView(mTmpMatrix, 0);

    // 节流：避免高频 post 导致队列堆积
    const now = Date.now();
    if (now - this.lastPostTime >= CardboardMotionStrategy.SENSOR_THROTTLE_MS) {
      this.lastPostTime = now;
      this.getParams()?.glHandler?.post(this.updateSensorRunnable);
    }
  }

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   */
  override destroy(): void {
    // 先关闭传感器
    this.isOn = false;
    this.mRegistered = false;
    // 清理闭包引用（使用类型断言绕过只读属性）
    (this as Record<string, ESObject>).updateSensorRunnable = null;
    // 清理 headTracker 和 looper
    this.headTracker = null;
    this.mDeviceSensorLooper = null;
    // 调用父类销毁
    super.destroy();
  }
}


