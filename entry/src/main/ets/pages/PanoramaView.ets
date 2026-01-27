/**
 * PanoramaView - 全景渲染视图页面（主控制页面）
 * 使用 XComponent 承载 OpenGL ES 渲染的 360° 全景
 * 支持视频播放和外部显示器输出
 * 使用 md360player 库进行全景视频渲染
 */

import { SensorManager, SensorDataListener, DeviceHoldMode, getSensorManager } from '../sensor/SensorManager';
import { GlassesImuManager, GlassesConnectionState, getGlassesImuManager } from '../sensor/GlassesImuManager';
import { Quaternion, Matrix4 } from '../utils/MathUtils';
import { SensorListenerImpl, ExternalDisplayListenerImpl, GlassesImuListenerImpl } from '../utils/ListenerImplementations';
import { ExternalDisplayManager, DisplayInfo, ExternalDisplayListener, DisplayType, getExternalDisplayManager } from '../display/ExternalDisplayManager';
import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { MDVRLibrary, IOnSurfaceReadyCallback, Context } from '@ohos/md360player';
import { media } from '@kit.MediaKit';

/**
 * 视频播放回调实现类
 * 实现 IOnSurfaceReadyCallback 接口，用于 md360player 库
 */
class VideoCallback implements IOnSurfaceReadyCallback {
  private avPlayer: media.AVPlayer | null = null;
  private videoUri: string = '';
  private surfaceId: string | null = null;
  private progressTimer: number | null = null;
  private onStateChanged: ((isPlaying: boolean) => void) | null = null;
  private onProgressChanged: ((currentTime: number, duration: number) => void) | null = null;

  setStateCallback(onStateChanged: (isPlaying: boolean) => void, 
                   onProgressChanged: (currentTime: number, duration: number) => void): void {
    this.onStateChanged = onStateChanged;
    this.onProgressChanged = onProgressChanged;
  }

  onSurfaceReady(surface: Object): void {
    console.log('VideoCallback: Surface ready');
  }

  async setSurfaceIdAndCreatePlayer(surfaceId: string): Promise<void> {
    if (!surfaceId || surfaceId === '0' || surfaceId === '') {
      console.error('VideoCallback: Invalid surfaceId:', surfaceId);
      return;
    }

    if (this.surfaceId === surfaceId) {
      console.log('VideoCallback: surfaceId already set:', surfaceId);
      return;
    }

    this.surfaceId = surfaceId;
    console.log('VideoCallback: Creating AVPlayer with surfaceId:', surfaceId);

    try {
      if (this.avPlayer !== null) {
        await this.avPlayer.release();
        this.avPlayer = null;
      }

      this.avPlayer = await media.createAVPlayer();
      if (this.avPlayer === null) {
        console.error('VideoCallback: Failed to create AVPlayer');
        return;
      }

      this.avPlayer.surfaceId = surfaceId;

      this.avPlayer.on('stateChange', (state: string) => {
        console.log('VideoCallback: AVPlayer state changed to:', state);
        if (state === 'playing') {
          this.onStateChanged?.(true);
          this.startProgressTimer();
        } else if (state === 'paused' || state === 'stopped') {
          this.onStateChanged?.(false);
          this.stopProgressTimer();
        }
      });

      if (this.videoUri) {
        this.avPlayer.url = this.videoUri;
      }

      console.log('VideoCallback: AVPlayer created successfully');
    } catch (error) {
      console.error('VideoCallback: Failed to create AVPlayer:', error);
    }
  }

  async setSource(uri: string): Promise<void> {
    this.videoUri = uri;
    if (this.avPlayer) {
      try {
        await this.avPlayer.reset();
        this.avPlayer.url = uri;
      } catch (error) {
        console.error('VideoCallback: Failed to set source:', error);
      }
    }
  }

  async play(): Promise<void> {
    if (this.avPlayer && (this.avPlayer.state === 'prepared' || this.avPlayer.state === 'paused')) {
      try {
        await this.avPlayer.play();
      } catch (error) {
        console.error('VideoCallback: Failed to play:', error);
      }
    }
  }

  async pause(): Promise<void> {
    if (this.avPlayer && this.avPlayer.state === 'playing') {
      try {
        await this.avPlayer.pause();
      } catch (error) {
        console.error('VideoCallback: Failed to pause:', error);
      }
    }
  }

  isPlaying(): boolean {
    return this.avPlayer?.state === 'playing';
  }

