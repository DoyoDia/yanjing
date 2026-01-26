/**
 * ListenerImplementations - 监听器接口的具体实现类
 * 用于解决 ArkTS 不支持匿名对象字面量的问题
 */

import { Quaternion, Matrix4 } from './MathUtils';
import { SensorDataListener } from '../sensor/SensorManager';
import { GlassesImuListener, GlassesConnectionState } from '../sensor/GlassesImuManager';
import { ExternalDisplayListener, DisplayInfo, DisplayType } from '../display/ExternalDisplayManager';
import { VideoFrameListener, VideoPlayerState } from '../video/VideoPlayerManager';
import { image } from '@kit.ImageKit';

/**
 * 传感器数据监听器实现类
 */
export class SensorListenerImpl implements SensorDataListener {
  private callback: (quaternion: Quaternion, viewMatrix: Matrix4) => void;

  constructor(callback: (quaternion: Quaternion, viewMatrix: Matrix4) => void) {
    this.callback = callback;
  }

  onOrientationUpdate(quaternion: Quaternion, viewMatrix: Matrix4): void {
    this.callback(quaternion, viewMatrix);
  }
}

/**
 * 外部显示器监听器实现类
 */
export class ExternalDisplayListenerImpl implements ExternalDisplayListener {
  private onConnected: (displayInfo: DisplayInfo) => void;
  private onDisconnected: (displayId: number) => void;
  private onChanged: (displayInfo: DisplayInfo) => void;

  constructor(
    onConnected: (displayInfo: DisplayInfo) => void,
    onDisconnected: (displayId: number) => void,
    onChanged: (displayInfo: DisplayInfo) => void
  ) {
    this.onConnected = onConnected;
    this.onDisconnected = onDisconnected;
    this.onChanged = onChanged;
  }

  onExternalDisplayConnected(displayInfo: DisplayInfo): void {
    this.onConnected(displayInfo);
  }

  onExternalDisplayDisconnected(displayId: number): void {
    this.onDisconnected(displayId);
  }

  onDisplayChanged(displayInfo: DisplayInfo): void {
    this.onChanged(displayInfo);
  }
}

/**
 * 视频帧监听器实现类
 */
export class VideoFrameListenerImpl implements VideoFrameListener {
  private onFrame: (pixelMap: image.PixelMap, width: number, height: number) => void;
  private onState: (state: VideoPlayerState) => void;
  private onProgress: (currentTime: number, duration: number) => void;

  constructor(
    onFrame: (pixelMap: image.PixelMap, width: number, height: number) => void,
    onState: (state: VideoPlayerState) => void,
    onProgress: (currentTime: number, duration: number) => void
  ) {
    this.onFrame = onFrame;
    this.onState = onState;
    this.onProgress = onProgress;
  }

  onFrameAvailable(pixelMap: image.PixelMap, width: number, height: number): void {
    this.onFrame(pixelMap, width, height);
  }

  onStateChanged(state: VideoPlayerState): void {
    this.onState(state);
  }

  onProgressUpdate(currentTime: number, duration: number): void {
    this.onProgress(currentTime, duration);
  }
}

/**
 * 眼镜 IMU 监听器实现类
 */
export class GlassesImuListenerImpl implements GlassesImuListener {
  private onConnection: (state: GlassesConnectionState) => void;
  private onQuaternion: (quaternion: Quaternion) => void;
  private onErrorCallback: (message: string, code?: number) => void;

  constructor(
    onConnection: (state: GlassesConnectionState) => void,
    onQuaternion: (quaternion: Quaternion) => void,
    onErrorCallback: (message: string, code?: number) => void
  ) {
    this.onConnection = onConnection;
    this.onQuaternion = onQuaternion;
    this.onErrorCallback = onErrorCallback;
  }

  onConnectionChanged(state: GlassesConnectionState): void {
    this.onConnection(state);
  }

  onImuQuaternion(quaternion: Quaternion): void {
    this.onQuaternion(quaternion);
  }

  onError(message: string, code?: number): void {
    this.onErrorCallback(message, code);
  }
}
