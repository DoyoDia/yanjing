/**
 * SensorManager - 传感器管理模块
 * 负责订阅手机旋转矢量传感器，获取姿态四元数，并转换为 OpenGL 视图矩阵
 *
 * 坐标系说明：
 * - Android/鸿蒙设备坐标系（当手机竖直持有时）：
 *   X: 指向右侧
 *   Y: 指向上方（屏幕顶部）
 *   Z: 指向用户（从屏幕向外）
 *
 * - OpenGL 坐标系（右手坐标系）：
 *   X: 指向右侧
 *   Y: 指向上方
 *   Z: 指向用户（从屏幕向外）
 *
 * - 眼镜视野坐标系（用户横持手机像望远镜）：
 *   需要将竖屏坐标系重映射为横屏坐标系
 */

import { sensor } from '@kit.SensorServiceKit';
import { Quaternion, Matrix4, quaternionFromRotationX, quaternionFromRotationZ, degToRad } from '../utils/MathUtils';

/**
 * 传感器数据回调接口
 */
export interface SensorDataListener {
  /**
   * 当姿态数据更新时调用
   * @param quaternion 设备姿态四元数
   * @param viewMatrix OpenGL 视图矩阵（列主序，16个浮点数）
   */
  onOrientationUpdate(quaternion: Quaternion, viewMatrix: Matrix4): void;
}

/**
 * 传感器管理器配置
 */
export interface SensorManagerConfig {
  /** 传感器采样间隔，单位：纳秒。默认 16666667ns ≈ 60Hz */
  samplingInterval?: number;
  /** 设备持握模式 */
  holdMode?: DeviceHoldMode;
}

/**
 * 设备持握模式枚举
 */
export enum DeviceHoldMode {
  /** 横持模式 - 像望远镜一样横着拿手机 */
  LANDSCAPE_TELESCOPE = 'landscape_telescope',
  /** 竖持模式 - 正常竖着拿手机 */
  PORTRAIT = 'portrait',
  /** 平放模式 - 手机平放在桌面上，通过旋转控制视野 */
  FLAT = 'flat'
}

/**
 * SensorManager 类
 * 单例模式，管理旋转矢量传感器的订阅和数据处理
 */
export class SensorManager {
  private static instance: SensorManager | null = null;

  /** 当前设备姿态四元数 */
  private deviceQuaternion: Quaternion = new Quaternion();

  /** 处理后的 OpenGL 视图矩阵 */
  private viewMatrix: Matrix4 = new Matrix4();

  /** 数据监听器列表 */
  private listeners: SensorDataListener[] = [];

  /** 传感器是否正在运行 */
  private isRunning: boolean = false;

  /** 传感器采样间隔（纳秒） */
  private samplingInterval: number = 16666667; // 约 60Hz

  /** 设备持握模式 */
  private holdMode: DeviceHoldMode = DeviceHoldMode.LANDSCAPE_TELESCOPE;

  /**
   * 坐标系校正四元数
   * 用于将手机坐标系转换为眼镜视野坐标系
   */
  private coordinateRemapQuaternion: Quaternion = new Quaternion();

  /**
   * 私有构造函数（单例模式）
   */
  private constructor() {
    this.updateCoordinateRemapQuaternion();
  }

  /**
   * 获取 SensorManager 单例实例
   */
  public static getInstance(): SensorManager {
    if (!SensorManager.instance) {
      SensorManager.instance = new SensorManager();
    }
    return SensorManager.instance;
  }

  /**
   * 配置传感器管理器
   */
  public configure(config: SensorManagerConfig): void {
    if (config.samplingInterval !== undefined) {
      this.samplingInterval = config.samplingInterval;
    }
    if (config.holdMode !== undefined) {
      this.holdMode = config.holdMode;
      this.updateCoordinateRemapQuaternion();
    }
  }

  /**
   * 根据持握模式更新坐标系重映射四元数
   *
   * 关键转换逻辑：
   * 1. 设备坐标系 -> 世界坐标系（传感器已完成）
   * 2. 世界坐标系 -> OpenGL相机坐标系（需要考虑持握方式）
   */
  private updateCoordinateRemapQuaternion(): void {
    switch (this.holdMode) {
      case DeviceHoldMode.LANDSCAPE_TELESCOPE:
        // 横持模式（像望远镜）：
        // 用户将手机横着拿，屏幕顶部（原Y轴正方向）指向左侧
        // 需要：绕Z轴旋转-90度，使原Y轴变为新的X轴负方向
        // 然后：绕X轴旋转-90度，将坐标系从"平面朝上"转为"平面朝前"
        const rotZ = quaternionFromRotationZ(degToRad(-90)); // 横屏校正
        const rotX = quaternionFromRotationX(degToRad(-90)); // 视野方向校正
        this.coordinateRemapQuaternion.copy(rotX).multiply(rotZ);
        break;

      case DeviceHoldMode.PORTRAIT:
        // 竖持模式：
        // 只需要绕X轴旋转-90度，使手机屏幕正对的方向成为视野前方
        this.coordinateRemapQuaternion = quaternionFromRotationX(degToRad(-90));
        break;

      case DeviceHoldMode.FLAT:
        // 平放模式：
        // 手机屏幕朝上，用户环顾四周
        // 不需要额外旋转，Z轴已经指向上方
        this.coordinateRemapQuaternion = new Quaternion(0, 0, 0, 1); // 单位四元数
        break;
    }
  }