  private startProgressTimer(): void {
    this.stopProgressTimer();
    this.progressTimer = setInterval(() => {
      if (this.avPlayer && this.avPlayer.state === 'playing') {
        const currentTime = this.avPlayer.currentTime || 0;
        const duration = this.avPlayer.duration || 0;
        this.onProgressChanged?.(currentTime, duration);
      }
    }, 500);
  }

  private stopProgressTimer(): void {
    if (this.progressTimer !== null) {
      clearInterval(this.progressTimer);
      this.progressTimer = null;
    }
  }

  release(): void {
    this.stopProgressTimer();
    if (this.avPlayer) {
      this.avPlayer.release();
      this.avPlayer = null;
    }
  }
}

@Entry
@Component
struct PanoramaView {
  // XComponent 控制器
  private xComponentController: XComponentController = new XComponentController();

  // 管理器实例
  private sensorManager: SensorManager = getSensorManager();
  private displayManager: ExternalDisplayManager = getExternalDisplayManager();
  private glassesManager: GlassesImuManager = getGlassesImuManager();

  // md360player 相关
  private vrLibrary: MDVRLibrary | null = null;
  private vrContext: Context | null = null;
  private videoCallback: VideoCallback | null = null;

  // 上下文
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  // 渲染状态
  @State isRendering: boolean = false;
  @State rendererReady: boolean = false;

  // FOV 设置
  private readonly fovMin: number = 60;
  private readonly fovMax: number = 110;
  private readonly fovStep: number = 1;
  @State fovValue: number = 90;

  // 视频状态
  @State isPlaying: boolean = false;
  @State videoProgress: number = 0;
  @State videoDuration: number = 0;
  @State videoFileName: string = '未选择视频';

  // 外部显示器状态
  @State hasExternalDisplay: boolean = false;
  @State externalDisplayInfo: string = '未连接';
  @State isOutputToExternal: boolean = false;

  // 眼镜 IMU 状态
  @State glassesConnected: boolean = false;
  @State glassesStreaming: boolean = false;
  @State glassesName: string = '未知设备';

  // 帧率统计
  @State fps: number = 0;
  private frameCount: number = 0;
  private lastFpsTime: number = 0;

  // 触控手势
  private lastPanX: number | undefined = undefined;
  private lastPanY: number | undefined = undefined;

  // 监听器实例
  private sensorListener: SensorListenerImpl | null = null;
  private displayListener: ExternalDisplayListenerImpl | null = null;
  private glassesListener: GlassesImuListenerImpl | null = null;

  /**
   * 页面即将出现
   */
  aboutToAppear(): void {
    // 创建传感器监听器
    this.sensorListener = new SensorListenerImpl((quaternion: Quaternion, viewMatrix: Matrix4) => {
      if (this.vrLibrary && this.rendererReady) {
        // 将传感器数据传递给 md360player
        // md360player 使用四元数 (x, y, z, w) 进行视角控制
        const quat = quaternion.toArray();
        this.vrLibrary.updateGyroData(quat[0], quat[1], quat[2], quat[3]);
      }
    });

    // 创建外部显示器监听器
    this.displayListener = new ExternalDisplayListenerImpl(
      (displayInfo: DisplayInfo) => {
        this.hasExternalDisplay = true;
        this.externalDisplayInfo = `${displayInfo.name} (${displayInfo.width}x${displayInfo.height})`;
        console.info('PanoramaView: External display connected');
      },
      (displayId: number) => {
        this.hasExternalDisplay = this.displayManager.hasExternalDisplay();
        if (!this.hasExternalDisplay) {
          this.externalDisplayInfo = '未连接';
          this.isOutputToExternal = false;
        }
        console.info('PanoramaView: External display disconnected');
      },
      (displayInfo: DisplayInfo) => {
        if (displayInfo.type === DisplayType.EXTERNAL) {
          this.externalDisplayInfo = `${displayInfo.name} (${displayInfo.width}x${displayInfo.height})`;
        }
      }
    );

    // Glasses IMU listener
    this.glassesListener = new GlassesImuListenerImpl(
      (state: GlassesConnectionState) => {
        this.glassesConnected = state.connected && state.hasPermission;
        this.glassesStreaming = state.streaming;
        this.glassesName = state.deviceInfo ? state.deviceInfo.name : 'Unknown';

        if (this.isRendering) {
          if (state.connected && state.hasPermission) {
            this.sensorManager.stop();
            this.glassesManager.startImu();
          } else {
            this.glassesManager.stopImu();
            this.sensorManager.start();
          }
        }
      },
      (quaternion: Quaternion) => {
        this.sensorManager.updateFromQuaternion(quaternion);
      },
      (message: string) => {
        console.error('PanoramaView: Glasses IMU error', message);
      }
    );

    // 配置传感器
    this.sensorManager.configure({
      samplingInterval: 16666667,
      holdMode: DeviceHoldMode.LANDSCAPE_TELESCOPE
    });

    // 添加监听器
    this.sensorManager.addListener(this.sensorListener);
    this.displayManager.addListener(this.displayListener);
    if (this.glassesListener) {
      this.glassesManager.addListener(this.glassesListener);
    }

    // 设置上下文
    this.displayManager.setContext(this.context);

    this.glassesManager.initialize();

    // 初始化管理器
    this.initializeManagers();
  }

