/**
 * VideoPlayerManager - 360°全景视频播放器管理模块
 * 负责视频解码和纹理更新
 */

import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';

/**
 * 视频播放状态
 */
export enum VideoPlayerState {
  IDLE = 'idle',
  INITIALIZED = 'initialized',
  PREPARED = 'prepared',
  PLAYING = 'playing',
  PAUSED = 'paused',
  STOPPED = 'stopped',
  COMPLETED = 'completed',
  ERROR = 'error'
}

/**
 * 视频帧回调接口
 */
export interface VideoFrameListener {
  /**
   * 当新的视频帧可用时调用
   * @param pixelMap 视频帧像素数据
   * @param width 帧宽度
   * @param height 帧高度
   */
  onFrameAvailable(pixelMap: image.PixelMap, width: number, height: number): void;

  /**
   * 当播放状态改变时调用
   */
  onStateChanged(state: VideoPlayerState): void;

  /**
   * 当播放进度更新时调用
   * @param currentTime 当前播放时间（毫秒）
   * @param duration 总时长（毫秒）
   */
  onProgressUpdate(currentTime: number, duration: number): void;
}

/**
 * 视频播放器管理器
 */
export class VideoPlayerManager {
  private static instance: VideoPlayerManager | null = null;

  // AVPlayer 实例
  private avPlayer: media.AVPlayer | null = null;

  // 播放状态
  private state: VideoPlayerState = VideoPlayerState.IDLE;

  // 监听器列表
  private listeners: VideoFrameListener[] = [];

  // 视频信息
  private videoWidth: number = 0;
  private videoHeight: number = 0;
  private duration: number = 0;

  // 是否循环播放
  private looping: boolean = true;

  // 上下文
  private context: common.UIAbilityContext | null = null;

