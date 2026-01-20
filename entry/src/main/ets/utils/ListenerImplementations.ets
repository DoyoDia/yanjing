/**
 * ListenerImplementations - 监听器接口的具体实现类
 * 用于解决 ArkTS 不支持匿名对象字面量的问题
 */

import { Quaternion, Matrix4 } from './MathUtils';
import { SensorDataListener } from '../sensor/SensorManager';
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