  /**
   * 页面即将消失
   */
  aboutToDisappear(): void {
    this.stopRendering();
    this.sensorManager.stop();
    
    if (this.sensorListener) {
      this.sensorManager.removeListener(this.sensorListener);
    }
    if (this.displayListener) {
      this.displayManager.removeListener(this.displayListener);
    }
    if (this.glassesListener) {
      this.glassesManager.removeListener(this.glassesListener);
    }
    
    this.glassesManager.stopImu();
    this.glassesManager.stopMonitoring();
    this.displayManager.closeExternalWindow();
    
    // 释放 md360player 资源
    if (this.videoCallback) {
      this.videoCallback.release();
      this.videoCallback = null;
    }
    if (this.vrLibrary) {
      this.vrLibrary.onDestroy();
      this.vrLibrary = null;
    }
  }

  /**
   * 初始化管理器
   */
  private async initializeManagers(): Promise<void> {
    // 初始化外部显示器管理器
    await this.displayManager.initialize();
    this.hasExternalDisplay = this.displayManager.hasExternalDisplay();

    if (this.hasExternalDisplay) {
      const extDisplay = this.displayManager.getFirstExternalDisplay();
      if (extDisplay) {
        this.externalDisplayInfo = `${extDisplay.name} (${extDisplay.width}x${extDisplay.height})`;
      }
    }
  }

  /**
   * 初始化 VR 库
   */
  private async initVR(surfaceId: string): Promise<void> {
    console.info('PanoramaView: Initializing VR with surfaceId:', surfaceId);

    // 创建视频回调
    this.videoCallback = new VideoCallback();
    this.videoCallback.setStateCallback(
      (isPlaying: boolean) => {
        this.isPlaying = isPlaying;
      },
      (currentTime: number, duration: number) => {
        this.videoProgress = currentTime;
        this.videoDuration = duration;
      }
    );

    // 创建 VR Context
    this.vrContext = new Context();

    // 构建 MDVRLibrary
    const builder = MDVRLibrary.with(this.vrContext)
      .displayMode(MDVRLibrary.DISPLAY_MODE_NORMAL)
      .interactiveMode(MDVRLibrary.INTERACTIVE_MODE_MOTION_WITH_TOUCH)
      .asVideo(this.videoCallback);

    this.vrLibrary = builder.build(this.xComponentController);

    // 通知 Surface 就绪
    this.vrLibrary.onSurfaceReady(surfaceId);

    // 获取视频 Surface ID 并创建播放器
    setTimeout(async () => {
      if (!this.vrLibrary || !this.videoCallback) {
        return;
      }

      const videoSurfaceId = this.vrLibrary.getVideoSurfaceId();
      console.info('PanoramaView: Got video surfaceId:', videoSurfaceId);

      if (videoSurfaceId && videoSurfaceId !== '' && videoSurfaceId !== '0') {
        await this.videoCallback.setSurfaceIdAndCreatePlayer(videoSurfaceId);
        this.rendererReady = true;
        console.info('PanoramaView: Renderer ready');
      } else {
        console.error('PanoramaView: Invalid video surfaceId');
      }
    }, 500);
  }

  /**
   * 开始渲染循环
   */
  private startRendering(): void {
    if (this.isRendering) return;

    this.isRendering = true;
    if (this.glassesConnected) {
      this.glassesManager.startImu();
    } else {
      this.sensorManager.start();
    }
    this.lastFpsTime = Date.now();
    this.frameCount = 0;
  }