  /**
   * 添加传感器数据监听器
   */
  public addListener(listener: SensorDataListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  /**
   * 移除传感器数据监听器
   */
  public removeListener(listener: SensorDataListener): void {
    const index = this.listeners.indexOf(listener);
    if (index !== -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 启动传感器订阅
   */
  public start(): void {
    if (this.isRunning) {
      console.info('SensorManager: Sensor is already running');
      return;
    }

    try {
      sensor.on(sensor.SensorId.ROTATION_VECTOR, (data: sensor.RotationVectorResponse) => {
        this.onSensorData(data);
      }, { interval: this.samplingInterval });

      this.isRunning = true;
      console.info('SensorManager: Rotation vector sensor started');
    } catch (error) {
      console.error('SensorManager: Failed to start sensor', JSON.stringify(error));
    }
  }

  /**
   * 停止传感器订阅
   */
  public stop(): void {
    if (!this.isRunning) {
      console.info('SensorManager: Sensor is not running');
      return;
    }

    try {
      sensor.off(sensor.SensorId.ROTATION_VECTOR);
      this.isRunning = false;
      console.info('SensorManager: Rotation vector sensor stopped');
    } catch (error) {
      console.error('SensorManager: Failed to stop sensor', JSON.stringify(error));
    }
  }

  /**
   * 处理传感器原始数据
   * @param data 旋转矢量传感器数据
   */
  private onSensorData(data: sensor.RotationVectorResponse): void {
    // 鸿蒙旋转矢量传感器返回的四元数格式: (x, y, z, w)
    // 注意：某些平台可能返回 (w, x, y, z)，需要根据实际情况调整
    this.deviceQuaternion.set(data.x, data.y, data.z, data.w);
    this.deviceQuaternion.normalize();

    // 计算 OpenGL 视图矩阵
    this.computeViewMatrix();

    // 通知所有监听器
    this.notifyListeners();
  }

  /**
   * 计算 OpenGL 视图矩阵
   *
   * 视图矩阵的计算流程：
   * 1. 获取设备在世界坐标系中的姿态四元数 Q_device
   * 2. 应用坐标系重映射 Q_remap，得到相机姿态 Q_camera = Q_remap * Q_device
   * 3. 视图矩阵是相机姿态的逆矩阵（将世界坐标转换到相机坐标）
   * 4. 对于纯旋转四元数，逆矩阵等于共轭四元数对应的矩阵的转置
   */
  private computeViewMatrix(): void {
    // 创建工作用的临时四元数
    const cameraQuaternion = this.deviceQuaternion.clone();

    // 应用坐标系重映射
    // Q_camera = Q_remap * Q_device
    cameraQuaternion.premultiply(this.coordinateRemapQuaternion);

    // 计算相机姿态的逆（共轭）
    // 因为视图矩阵需要将世界坐标转换到相机坐标
    cameraQuaternion.conjugate();

    // 从四元数生成旋转矩阵
    this.viewMatrix.setFromQuaternion(cameraQuaternion);
  }

  /**
   * 通知所有监听器姿态数据已更新
   */
  private notifyListeners(): void {
    for (const listener of this.listeners) {
      listener.onOrientationUpdate(this.deviceQuaternion.clone(), this.viewMatrix.clone());
    }
  }

  /**
   * 获取当前设备姿态四元数（只读副本）
   */
  public getDeviceQuaternion(): Quaternion {
    return this.deviceQuaternion.clone();
  }

  /**
   * 获取当前 OpenGL 视图矩阵（只读副本）
   */
  public getViewMatrix(): Matrix4 {
    return this.viewMatrix.clone();
  }

  /**
   * 获取视图矩阵的 Float32Array 格式，可直接传递给 OpenGL uniform
   */
  public getViewMatrixArray(): Float32Array {
    return this.viewMatrix.toFloat32Array();
  }

  /**
   * 检查传感器是否正在运行
   */
  public isActive(): boolean {
    return this.isRunning;
  }

  /**
   * 设置持握模式
   */
  public setHoldMode(mode: DeviceHoldMode): void {
    this.holdMode = mode;
    this.updateCoordinateRemapQuaternion();
  }

  /**
   * 获取当前持握模式
   */
  public getHoldMode(): DeviceHoldMode {
    return this.holdMode;
  }
}

/**
 * 导出便捷的获取实例函数
 */
export function getSensorManager(): SensorManager {
  return SensorManager.getInstance();
}
