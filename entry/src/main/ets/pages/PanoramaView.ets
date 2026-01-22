/**
 * PanoramaView - 全景渲染视图页面（主控制页面）
 * 使用 XComponent 承载 OpenGL ES 渲染的 360° 全景
 * 支持视频播放和外部显示器输出
 */

import { SensorManager, SensorDataListener, DeviceHoldMode, getSensorManager } from '../sensor/SensorManager';
import { Quaternion, Matrix4 } from '../utils/MathUtils';
import { SensorListenerImpl, ExternalDisplayListenerImpl, VideoFrameListenerImpl } from '../utils/ListenerImplementations';
import { VideoPlayerManager, VideoPlayerState, VideoFrameListener, getVideoPlayerManager } from '../video/VideoPlayerManager';
import { ExternalDisplayManager, DisplayInfo, ExternalDisplayListener, DisplayType, getExternalDisplayManager } from '../display/ExternalDisplayManager';
import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import panoramaRenderer from 'libpanorama_renderer.so';

@Entry
@Component
struct PanoramaView {
  // XComponent 控制器
  private xComponentController: XComponentController = new XComponentController();

  // 管理器实例
  private sensorManager: SensorManager = getSensorManager();
  private videoManager: VideoPlayerManager = getVideoPlayerManager();
  private displayManager: ExternalDisplayManager = getExternalDisplayManager();

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

  // 触控拖动视角
  private isTouching: boolean = false;
  private lastTouchX: number = 0;
  private lastTouchY: number = 0;
  private dragYaw: number = 0;   // 弧度
  private dragPitch: number = 0; // 弧度
  private readonly dragSensitivity: number = 0.003;
  private readonly maxPitch: number = Math.PI / 2 - 0.01;

  // 视频状态
  @State videoState: string = 'idle';
  @State videoProgress: number = 0;
  @State videoDuration: number = 0;
  @State videoFileName: string = '未选择视频';

  // 外部显示器状态
  @State hasExternalDisplay: boolean = false;
  @State externalDisplayInfo: string = '未连接';
  @State isOutputToExternal: boolean = false;

  // 渲染循环定时器 ID
  private renderTimerId: number = -1;

  // 帧率统计
  @State fps: number = 0;
  private frameCount: number = 0;
  private lastFpsTime: number = 0;

  // 监听器实例
  private sensorListener: SensorListenerImpl | null = null;
  private displayListener: ExternalDisplayListenerImpl | null = null;
  private videoListener: VideoFrameListenerImpl | null = null;