  /**
   * 停止渲染循环
   */
  private stopRendering(): void {
    this.isRendering = false;
    this.glassesManager.stopImu();
    this.sensorManager.stop();
  }

  /**
   * 选择视频文件
   */
  private async selectVideo(): Promise<void> {
    try {
      const documentViewPicker = new picker.DocumentViewPicker(this.context);
      const uris = await documentViewPicker.select({
        maxSelectNumber: 1,
        selectMode: picker.DocumentSelectMode.FILE,
        fileSuffixFilters: ['.mp4', '.mov', '.webm', '.avi']
      });

      if (uris.length > 0) {
        const videoUri = uris[0];
        const parts = videoUri.split('/');
        this.videoFileName = parts[parts.length - 1] || '视频文件';

        if (this.videoCallback) {
          await this.videoCallback.setSource(videoUri);
        }
        console.info('PanoramaView: Video selected', videoUri);
      }
    } catch (error) {
      console.error('PanoramaView: Failed to select video', JSON.stringify(error));
    }
  }

  /**
   * 播放/暂停视频
   */
  private async toggleVideoPlayback(): Promise<void> {
    if (!this.videoCallback) {
      return;
    }

    if (this.videoCallback.isPlaying()) {
      await this.videoCallback.pause();
    } else {
      await this.videoCallback.play();
    }
  }

  /**
   * 切换外部显示器输出
   */
  private async toggleExternalOutput(): Promise<void> {
    if (!this.hasExternalDisplay) {
      console.warn('PanoramaView: No external display available');
      return;
    }

    if (this.isOutputToExternal) {
      await this.displayManager.closeExternalWindow();
      this.isOutputToExternal = false;
    } else {
      const extDisplay = this.displayManager.getFirstExternalDisplay();
      if (extDisplay) {
        const windowResult = await this.displayManager.createWindowOnExternalDisplay(
          extDisplay.id,
          'pages/ExternalPanoramaView'
        );
        this.isOutputToExternal = windowResult !== null;
      }
    }
  }

  /**
   * XComponent 加载完成回调
   */
  private async onXComponentLoad(): Promise<void> {
    console.info('PanoramaView: XComponent loaded');

    const surfaceId = this.xComponentController.getXComponentSurfaceId();
    await this.initVR(surfaceId);
  }

  /**
   * XComponent 销毁回调
   */
  private onXComponentDestroy(): void {
    console.info('PanoramaView: XComponent destroyed');
    this.rendererReady = false;
    this.stopRendering();
  }

  /**
   * 应用当前 FOV
   */
  private applyFov(): void {
    // md360player 的 FOV 控制由内部处理，这里保留接口以备后续扩展
    console.info('PanoramaView: FOV set to', this.fovValue);
  }