  // 待处理的 SurfaceId (延迟绑定)
  private pendingSurfaceId: string = '';

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): VideoPlayerManager {
    if (!VideoPlayerManager.instance) {
      VideoPlayerManager.instance = new VideoPlayerManager();
    }
    return VideoPlayerManager.instance;
  }

  /**
   * 设置上下文
   */
  public setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * 初始化播放器
   */
  public async initialize(): Promise<boolean> {
    try {
      // 创建 AVPlayer 实例
      this.avPlayer = await media.createAVPlayer();

      // 注册回调
      this.registerCallbacks();

      this.state = VideoPlayerState.IDLE;
      this.notifyStateChanged();

      console.info('VideoPlayerManager: Initialized successfully');
      return true;
    } catch (error) {
      console.error('VideoPlayerManager: Failed to initialize', JSON.stringify(error));
      this.state = VideoPlayerState.ERROR;
      this.notifyStateChanged();
      return false;
    }
  }

  /**
   * 设置渲染 Surface ID
   * 必须在 initialize 之后，prepared 之前调用
   */
  public async setSurfaceId(surfaceId: string): Promise<void> {
    if (!this.avPlayer) return;
    
    this.pendingSurfaceId = surfaceId;

    // 只有在 INITIALIZED 状态下才尝试设置 SurfaceId
    // 如果当前是 IDLE (刚创建) 或其他状态，等待进入 INITIALIZED 后再设置
    if (this.state === VideoPlayerState.INITIALIZED) {
        try {
            this.avPlayer.surfaceId = surfaceId;
            console.info(`VideoPlayerManager: SurfaceId set to ${surfaceId}`);
            // 清除 pending，避免重复设置
            this.pendingSurfaceId = ''; 
        } catch (error) {
            console.error('VideoPlayerManager: Failed to set SurfaceId', JSON.stringify(error));
        }
    } else {
        console.info(`VideoPlayerManager: SurfaceId ${surfaceId} pending, waiting for INITIALIZED state`);
    }
  }

  /**
   * 注册 AVPlayer 回调
   */
  private registerCallbacks(): void {
    if (!this.avPlayer) return;

    // 状态变化回调
    this.avPlayer.on('stateChange', (state: string, reason: media.StateChangeReason) => {
      console.info(`VideoPlayerManager: State changed to ${state}, reason: ${reason}`);

      switch (state) {
        case 'idle':
          this.state = VideoPlayerState.IDLE;
          break;
        case 'initialized':
          this.state = VideoPlayerState.INITIALIZED;
          
          // 如果有待处理的 SurfaceId，现在设置
          if (this.pendingSurfaceId && this.pendingSurfaceId.length > 0) {
            try {
               this.avPlayer!.surfaceId = this.pendingSurfaceId;
               console.info(`VideoPlayerManager: Pending SurfaceId set to ${this.pendingSurfaceId}`);
               this.pendingSurfaceId = ''; // 清除
            } catch (error) {
               console.error('VideoPlayerManager: Failed to set pending SurfaceId', JSON.stringify(error));
            }
          }

          // 准备播放
          this.avPlayer?.prepare();
          break;
        case 'prepared':
          this.state = VideoPlayerState.PREPARED;
          // 获取视频信息
          this.videoWidth = this.avPlayer?.width || 0;
          this.videoHeight = this.avPlayer?.height || 0;
          this.duration = this.avPlayer?.duration || 0;
          console.info(`VideoPlayerManager: Video info - ${this.videoWidth}x${this.videoHeight}, duration: ${this.duration}ms`);
          break;
        case 'playing':
          this.state = VideoPlayerState.PLAYING;
          break;
        case 'paused':
          this.state = VideoPlayerState.PAUSED;
          break;
        case 'stopped':
          this.state = VideoPlayerState.STOPPED;
          break;
        case 'completed':
          this.state = VideoPlayerState.COMPLETED;
          // 循环播放
          if (this.looping) {
            this.avPlayer?.seek(0);
            this.avPlayer?.play();
          }
          break;
        case 'error':
          this.state = VideoPlayerState.ERROR;
          break;
      }

      this.notifyStateChanged();
    });

    // 错误回调
    this.avPlayer.on('error', (error: BusinessError) => {
      console.error(`VideoPlayerManager: Error - code: ${error.code}, message: ${error.message}`);
      this.state = VideoPlayerState.ERROR;
      this.notifyStateChanged();
    });

    // 时间更新回调
    this.avPlayer.on('timeUpdate', (time: number) => {
      this.notifyProgressUpdate(time, this.duration);
    });

    // seek 完成回调
    this.avPlayer.on('seekDone', (seekTime: number) => {
      console.info(`VideoPlayerManager: Seek done to ${seekTime}ms`);
    });
  }

  /**
   * 设置视频源（文件路径）
   * @param filePath 视频文件路径 (fd://xxx 或 file://xxx)
   */
  public async setSource(filePath: string): Promise<boolean> {
    if (!this.avPlayer) {
      console.error('VideoPlayerManager: Player not initialized');
      return false;
    }

    try {
      // 检查是否为 file:// 路径
      if (filePath.startsWith('file://')) {
        const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
        this.avPlayer.fdSrc = {
          fd: file.fd
        };
        console.info(`VideoPlayerManager: FD Source set for ${filePath}`);
      } else {
        this.avPlayer.url = filePath;
        console.info(`VideoPlayerManager: URL Source set to ${filePath}`);
      }
      return true;
    } catch (error) {
      console.error('VideoPlayerManager: Failed to set source', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 设置视频源（从 rawfile）
   * @param rawFileName rawfile 目录下的文件名
   */
  public async setSourceFromRawFile(rawFileName: string): Promise<boolean> {
    if (!this.avPlayer || !this.context) {
      console.error('VideoPlayerManager: Player or context not initialized');
      return false;
    }

    try {
      // 获取 rawfile 的文件描述符
      const resourceMgr = this.context.resourceManager;
      const rawFd = await resourceMgr.getRawFd(rawFileName);

      // 使用 fdSrc 设置数据源
      this.avPlayer.fdSrc = {
        fd: rawFd.fd,
        offset: rawFd.offset,
        length: rawFd.length
      };

      console.info(`VideoPlayerManager: Source set from rawfile: ${rawFileName}`);
      return true;
    } catch (error) {
      console.error('VideoPlayerManager: Failed to set source from rawfile', JSON.stringify(error));
      return false;
    }
  }

  /**
   * 开始播放
   */
  public async play(): Promise<void> {
    if (!this.avPlayer) return;

    try {
      if (this.state === VideoPlayerState.PREPARED ||
          this.state === VideoPlayerState.PAUSED ||
          this.state === VideoPlayerState.COMPLETED) {
        await this.avPlayer.play();
      }
    } catch (error) {
      console.error('VideoPlayerManager: Failed to play', JSON.stringify(error));
    }
  }

  /**
   * 暂停播放
   */
  public async pause(): Promise<void> {
    if (!this.avPlayer) return;

    try {
      if (this.state === VideoPlayerState.PLAYING) {
        await this.avPlayer.pause();
      }
    } catch (error) {
      console.error('VideoPlayerManager: Failed to pause', JSON.stringify(error));
    }
  }

  /**
   * 停止播放
   */
  public async stop(): Promise<void> {
    if (!this.avPlayer) return;

    try {
      await this.avPlayer.stop();
    } catch (error) {
      console.error('VideoPlayerManager: Failed to stop', JSON.stringify(error));
    }
  }

  /**
   * 跳转到指定位置
   * @param time 目标时间（毫秒）
   */
  public async seek(time: number): Promise<void> {
    if (!this.avPlayer) return;

    try {
      await this.avPlayer.seek(time, media.SeekMode.SEEK_PREV_SYNC);
    } catch (error) {
      console.error('VideoPlayerManager: Failed to seek', JSON.stringify(error));
    }
  }

  /**
   * 设置是否循环播放
   */
  public setLooping(looping: boolean): void {
    this.looping = looping;
  }

  /**
   * 释放资源
   */
  public async release(): Promise<void> {
    if (!this.avPlayer) return;

    try {
      await this.avPlayer.release();
      this.avPlayer = null;
      this.state = VideoPlayerState.IDLE;
      console.info('VideoPlayerManager: Released');
    } catch (error) {
      console.error('VideoPlayerManager: Failed to release', JSON.stringify(error));
    }
  }

  /**
   * 添加监听器
   */
  public addListener(listener: VideoFrameListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  /**
   * 移除监听器
   */
  public removeListener(listener: VideoFrameListener): void {
    const index = this.listeners.indexOf(listener);
    if (index !== -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 获取当前状态
   */
  public getState(): VideoPlayerState {
    return this.state;
  }

  /**
   * 获取视频宽度
   */
  public getVideoWidth(): number {
    return this.videoWidth;
  }

  /**
   * 获取视频高度
   */
  public getVideoHeight(): number {
    return this.videoHeight;
  }

  /**
   * 获取视频时长
   */
  public getDuration(): number {
    return this.duration;
  }

  /**
   * 通知状态变化
   */
  private notifyStateChanged(): void {
    for (const listener of this.listeners) {
      listener.onStateChanged(this.state);
    }
  }

  /**
   * 通知进度更新
   */
  private notifyProgressUpdate(currentTime: number, duration: number): void {
    for (const listener of this.listeners) {
      listener.onProgressUpdate(currentTime, duration);
    }
  }

  /**
   * 获取 AVPlayer 实例（用于绑定 Surface）
   */
  public getAVPlayer(): media.AVPlayer | null {
    return this.avPlayer;
  }
}

/**
 * 便捷获取实例函数
 */
export function getVideoPlayerManager(): VideoPlayerManager {
  return VideoPlayerManager.getInstance();
}
