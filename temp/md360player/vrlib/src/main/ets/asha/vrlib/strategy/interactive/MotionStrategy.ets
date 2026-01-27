/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { AbsInteractiveStrategy, InteractiveModeManagerParams } from './AbsInteractiveStrategy';
import { MDMainHandler } from '../../common/MDMainHandler';
import { VRUtil } from '../../common/VRUtil';
import { MD360Director } from '../../MD360Director';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';
import { SensorEventListener, SensorEvent } from '../../AndroidTypes';

// type Context = any;
type WindowManager = Object;

/**
 * 运动交互策略类
 */
export class MotionStrategy extends AbsInteractiveStrategy implements SensorEventListener {
  private static readonly TAG: string = "MotionStrategy";

  private windowManager: WindowManager | null = null;
  private mSensorMatrix: number[] = new Array(16).fill(0);
  private mTmpMatrix: number[] = new Array(16).fill(0);
  private mRegistered: boolean = false;
  private mIsSupport: boolean | null = null;
  private readonly mMatrixLock: object = new Object();
  private isOn: boolean = false;
  private updateSensorRunnable: (() => void) | null;

  constructor(params: InteractiveModeManagerParams) {
    super(params);
    this.updateSensorRunnable = () => {
      if (!this.mRegistered || !this.isOn) return;
      // mTmpMatrix will be used in multi thread.
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
    // windowManager = context.getSystemService(Context.WINDOW_SERVICE);
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
      // Sensor sensor = mSensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR);
      // this.mIsSupport = (sensor != null);
      this.mIsSupport = true; // 占位实现
    }
    return this.mIsSupport;
  }

  protected registerSensor(context: Context): void {
    if (this.mRegistered) return;

    // 在鸿蒙中，需要使用对应的传感器API
    // 这里保留接口，具体实现需要根据鸿蒙的传感器API完成

    // SensorManager mSensorManager = context.getSystemService(Context.SENSOR_SERVICE);
    // Sensor sensor = mSensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR);
    // if (sensor == null) {
    //   console.error(TAG, "TYPE_ROTATION_VECTOR sensor not support!");
    //   return;
    // }
    // mSensorManager.registerListener(this, sensor, getParams().mMotionDelay, MDMainHandler.sharedHandler());

    this.mRegistered = true;
  }

  protected unregisterSensor(context: Context): void {
    if (!this.mRegistered) return;

    // 在鸿蒙中，需要使用对应的传感器API
    // SensorManager mSensorManager = context.getSystemService(Context.SENSOR_SERVICE);
    // mSensorManager.unregisterListener(this);

    this.mRegistered = false;
  }

  onSensorChanged(event: SensorEvent): void {
    if (this.isOn && event.accuracy !== 0) {
      const params = this.getParams();
      if (params?.mSensorListener != null) {
        params.mSensorListener.onSensorChanged(event);
      }

      const type = event.sensor.getType();
      // switch (type) {
      //   case Sensor.TYPE_ROTATION_VECTOR:
      //     VRUtil.sensorRotationVector2Matrix(event, windowManager.getDefaultDisplay().getRotation(), mSensorMatrix);
      //     synchronized (mMatrixLock) {
      //       System.arraycopy(mSensorMatrix, 0, mTmpMatrix, 0, 16);
      //     }
      //     params.glHandler.post(updateSensorRunnable);
      //     break;
      // }
    }
  }

  onAccuracyChanged(sensor: Object, accuracy: number): void {
    const params = this.getParams();
    if (params?.mSensorListener != null) {
      params.mSensorListener.onAccuracyChanged(sensor, accuracy);
    }
  }

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   */
  override destroy(): void {
    // 先关闭传感器
    this.isOn = false;
    this.mRegistered = false;
    // 清理闭包引用
    this.updateSensorRunnable = null;
    this.windowManager = null;
    // 调用父类销毁
    super.destroy();
  }
}