  /**
   * 页面即将出现
   */
  aboutToAppear(): void {
    // 创建传感器监听器
    this.sensorListener = new SensorListenerImpl((quaternion: Quaternion, viewMatrix: Matrix4) => {
      if (this.rendererReady) {
        const adjustedMatrix = this.applyDragToViewMatrix(viewMatrix);
        panoramaRenderer.setViewMatrix(adjustedMatrix.toFloat32Array());
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

    // 创建视频播放监听器
    this.videoListener = new VideoFrameListenerImpl(
      (pixelMap: image.PixelMap, width: number, height: number) => {
        // 帧数据可用时的处理
      },
      (state: VideoPlayerState) => {
        this.videoState = state;
      },
      (currentTime: number, duration: number) => {
        this.videoProgress = currentTime;
        this.videoDuration = duration;
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
    this.videoManager.addListener(this.videoListener);

    // 设置上下文
    this.videoManager.setContext(this.context);
    this.displayManager.setContext(this.context);

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
    if (this.videoListener) {
      this.videoManager.removeListener(this.videoListener);
    }
    this.displayManager.closeExternalWindow();
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

    // 初始化视频播放器
    await this.videoManager.initialize();
  }

  /**
   * 开始渲染循环
   */
  private startRendering(): void {
    if (this.isRendering) return;

    this.isRendering = true;
    this.sensorManager.start();
    this.lastFpsTime = Date.now();
    this.frameCount = 0;

    // 使用 setInterval 替代 requestAnimationFrame（约60fps）
    this.renderTimerId = setInterval(() => {
      if (!this.isRendering || !this.rendererReady) return;

      panoramaRenderer.render();

      this.frameCount++;
      const now = Date.now();
      if (now - this.lastFpsTime >= 1000) {
        this.fps = this.frameCount;
        this.frameCount = 0;
        this.lastFpsTime = now;
      }
    }, 16);
  }

  /**
   * 停止渲染循环
   */
  private stopRendering(): void {
    this.isRendering = false;
    if (this.renderTimerId !== -1) {
      clearInterval(this.renderTimerId);
      this.renderTimerId = -1;
    }
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

        await this.videoManager.setSource(videoUri);
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
    const state = this.videoManager.getState();
    if (state === VideoPlayerState.PLAYING) {
      await this.videoManager.pause();
    } else {
      await this.videoManager.play();
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
  private onXComponentLoad(): void {
    console.info('PanoramaView: XComponent loaded');

    setTimeout(async () => {
      if (panoramaRenderer.isInitialized()) {
        this.rendererReady = true;
        panoramaRenderer.setStereoMode(false);
        this.applyFov();
        
        // 获取 SurfaceId 并设置给视频播放器
        const surfaceId = panoramaRenderer.getSurfaceId();
        if (surfaceId && surfaceId.length > 0) {
          await this.videoManager.setSurfaceId(surfaceId);
          console.info(`PanoramaView: SurfaceId bound to player: ${surfaceId}`);
        } else {
          console.error('PanoramaView: Failed to get SurfaceId from renderer');
        }

        console.info('PanoramaView: Renderer ready');
      } else {
        console.error('PanoramaView: Renderer failed to initialize');
      }
    }, 100);
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
    const fov = this.fovValue;
    if (this.rendererReady) {
      panoramaRenderer.setFOV(fov);
    }
  }

  /**
   * 将触控拖动叠加到传感器视图矩阵
   */
  private applyDragToViewMatrix(viewMatrix: Matrix4): Matrix4 {
    if (this.dragYaw === 0 && this.dragPitch === 0) {
      return viewMatrix;
    }

    const dragQuaternion = new Quaternion().setFromEulerZYX(this.dragYaw, this.dragPitch, 0);
    dragQuaternion.conjugate();

    const dragMatrix = new Matrix4().setFromQuaternion(dragQuaternion);
    return new Matrix4().multiplyMatrices(dragMatrix, viewMatrix);
  }

  /**
   * 触控拖动处理
   */
  private handleTouch(event: TouchEvent): void {
    if (event.touches.length === 0) {
      return;
    }

    const touch = event.touches[0];

    if (event.type === TouchType.Down) {
      this.isTouching = true;
      this.lastTouchX = touch.x;
      this.lastTouchY = touch.y;
      return;
    }

    if (event.type === TouchType.Move && this.isTouching) {
      const dx = touch.x - this.lastTouchX;
      const dy = touch.y - this.lastTouchY;
      this.lastTouchX = touch.x;
      this.lastTouchY = touch.y;

      this.dragYaw += dx * this.dragSensitivity;
      this.dragPitch += dy * this.dragSensitivity;

      if (this.dragPitch > this.maxPitch) {
        this.dragPitch = this.maxPitch;
      } else if (this.dragPitch < -this.maxPitch) {
        this.dragPitch = -this.maxPitch;
      }
      return;
    }

    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.isTouching = false;
    }
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
        libraryname: 'panorama_renderer',
        controller: this.xComponentController
      })
        .onLoad(() => this.onXComponentLoad())
        .onDestroy(() => this.onXComponentDestroy())
        .onTouch((event: TouchEvent) => this.handleTouch(event))
        .width('100%')
        .height('100%')

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
          Row() {
            Text(this.hasExternalDisplay ? '🥽' : '📱')
              .fontSize(14)
            Text(this.hasExternalDisplay ? '眼镜已连接' : '未连接眼镜')
              .fontSize(12)
              .fontColor(this.hasExternalDisplay ? '#4CAF50' : '#757575')
              .margin({ left: 4 })
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

            Button(this.videoState === VideoPlayerState.PLAYING ? '⏸ 暂停' : '▶ 播放')
              .fontSize(13)
              .height(40)
              .layoutWeight(1)
              .backgroundColor(this.videoState === VideoPlayerState.PLAYING ?
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
