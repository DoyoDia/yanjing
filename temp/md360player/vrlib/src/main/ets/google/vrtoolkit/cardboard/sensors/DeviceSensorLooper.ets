/**
 * 设备传感器循环器类
 * 注意：此类依赖Android的SensorManager、Sensor、SensorEvent、SensorEventListener、Handler、HandlerThread、Looper等API
 * 在HarmonyOS中需要使用相应的传感器API替代
 */
import { SensorEventProvider } from './SensorEventProvider';
import { SensorManager, Sensor, SensorEvent, SensorEventListener, Handler, HandlerThread, Looper, Build } from './AndroidTypes';

export class DeviceSensorLooper implements SensorEventProvider {
  private static readonly LOG_TAG: string = 'DeviceSensorLooper';
  private isRunning: boolean = false;
  private sensorManager: SensorManager | null = null;
  private sensorLooper: Looper | null = null;
  private sensorEventListener: SensorEventListener | null = null;
  private readonly registeredListeners: SensorEventListener[] = [];
  private level: number = 0;
  private readonly lock: object = new Object(); // 用于同步

  constructor(sensorManager: SensorManager, level?: number) {
    this.sensorManager = sensorManager;
    this.level = level ?? 0;
  }

  // 分发回调，供内部监听器类使用
  // 需要被内部类访问，因此设为 public
  public dispatchSensorChanged(event: SensorEvent): void {
    const listeners = [...this.registeredListeners];
    for (const listener of listeners) {
      listener.onSensorChanged(event);
    }
  }

  public dispatchAccuracyChanged(sensor: Sensor, accuracy: number): void {
    const listeners = [...this.registeredListeners];
    for (const listener of listeners) {
      listener.onAccuracyChanged(sensor, accuracy);
    }
  }

  private getUncalibratedGyro(): Sensor | null {
    // TODO: 在HarmonyOS中需要获取设备制造商信息
    // Build.MANUFACTURER 在HarmonyOS中需要使用相应的API
    const manufacturer: string = ''; // 占位符，需要HarmonyOS API
    if (manufacturer === 'HTC') {
      return null;
    }
    // Sensor.TYPE_GYROSCOPE_UNCALIBRATED = 16
    // TODO: 在HarmonyOS中使用相应的传感器类型常量
    return this.sensorManager?.getDefaultSensor(16) ?? null;
  }

  start(): void {
    if (!this.isRunning) {
      // 创建传感器事件监听器（必须使用显式类，避免结构类型的对象字面量）
      this.sensorEventListener = new InternalSensorEventListener(this);

      // TODO: 在HarmonyOS中需要使用Worker线程或相应的异步机制替代HandlerThread
      // HandlerThread在HarmonyOS中需要使用Worker或TaskPool
      // 这里使用占位符实现
      const onLooperPrepared = () => {
        // TODO: 在HarmonyOS中需要使用相应的Handler/线程机制
        // Sensor.TYPE_ACCELEROMETER = 1
        const accelerometer: Sensor | null = this.sensorManager?.getDefaultSensor(1) ?? null;
        if (accelerometer && this.sensorEventListener) {
          // TODO: 在HarmonyOS中使用相应的传感器注册API
          // this.sensorManager.registerListener(this.sensorEventListener, accelerometer, this.level, undefined);
        }

        const gyroscope: Sensor | null = this.getUncalibratedGyro();
        if (gyroscope == null) {
          console.log(`${DeviceSensorLooper.LOG_TAG}: Uncalibrated gyroscope unavailable, default to regular gyroscope.`);
          // Sensor.TYPE_GYROSCOPE = 4
          const regularGyro: Sensor | null = this.sensorManager?.getDefaultSensor(4) ?? null;
          if (regularGyro && this.sensorEventListener) {
            // TODO: 在HarmonyOS中使用相应的传感器注册API
            // this.sensorManager.registerListener(this.sensorEventListener, regularGyro, this.level, undefined);
          }
        } else if (this.sensorEventListener) {
          // TODO: 在HarmonyOS中使用相应的传感器注册API
          // this.sensorManager.registerListener(this.sensorEventListener, gyroscope, this.level, undefined);
        }
      };

      // TODO: 在HarmonyOS中启动Worker线程
      // sensorThread.start();
      // this.sensorLooper = sensorThread.getLooper();
      
      // 临时调用onLooperPrepared（实际应该在Worker线程准备就绪后调用）
      onLooperPrepared();
      
      this.isRunning = true;
    }
  }

  stop(): void {
    if (this.isRunning) {
      // TODO: 在HarmonyOS中使用相应的传感器注销API
      if (this.sensorEventListener) {
        // this.sensorManager?.unregisterListener(this.sensorEventListener);
      }
      this.sensorEventListener = null;
      
      // TODO: 在HarmonyOS中停止Worker线程
      // this.sensorLooper?.quit();
      this.sensorLooper = null;
      
      this.isRunning = false;
    }
  }

  registerListener(listener: SensorEventListener): void {
    // 在ETS中，可以使用锁或其他同步机制
    if (!this.registeredListeners.includes(listener)) {
      this.registeredListeners.push(listener);
    }
  }

  unregisterListener(listener: SensorEventListener): void {
    // 在ETS中，可以使用锁或其他同步机制
    const index = this.registeredListeners.indexOf(listener);
    if (index >= 0) {
      this.registeredListeners.splice(index, 1);
    }
  }
}

/**
 * 内部传感器事件监听器，实现显式的 SensorEventListener 接口，
 * 避免使用匿名对象字面量触发 ArkTS 结构类型检查。
 */
class InternalSensorEventListener implements SensorEventListener {
  private owner: DeviceSensorLooper;

  constructor(owner: DeviceSensorLooper) {
    this.owner = owner;
  }

  onSensorChanged(event: SensorEvent): void {
    this.owner.dispatchSensorChanged(event);
  }

  onAccuracyChanged(sensor: Sensor, accuracy: number): void {
    this.owner.dispatchAccuracyChanged(sensor, accuracy);
  }
}