  /**
   * 格式化时间显示
   */
  private formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }

  build() {
    Stack() {
      // 全景渲染视图
      XComponent({
        id: 'panoramaXComponent',
        type: XComponentType.SURFACE,
        libraryname: 'md360player',
        controller: this.xComponentController
      })
        .onLoad(() => this.onXComponentLoad())
        .onDestroy(() => this.onXComponentDestroy())
        .width('100%')
        .height('100%')
        .gesture(
          PanGesture({ fingers: 1, direction: PanDirection.All, distance: 1 })
            .onActionStart((event: GestureEvent) => {
              this.lastPanX = event.offsetX;
              this.lastPanY = event.offsetY;
            })
            .onActionUpdate((event: GestureEvent) => {
              if (this.lastPanX !== undefined && this.lastPanY !== undefined && this.vrLibrary) {
                const distanceX = event.offsetX - this.lastPanX;
                const distanceY = event.offsetY - this.lastPanY;
                this.vrLibrary.onDrag(distanceX, distanceY);
                this.lastPanX = event.offsetX;
                this.lastPanY = event.offsetY;
              }
            })
            .onActionEnd(() => {
              this.lastPanX = undefined;
              this.lastPanY = undefined;
            })
        )

      // 控制面板
      Column() {
        // 顶部状态栏
        Row() {
          // 渲染状态
          Row() {
            Circle()
              .width(10)
              .height(10)
              .fill(this.isRendering ? '#4CAF50' : '#757575')
            Text(this.isRendering ? 'LIVE' : 'PAUSED')
              .fontSize(12)
              .fontColor('#FFFFFF')
              .margin({ left: 6 })
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('rgba(0, 0, 0, 0.6)')
          .borderRadius(16)

          Blank()

          // 外部显示器状态
          // Glasses IMU status
          Row() {
            Circle()
              .width(10)
              .height(10)
              .fill(this.glassesConnected ? (this.glassesStreaming ? '#4CAF50' : '#FFC107') : '#757575')
            Text(this.glassesConnected ? `${this.glassesName} IMU` : 'IMU Disconnected')
              .fontSize(12)
              .fontColor(this.glassesConnected ? '#4CAF50' : '#757575')
              .margin({ left: 6 })
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('rgba(0, 0, 0, 0.6)')
          .borderRadius(16)

          Blank()

          // FPS
          Text(`${this.fps} FPS`)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('rgba(0, 0, 0, 0.6)')
            .borderRadius(16)
        }
        .width('100%')
        .padding(12)

        Blank()

        // 底部控制面板
        Column() {
          // 视频信息栏
          Row() {
            Text(`📹 ${this.videoFileName}`)
              .fontSize(12)
              .fontColor('#B0BEC5')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            Text(`${this.formatTime(this.videoProgress)} / ${this.formatTime(this.videoDuration)}`)
              .fontSize(12)
              .fontColor('#78909C')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })

          // 视频进度条
          if (this.videoDuration > 0) {
            Progress({
              value: this.videoProgress,
              total: this.videoDuration,
              type: ProgressType.Linear
            })
              .width('90%')
              .height(4)
              .color('#2196F3')
              .margin({ bottom: 12 })
          }

          // 控制按钮第一行（视频控制）
          Row() {
            Button('📂 选择视频')
              .fontSize(13)
              .height(40)
              .layoutWeight(1)
              .backgroundColor('rgba(33, 150, 243, 0.8)')
              .margin({ right: 8 })
              .onClick(() => this.selectVideo())

            Button(this.isPlaying ? '⏸ 暂停' : '▶ 播放')
              .fontSize(13)
              .height(40)
              .layoutWeight(1)
              .backgroundColor(this.isPlaying ?
                'rgba(255, 152, 0, 0.8)' : 'rgba(76, 175, 80, 0.8)')
              .onClick(() => this.toggleVideoPlayback())
          }
          .width('90%')
          .margin({ bottom: 8 })

          // 控制按钮第二行（渲染控制）
          Row() {
            Button(this.isRendering ? '⏹ 停止渲染' : '▶ 开始渲染')
              .fontSize(13)
              .height(40)
              .layoutWeight(1)
              .backgroundColor(this.isRendering ?
                'rgba(244, 67, 54, 0.8)' : 'rgba(76, 175, 80, 0.8)')
              .onClick(() => {
                if (this.isRendering) {
                  this.stopRendering();
                } else {
                  this.startRendering();
                }
              })
          }
          .width('90%')
          .margin({ bottom: 8 })

          // FOV 滑块
          Column() {
            Text(`🔭 FOV ${this.fovValue}°`)
              .fontSize(12)
              .fontColor('#B0BEC5')
              .margin({ bottom: 6 })

            Slider({
              value: this.fovValue,
              min: this.fovMin,
              max: this.fovMax,
              step: this.fovStep
            })
              .width('90%')
              .onChange((value: number) => {
                this.fovValue = Math.round(value);
                this.applyFov();
              })
          }
          .width('90%')
          .margin({ bottom: 8 })

          // 控制按钮第三行（外部显示器）
          if (this.hasExternalDisplay) {
            Button(this.isOutputToExternal ? '🔴 停止眼镜输出' : '🥽 输出到眼镜')
              .fontSize(13)
              .height(40)
              .width('90%')
              .backgroundColor(this.isOutputToExternal ?
                'rgba(244, 67, 54, 0.8)' : 'rgba(0, 150, 136, 0.8)')
              .margin({ bottom: 8 })
              .onClick(() => this.toggleExternalOutput())
          }

          // 外部显示器信息
          Text(`外部显示器: ${this.externalDisplayInfo}`)
            .fontSize(11)
            .fontColor('#546E7A')
            .margin({ bottom: 16 })
        }
        .width('100%')
        .padding({ bottom: 16 })
        .backgroundColor('rgba(0, 0, 0, 0.7)')
        .borderRadius({ topLeft: 20, topRight: 20 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
