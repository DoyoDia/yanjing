/**
 * 视频播放页面
 * 对应 Android 项目的 VideoPlayerActivity
 * 从 DemoPage 跳转过来，播放指定的视频
 */

import { MDVRLibrary, IOnSurfaceReadyCallback, Context } from '@ohos/md360player';
import { media } from '@kit.MediaKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import sensor from '@ohos.sensor';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 性能测量工具类
 */
class PerformanceMonitor {
  private static callCounts: Map<string, number> = new Map();
  private static totalDurations: Map<string, number> = new Map();
  private static maxDurations: Map<string, number> = new Map();
  private static minDurations: Map<string, number> = new Map();

  /**
   * 测量函数执行耗时
   * @param funcName 函数名称
   * @param func 要执行的函数
   * @param logEveryN 每N次调用才打印一次日志（用于高频调用，如updateGyroData）
   * @returns 函数返回值
   */
  static measure<T>(funcName: string, func: () => T, logEveryN: number = 1): T {
    const startTime = Date.now();
    try {
      const result = func();
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      // 更新统计信息
      const count = (PerformanceMonitor.callCounts.get(funcName) || 0) + 1;
      PerformanceMonitor.callCounts.set(funcName, count);
      
      const total = (PerformanceMonitor.totalDurations.get(funcName) || 0) + duration;
      PerformanceMonitor.totalDurations.set(funcName, total);
      
      const max = Math.max(PerformanceMonitor.maxDurations.get(funcName) || 0, duration);
      PerformanceMonitor.maxDurations.set(funcName, max);
      
      const min = Math.min(PerformanceMonitor.minDurations.get(funcName) || Number.MAX_VALUE, duration);
      PerformanceMonitor.minDurations.set(funcName, min);
      
      // 根据 logEveryN 决定是否打印日志
      if (count % logEveryN === 0) {
        const avg = total / count;
        console.log(`[MD360Player-Perf] ${funcName} 耗时: ${duration}ms | 平均: ${avg.toFixed(2)}ms | 最大: ${max}ms | 最小: ${min}ms | 调用次数: ${count}`);
      }
      
      return result;
    } catch (error) {
      const endTime = Date.now();
      const duration = endTime - startTime;
      console.error(`[MD360Player-Perf] ${funcName} 执行失败，耗时: ${duration}ms`, error);
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error(String(error));
      }
    }
  }

  /**
   * 测量异步函数执行耗时
   * @param funcName 函数名称
   * @param func 要执行的异步函数
   * @param logEveryN 每N次调用才打印一次日志
   * @returns Promise<T>
   */
  static async measureAsync<T>(funcName: string, func: () => Promise<T>, logEveryN: number = 1): Promise<T> {
    const startTime = Date.now();
    try {
      const result = await func();
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      // 更新统计信息
      const count = (PerformanceMonitor.callCounts.get(funcName) || 0) + 1;
      PerformanceMonitor.callCounts.set(funcName, count);
      
      const total = (PerformanceMonitor.totalDurations.get(funcName) || 0) + duration;
      PerformanceMonitor.totalDurations.set(funcName, total);
      
      const max = Math.max(PerformanceMonitor.maxDurations.get(funcName) || 0, duration);
      PerformanceMonitor.maxDurations.set(funcName, max);
      
      const min = Math.min(PerformanceMonitor.minDurations.get(funcName) || Number.MAX_VALUE, duration);
      PerformanceMonitor.minDurations.set(funcName, min);
      
      // 根据 logEveryN 决定是否打印日志
      if (count % logEveryN === 0) {
        const avg = total / count;
        console.log(`[MD360Player-Perf] ${funcName} 耗时: ${duration}ms | 平均: ${avg.toFixed(2)}ms | 最大: ${max}ms | 最小: ${min}ms | 调用次数: ${count}`);
      }
      
      return result;
    } catch (error) {
      const endTime = Date.now();
      const duration = endTime - startTime;
      console.error(`[MD360Player-Perf] ${funcName} 执行失败，耗时: ${duration}ms`, error);
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error(String(error));
      }
    }
  }

  /**
   * 获取指定函数的统计信息
   */
  static getStats(funcName: string): string {
    const count = PerformanceMonitor.callCounts.get(funcName) || 0;
    const total = PerformanceMonitor.totalDurations.get(funcName) || 0;
    const avg = count > 0 ? total / count : 0;
    const max = PerformanceMonitor.maxDurations.get(funcName) || 0;
    const min = PerformanceMonitor.minDurations.get(funcName) || 0;
    return `${funcName}: 调用${count}次, 平均${avg.toFixed(2)}ms, 最大${max}ms, 最小${min}ms`;
  }

  /**
   * 打印所有函数的统计信息
   */
  static printAllStats(): void {
    console.log('[MD360Player-Perf] ========== 性能统计汇总 ==========');
    PerformanceMonitor.callCounts.forEach((count, funcName) => {
      console.log(`[MD360Player-Perf] ${PerformanceMonitor.getStats(funcName)}`);
    });
    console.log('[MD360Player-Perf] =================================');
  }
}

/**
 * 播放状态回调接口
 */
interface IPlaybackStateCallback {
  onStateChanged?(isPlaying: boolean): void;
  onProgressChanged?(currentTime: number, duration: number): void;
  onDurationChanged?(duration: number): void;
}

/**
 * 播放状态回调实现类
 */
class PlaybackStateCallbackImpl implements IPlaybackStateCallback {
  private page: VideoPlayerPage;

  constructor(page: VideoPlayerPage) {
    this.page = page;
  }

  onStateChanged(isPlaying: boolean): void {
    this.page.isPlaying = isPlaying;
  }

  onProgressChanged(currentTime: number, duration: number): void {
    if (!this.page.isSeeking) {
      this.page.currentTime = currentTime;
    }
    if (this.page.duration !== duration && duration > 0) {
      this.page.duration = duration;
    }
  }

  onDurationChanged(duration: number): void {
    this.page.duration = duration;
  }
}

/**
 * 视频 Surface 准备回调实现类
 * 当 Surface 准备好时，创建视频播放器并连接到 Surface
 */
class VideoSurfaceCallback implements IOnSurfaceReadyCallback {
  private avPlayer: media.AVPlayer | null = null;
  private videoFilePath: string; // 本地文件路径或网络 URL
  private surfaceId: string | null = null;
  private stateCallback: IPlaybackStateCallback | null = null;
  private progressTimer: number | null = null;

  constructor(videoFilePath: string) {
    this.videoFilePath = videoFilePath;
  }

  /**
   * 设置播放状态回调
   */
  setStateCallback(callback: IPlaybackStateCallback | null): void {
    this.stateCallback = callback;
  }

  onSurfaceReady(surface: Object): void {
    console.log('VideoSurfaceCallback: Surface ready');
  }

  /**
   * 播放/暂停切换
   */
  togglePlayPause(): void {
    if (!this.avPlayer) {
      console.warn('VideoSurfaceCallback: AVPlayer is null, cannot toggle play/pause');
      return;
    }
    
    try {
      if (this.avPlayer.state === 'playing') {
        this.avPlayer.pause();
        this.stateCallback?.onStateChanged?.(false);
      } else if (this.avPlayer.state === 'prepared' || this.avPlayer.state === 'paused') {
        this.avPlayer.play();
        this.stateCallback?.onStateChanged?.(true);
        this.startProgressTimer();
      } else if (this.avPlayer.state === 'completed') {
        // 播放完成后，从头开始播放
        this.avPlayer.seek(0);
        this.avPlayer.play();
        this.stateCallback?.onStateChanged?.(true);
        this.startProgressTimer();
      }
    } catch (error) {
      console.error('VideoSurfaceCallback: Failed to toggle play/pause:', error);
    }
  }

  /**
   * 跳转到指定位置
   */
  seekTo(timeMs: number): void {
    if (!this.avPlayer) {
      return;
    }
    
    try {
      this.avPlayer.seek(timeMs, media.SeekMode.SEEK_NEXT_SYNC);
    } catch (error) {
      console.error('VideoSurfaceCallback: Failed to seek:', error);
    }
  }

  /**
   * 获取当前播放状态
   */
  isPlaying(): boolean {
    return this.avPlayer?.state === 'playing';
  }

  /**
   * 获取当前播放时间（毫秒）
   */
  getCurrentTime(): number {
    try {
      return this.avPlayer?.currentTime || 0;
    } catch (error) {
      return 0;
    }
  }

  /**
   * 获取总时长（毫秒）
   */
  getDuration(): number {
    try {
      return this.avPlayer?.duration || 0;
    } catch (error) {
      return 0;
    }
  }

  /**
   * 开始进度更新定时器
   */
  private startProgressTimer(): void {
    this.stopProgressTimer();
    this.progressTimer = setInterval(() => {
      if (this.avPlayer && this.avPlayer.state === 'playing') {
        const currentTime = this.getCurrentTime();
        const duration = this.getDuration();
        this.stateCallback?.onProgressChanged?.(currentTime, duration);
      }
    }, 500); // 每500ms更新一次
  }

  /**
   * 停止进度更新定时器
   */
  private stopProgressTimer(): void {
    if (this.progressTimer !== null) {
      clearInterval(this.progressTimer);
      this.progressTimer = null;
    }
  }

  /**
   * 设置 surfaceId 并创建视频播放器
   */
  async setSurfaceIdAndCreatePlayer(surfaceId: string): Promise<void> {
    console.log('VideoSurfaceCallback: setSurfaceIdAndCreatePlayer called with surfaceId:', surfaceId);
    
    if (!surfaceId || surfaceId === '0' || surfaceId === '') {
      console.error('VideoSurfaceCallback: Invalid surfaceId:', surfaceId);
      return;
    }
    
    if (this.surfaceId === surfaceId) {
      console.log('VideoSurfaceCallback: surfaceId already set:', surfaceId);
      return;
    }
    
    this.surfaceId = surfaceId;
    console.log('VideoSurfaceCallback: Setting surfaceId and creating AVPlayer:', surfaceId);
    
    try {
      if (this.avPlayer !== null) {
        this.avPlayer.release();
        this.avPlayer = null;
      }
      
      this.avPlayer = await media.createAVPlayer();
      
      if (this.avPlayer === null) {
        console.error('Failed to create AVPlayer: returned null');
        return;
      }
      
      this.avPlayer.on('error', (error: BusinessError) => {
        console.error('AVPlayer error:', JSON.stringify(error));
      });
      
      let videoUrl: string = '';
      if (this.videoFilePath) {
        // 如果已经是 fd:// 或 content:// 协议，直接使用
        if (this.videoFilePath.startsWith('fd://') || this.videoFilePath.startsWith('content://')) {
          videoUrl = this.videoFilePath;
          console.log('VideoPlayerPage: Using URI directly:', videoUrl);
        } else if (this.videoFilePath.startsWith('/')) {
          // 本地文件路径，使用 fd:// 协议
          try {
            const file = await fs.open(this.videoFilePath);
            videoUrl = `fd://${file.fd}`;
            console.log('VideoPlayerPage: Using local file with fd:// protocol:', videoUrl);
          } catch (error) {
            console.error('VideoPlayerPage: Failed to open local file:', error);
            videoUrl = this.videoFilePath; // 回退到原始路径
          }
        } else if (this.videoFilePath.startsWith('http://') || this.videoFilePath.startsWith('https://')) {
          // 网络 URL
          videoUrl = this.videoFilePath;
          console.log('VideoPlayerPage: Using network URL:', videoUrl);
        } else {
          // 其他情况，直接使用
          videoUrl = this.videoFilePath;
          console.log('VideoPlayerPage: Using video path as-is:', videoUrl);
        }
      } else {
        // 如果没有文件路径，使用默认网络 URL
        videoUrl = 'https://vd3.bdstatic.com/mda-pdc2kmwtd2vxhiy4/cae_h264/1681502407203843413/mda-pdc2kmwtd2vxhiy4.mp4';
      }
      
      // 设置状态变化回调
      this.avPlayer.on('stateChange', (state: string) => {
        console.log('AVPlayer state changed:', state);
        
        if (state === 'initialized' && this.avPlayer !== null) {
          console.log('AVPlayer is initialized, setting surfaceId before prepare():', this.surfaceId);
          try {
            const surfaceIdToSet = this.surfaceId ?? undefined;
            this.avPlayer.surfaceId = surfaceIdToSet;
            console.log('AVPlayer surfaceId set successfully. Current surfaceId:', this.avPlayer.surfaceId);
            
            if (this.avPlayer.surfaceId === surfaceIdToSet) {
              console.log('AVPlayer: surfaceId verified successfully in initialized state');
            } else {
              console.warn('AVPlayer: surfaceId mismatch! Expected:', surfaceIdToSet, 'Got:', this.avPlayer.surfaceId);
            }
            
            console.log('AVPlayer: Calling prepare() after setting surfaceId');
            this.avPlayer.prepare();
          } catch (error) {
            console.error('Failed to set AVPlayer surfaceId in initialized state:', error);
          }
        } else if (state === 'prepared' && this.avPlayer !== null) {
          console.log('AVPlayer prepared, starting playback');
          try {
            // 获取总时长（可能需要延迟获取）
            setTimeout(() => {
              if (this.avPlayer) {
                try {
                  const duration = this.avPlayer.duration;
                  if (duration > 0) {
                    console.log('VideoSurfaceCallback: Got duration:', duration);
                    this.stateCallback?.onDurationChanged?.(duration);
                  }
                } catch (error) {
                  console.warn('VideoSurfaceCallback: Failed to get duration:', error);
                }
              }
            }, 100);
            
            this.avPlayer.play();
            this.stateCallback?.onStateChanged?.(true);
            this.startProgressTimer();
          } catch (error) {
            console.error('Failed to play AVPlayer:', error);
          }
        } else if (state === 'playing') {
          console.log('AVPlayer is now playing');
          this.stateCallback?.onStateChanged?.(true);
          this.startProgressTimer();
        } else if (state === 'paused') {
          console.log('AVPlayer is paused');
          this.stateCallback?.onStateChanged?.(false);
          this.stopProgressTimer();
        } else if (state === 'completed') {
          console.log('AVPlayer completed');
          this.stateCallback?.onStateChanged?.(false);
          this.stopProgressTimer();
          // 播放完成后，可以重新播放
          if (this.avPlayer) {
            try {
              this.avPlayer.seek(0);
            } catch (error) {
              console.warn('Failed to seek to start after completion:', error);
            }
          }
        } else if (state === 'error') {
          console.error('AVPlayer entered error state');
          this.stateCallback?.onStateChanged?.(false);
          this.stopProgressTimer();
        }
      });
      
      this.avPlayer.url = videoUrl;
      console.log('AVPlayer URL set to:', videoUrl);
      
    } catch (error) {
      console.error('Failed to create AVPlayer:', error);
    }
  }

  release(): void {
    this.stopProgressTimer();
    if (this.avPlayer) {
      this.avPlayer.release();
      this.avPlayer = null;
      console.log('AVPlayer released');
    }
  }
}

@Entry
@Component
struct VideoPlayerPage {
  private vrLibrary: MDVRLibrary | null = null;
  private xComponentController: XComponentController = new XComponentController();
  private videoCallback: VideoSurfaceCallback | null = null;
  private vrContext: Context | null = null; // 保存 VR 库使用的 Context
  @State videoUrl: string = ''; // 从路由参数获取的视频 URL
  @State showViewControl: boolean = false; // 控制视角控制面板显示
  @State showOpenGLControl: boolean = false; // 控制 OpenGL 功能演示面板显示
  @State showAdvancedControl: boolean = false; // 控制高级功能面板显示
  @State viewportEnabled: boolean = true; // 视口功能是否启用（默认启用）
  @State scissorEnabled: boolean = false; // 裁剪功能是否启用
  @State blendEnabled: boolean = false; // 混合功能是否启用
  
  // 模式状态
  @State currentDisplayMode: number = MDVRLibrary.DISPLAY_MODE_NORMAL;
  @State currentInteractiveMode: number = MDVRLibrary.INTERACTIVE_MODE_TOUCH; // 默认使用触摸模式
  @State currentProjectionMode: number = MDVRLibrary.PROJECTION_MODE_SPHERE;
  @State antiDistortionEnabled: boolean = false;
  @State touchGestureEnabled: boolean = true; // 触摸手势是否启用
  
  // 信息显示
  @State hotspotInfo: string = '';
  @State directorBrief: string = '';
  
  // 播放控制状态
  @State isPlaying: boolean = false;
  @State currentTime: number = 0; // 当前播放时间（毫秒）
  @State duration: number = 0; // 总时长（毫秒）
  @State isSeeking: boolean = false; // 是否正在拖拽进度条
  @State showPlaybackControl: boolean = false; // 是否显示播放控制栏
  
  // 触摸控制状态
  private lastPanX: number | undefined = undefined; // 上次拖拽X坐标
  private lastPanY: number | undefined = undefined; // 上次拖拽Y坐标
  // 运动传感器状态
  private gyroSensorEnabled: boolean = false;
  // 旋转矢量回调（保持引用以便 off）
  private rotationVectorCallback: ((data: ESObject) => void) | null = null;

  aboutToAppear() {
    // 从路由参数获取视频 URL
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      if (params['videoUrl']) {
        this.videoUrl = params['videoUrl'] as string;
        console.log('VideoPlayerPage: Got videoUrl from params:', this.videoUrl);
      } else if (params['useLocalFile']) {
        // 使用本地文件
        this.videoUrl = ''; // 将在 initVR 中从 rawfile 加载
        console.log('VideoPlayerPage: Will use local file from rawfile');
      }
    }
  }

  build() {
    Stack() {
      XComponent({
        id: 'xcomponent',
        type: XComponentType.SURFACE,
        libraryname: 'md360player',
        controller: this.xComponentController
      })
        .onLoad(async () => {
          const surfaceId = this.xComponentController.getXComponentSurfaceId();
          await this.initVR(surfaceId);
        })
        .onDestroy(() => {
          this.videoCallback?.release();
          PerformanceMonitor.measure('vrLibrary.onDestroy()', () => {
            this.vrLibrary?.onDestroy();
          });
          // 打印所有性能统计信息
          PerformanceMonitor.printAllStats();
        })
        .width('100%')
        .height('100%')
        .gesture(
          // 拖拽手势：用于旋转视角（根据模式动态启用/禁用）
          PanGesture({ fingers: 1, direction: PanDirection.All, distance: 1 })
            .onActionStart((event: GestureEvent) => {
              // 纯运动模式下禁用触摸
              if (!this.touchGestureEnabled) {
                return;
              }
              // 拖拽开始
              this.lastPanX = event.offsetX;
              this.lastPanY = event.offsetY;
            })
            .onActionUpdate((event: GestureEvent) => {
              // 纯运动模式下禁用触摸
              if (!this.touchGestureEnabled) {
                return;
              }
              // 拖拽更新：计算移动距离并传递给VR库
              if (this.lastPanX !== undefined && this.lastPanY !== undefined) {
                const distanceX = event.offsetX - this.lastPanX;
                const distanceY = event.offsetY - this.lastPanY;
                if (this.vrLibrary) {
                  PerformanceMonitor.measure('vrLibrary.onDrag()', () => {
                    this.vrLibrary!.onDrag(distanceX, distanceY);
                  });
                }
                this.lastPanX = event.offsetX;
                this.lastPanY = event.offsetY;
              }
            })
            .onActionEnd(() => {
              // 拖拽结束
              this.lastPanX = undefined;
              this.lastPanY = undefined;
            })
        )

      // 顶部控制栏
      Scroll() {
        Row() {
          Button('返回')
            .onClick(() => {
              router.back();
            })
            .backgroundColor('#FFFFFF')
            .opacity(0.95)
            .fontSize(15)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .borderRadius(6)
            .border({ width: 1, color: '#E0E0E0' })
            .shadow({ radius: 4, color: '#40000000', offsetX: 0, offsetY: 2 })
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .margin({ right: 8 })

          Button(this.showAdvancedControl ? '隐藏高级' : '高级控制')
            .onClick(() => {
              this.showAdvancedControl = !this.showAdvancedControl;
              this.showViewControl = false;
              this.showOpenGLControl = false;
            })
            .backgroundColor('#FFFFFF')
            .opacity(0.95)
            .fontSize(15)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .borderRadius(6)
            .border({ width: 1, color: '#E0E0E0' })
            .shadow({ radius: 4, color: '#40000000', offsetX: 0, offsetY: 2 })
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .margin({ right: 8 })

          Button(this.showPlaybackControl ? '隐藏控制' : '播放控制')
            .onClick(() => {
              this.showPlaybackControl = !this.showPlaybackControl;
            })
            .backgroundColor('#FFFFFF')
            .opacity(0.95)
            .fontSize(15)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .borderRadius(6)
            .border({ width: 1, color: '#E0E0E0' })
            .shadow({ radius: 4, color: '#40000000', offsetX: 0, offsetY: 2 })
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        }
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Auto)
      .scrollBarColor('#80000000')
      .scrollBarWidth(4)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor('#00000000')
      .position({ x: 0, y: 0 })
      .zIndex(100)

      // 播放控制栏（底部）
      if (this.showPlaybackControl) {
        Column() {
          // 进度条和时间显示
          Row() {
            // 播放控制按钮
            Row() {
              // 播放/暂停按钮
              Button() {
                Image(this.isPlaying ? $r('app.media.icon_play') : $r('app.media.icon_pause'))
                  .width(32)
                  .height(32)
                  .fillColor('#FFFFFF')
              }
              .onClick(() => {
                this.videoCallback?.togglePlayPause();
              })
              .width(32)
              .height(32)
              .backgroundColor('#4CAF50')
              .borderRadius(32)
              .margin({ left: 16 })
            }
            .padding({ bottom: 12 })
            Text(this.formatTime(this.currentTime))
              .fontSize(12)
              .fontColor('#FFFFFF')
              .width(50)
              .textAlign(TextAlign.Start)
            
            Slider({
              value: this.duration > 0 ? (this.currentTime / this.duration) * 100 : 0,
              min: 0,
              max: 100,
              step: 0.1,
              style: SliderStyle.OutSet
            })
              .blockColor('#FFFFFF')
              .trackColor('#80FFFFFF')
              .selectedColor('#4CAF50')
              .showSteps(false)
              .showTips(false)
              .onChange((value: number) => {
                // 拖拽时更新显示的时间，但不立即跳转
                if (this.duration > 0) {
                  this.isSeeking = true;
                  this.currentTime = (value / 100) * this.duration;
                }
              })
              .onChange((value: number, mode: SliderChangeMode) => {
                if (mode === SliderChangeMode.End) {
                  // 拖拽结束时才真正跳转
                  if (this.duration > 0) {
                    const seekTime = (value / 100) * this.duration;
                    this.videoCallback?.seekTo(seekTime);
                  }
                  this.isSeeking = false;
                }
              })
              .layoutWeight(1)
              .height(30)
            
            Text(this.formatTime(this.duration))
              .fontSize(12)
              .fontColor('#FFFFFF')
              .width(50)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 3 })


        }
        .width('100%')
        .padding({ top: 12 })
        .backgroundColor('#80000000')
        .borderRadius(12)
        .position({ x: 0, y: '100%' })
        .translate({ y: -60 })
        .zIndex(102)
      }

      // 高级控制面板（显示模式、交互模式、投影模式等，横屏优化：靠右侧展示，支持上下滚动，带关闭按钮）
      if (this.showAdvancedControl) {
        Scroll() {
          Column() {
            Row() {
              Text('高级控制')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .layoutWeight(1)

              Text('✕')
                .onClick(() => {
                  this.showAdvancedControl = false;
                })
                .width(28)
                .height(28)
                .borderRadius(14)
                .backgroundColor('#33FFFFFF')
                .fontColor('#FFFFFF')
                .textAlign(TextAlign.Center)
            }
            .margin({ bottom: 12 })

            // 显示模式
            Text('显示模式')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ top: 8, bottom: 4 })
              .alignSelf(ItemAlign.Start)

            Row() {
              Button(this.currentDisplayMode === MDVRLibrary.DISPLAY_MODE_NORMAL ? '普通模式 ✓' : '普通模式')
                .onClick(() => {
                  this.switchDisplayMode(MDVRLibrary.DISPLAY_MODE_NORMAL);
                })
                .flexGrow(1)
                .height(40)
                .backgroundColor(this.currentDisplayMode === MDVRLibrary.DISPLAY_MODE_NORMAL ? '#4CAF50' : '#9E9E9E')
                .fontColor('#FFFFFF')

              Button(this.currentDisplayMode === MDVRLibrary.DISPLAY_MODE_GLASS ? 'VR模式 ✓' : 'VR模式')
                .onClick(() => {
                  this.switchDisplayMode(MDVRLibrary.DISPLAY_MODE_GLASS);
                })
                .flexGrow(1)
                .height(40)
                .margin({ left: 8 })
                .backgroundColor(this.currentDisplayMode === MDVRLibrary.DISPLAY_MODE_GLASS ? '#4CAF50' : '#9E9E9E')
                .fontColor('#FFFFFF')
            }
            .width('100%')
            .margin({ bottom: 12 })

            // 交互模式
            Text('交互模式')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ top: 8, bottom: 4 })
              .alignSelf(ItemAlign.Start)

            Column() {
              Button(this.getInteractiveModeText(MDVRLibrary.INTERACTIVE_MODE_MOTION))
                .onClick(() => {
                  this.switchInteractiveMode(MDVRLibrary.INTERACTIVE_MODE_MOTION);
                })
                .width('100%')
                .height(35)
                .margin({ bottom: 4 })
                .backgroundColor(this.currentInteractiveMode === MDVRLibrary.INTERACTIVE_MODE_MOTION ? '#4CAF50' : '#9E9E9E')
                .fontColor('#FFFFFF')
                .fontSize(12)

              Button(this.getInteractiveModeText(MDVRLibrary.INTERACTIVE_MODE_TOUCH))
                .onClick(() => {
                  this.switchInteractiveMode(MDVRLibrary.INTERACTIVE_MODE_TOUCH);
                })
                .width('100%')
                .height(35)
                .margin({ bottom: 4 })
                .backgroundColor(this.currentInteractiveMode === MDVRLibrary.INTERACTIVE_MODE_TOUCH ? '#4CAF50' : '#9E9E9E')
                .fontColor('#FFFFFF')
                .fontSize(12)

              Button(this.getInteractiveModeText(MDVRLibrary.INTERACTIVE_MODE_MOTION_WITH_TOUCH))
                .onClick(() => {
                  this.switchInteractiveMode(MDVRLibrary.INTERACTIVE_MODE_MOTION_WITH_TOUCH);
                })
                .width('100%')
                .height(35)
                .margin({ bottom: 4 })
                .backgroundColor(this.currentInteractiveMode === MDVRLibrary.INTERACTIVE_MODE_MOTION_WITH_TOUCH ? '#4CAF50' : '#9E9E9E')
                .fontColor('#FFFFFF')
                .fontSize(12)
            }
            .width('100%')
            .margin({ bottom: 12 })

            // 投影模式
            Text('投影模式')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ top: 8, bottom: 4 })
              .alignSelf(ItemAlign.Start)

            Row() {
              Button('球面')
                .onClick(() => {
                  this.switchProjectionMode(MDVRLibrary.PROJECTION_MODE_SPHERE);
                })
                .flexGrow(1)
                .height(35)
                .backgroundColor(this.currentProjectionMode === MDVRLibrary.PROJECTION_MODE_SPHERE ? '#4CAF50' : '#9E9E9E')
                .fontColor('#FFFFFF')
                .fontSize(12)
            }
            .width('100%')
            .margin({ bottom: 8 })

            // 信息显示
            if (this.hotspotInfo || this.directorBrief) {
              Text('信息')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .margin({ top: 8, bottom: 4 })
                .alignSelf(ItemAlign.Start)

              if (this.hotspotInfo) {
                Text(this.hotspotInfo)
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .width('100%')
                  .padding(8)
                  .backgroundColor('#80000000')
                  .borderRadius(4)
                  .margin({ bottom: 4 })
              }

              if (this.directorBrief) {
                Text(this.directorBrief)
                  .fontSize(12)
                  .fontColor('#FFFFFF')
                  .width('100%')
                  .padding(8)
                  .backgroundColor('#80000000')
                  .borderRadius(4)
                  .margin({ bottom: 4 })
              }
            }
          }
          .width('100%')
        }
        .width(320)
        .height('80%')
        .padding(16)
        .backgroundColor('#80000000')
        .borderRadius(8)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .scrollBarColor('#80FFFFFF')
        .scrollBarWidth(4)
        // 靠右侧，从顶部工具栏下方开始
        .position({ x: '100%', y: 72 })
        .translate({ x: -336, y: 0 }) // 320 宽 + 右侧 16 间距
        .zIndex(101)
      }
    }
    .width('100%')
    .height('100%')
  }

  async initVR(surfaceId: string) {
    let videoFilePath: string = this.videoUrl;
    
    // 如果没有指定 URL，尝试从 rawfile 加载
    if (!videoFilePath) {
      try {
        const context = getContext() as common.UIAbilityContext;
        const resourceManager = context.resourceManager;
        
        const rawFile = await resourceManager.getRawFileContent('test360video.mp4');
        const filesDir = context.filesDir;
        const targetPath = `${filesDir}/test360video.mp4`;
        
        const writeFile = fs.openSync(targetPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
        fs.writeSync(writeFile.fd, rawFile.buffer);
        fs.closeSync(writeFile);
        
        videoFilePath = targetPath;
        console.log('VideoPlayerPage: Video file copied from rawfile to:', videoFilePath);
      } catch (error) {
        console.error('VideoPlayerPage: Failed to load video from rawfile:', error);
        // 使用默认网络 URL
        videoFilePath = 'https://vd3.bdstatic.com/mda-pdc2kmwtd2vxhiy4/cae_h264/1681502407203843413/mda-pdc2kmwtd2vxhiy4.mp4';
      }
    }
    
    this.videoCallback = new VideoSurfaceCallback(videoFilePath);
    
    // 设置播放状态回调
    const playbackCallback = new PlaybackStateCallbackImpl(this);
    this.videoCallback.setStateCallback(playbackCallback);
    
    // 创建并保存 Context 实例，后续切换模式时使用同一个实例
    PerformanceMonitor.measure('new Context()', () => {
      this.vrContext = new Context();
    });
    
    if (!this.videoCallback) {
      throw new Error('videoCallback is null');
    }
    
    // 拆分链式调用，对每个方法进行耗时统计
    let builder = PerformanceMonitor.measure('MDVRLibrary.with()', () => {
      return MDVRLibrary.with(this.vrContext!);
    });
    
    builder = PerformanceMonitor.measure('builder.displayMode()', () => {
      return builder.displayMode(MDVRLibrary.DISPLAY_MODE_NORMAL);
    });
    
    builder = PerformanceMonitor.measure('builder.interactiveMode()', () => {
      return builder.interactiveMode(MDVRLibrary.INTERACTIVE_MODE_TOUCH); // 默认使用触摸模式
    });
    
    builder = PerformanceMonitor.measure('builder.asVideo()', () => {
      return builder.asVideo(this.videoCallback!);
    });
    
    this.vrLibrary = PerformanceMonitor.measure('builder.build()', () => {
      return builder.build(this.xComponentController);
    });
    
    // 初始化触摸手势状态
    this.updateTouchGestureState(MDVRLibrary.INTERACTIVE_MODE_TOUCH);
    
    PerformanceMonitor.measure('vrLibrary.onSurfaceReady()', () => {
      this.vrLibrary!.onSurfaceReady(surfaceId);
    });
    
    // 初始化视口（延迟执行，确保 NAPI 已准备好）
    setTimeout(() => {
      this.initViewport();
    }, 500);
    
    // 从 C++ 侧获取 NativeImage 的 surfaceId
    const maxRetries = 30;
    let retryCount = 0;
    
    console.log('VideoPlayerPage: Starting to get video surfaceId, maxRetries:', maxRetries);
    
    const tryConnectVideo = async () => {
      if (this.videoCallback === null || this.vrLibrary === null) {
        console.error('VideoPlayerPage: videoCallback or vrLibrary is null!');
        return;
      }
      
      const videoSurfaceId = PerformanceMonitor.measure('vrLibrary.getVideoSurfaceId()', () => {
        return this.vrLibrary!.getVideoSurfaceId();
      });
      console.log(`VideoPlayerPage: Attempt ${retryCount + 1}/${maxRetries}: Got videoSurfaceId from NAPI:`, videoSurfaceId);
      
      if (videoSurfaceId !== null && videoSurfaceId !== '' && videoSurfaceId !== '0') {
        console.log('VideoPlayerPage: Got valid video surfaceId from NAPI:', videoSurfaceId);
        try {
          await this.videoCallback.setSurfaceIdAndCreatePlayer(videoSurfaceId);
          console.log('VideoPlayerPage: setSurfaceIdAndCreatePlayer completed');
        } catch (error) {
          console.error('VideoPlayerPage: Error in setSurfaceIdAndCreatePlayer:', error);
        }
      } else {
        retryCount++;
        if (retryCount < maxRetries) {
          console.log(`VideoPlayerPage: Video surfaceId not available yet (retry ${retryCount}/${maxRetries}), got:`, videoSurfaceId);
          setTimeout(tryConnectVideo, 500);
        } else {
          console.error('VideoPlayerPage: Failed to get valid video surfaceId after', maxRetries, 'retries. Last value:', videoSurfaceId);
        }
      }
    };
    
    console.log('VideoPlayerPage: Will start trying to get surfaceId in 1000ms...');
    setTimeout(tryConnectVideo, 1000);
  }

  /**
   * 初始化视口（页面加载时自动启用）
   */
  private initViewport(): void {
    if (!this.vrLibrary) {
      console.warn('VideoPlayerPage: VR Library not ready yet, will retry viewport setup');
      // 如果 VR Library 还没准备好，延迟重试
      setTimeout(() => {
        this.initViewport();
      }, 500);
      return;
    }

    // 设置视口为屏幕的 3/4 大小，居中显示
    const context: common.UIAbilityContext = getContext() as common.UIAbilityContext;
    const windowStage: window.WindowStage | undefined = context.windowStage;
    if (windowStage) {
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      const windowWidth: number = mainWindow.getWindowProperties().windowRect.width;
      const windowHeight: number = mainWindow.getWindowProperties().windowRect.height;
      const viewportWidth: number = Math.floor(windowWidth * 0.75);
      const viewportHeight: number = Math.floor(windowHeight * 0.75);
      const viewportX: number = Math.floor((windowWidth - viewportWidth) / 2);
      const viewportY: number = Math.floor((windowHeight - viewportHeight) / 2);
      
      PerformanceMonitor.measure('vrLibrary.setViewport()', () => {
        this.vrLibrary!.setViewport(viewportX, viewportY, viewportWidth, viewportHeight);
      });
      this.viewportEnabled = true;
      console.log(`VideoPlayerPage: Viewport initialized to (${viewportX}, ${viewportY}, ${viewportWidth}, ${viewportHeight})`);
    }
  }

  /**
   * 切换显示模式
   */
  private switchDisplayMode(mode: number): void {
    console.log('========== VideoPlayerPage: switchDisplayMode START ==========');
    console.log('VideoPlayerPage: Requested mode:', mode, '(102=GLASS/VR, 101=NORMAL)');
    console.log('VideoPlayerPage: vrLibrary exists:', !!this.vrLibrary);
    console.log('VideoPlayerPage: vrContext exists:', !!this.vrContext);
    
    if (!this.vrLibrary || !this.vrContext) {
      console.error('VideoPlayerPage: vrLibrary or vrContext is null');
      return;
    }
    
    // 检查 switchDisplayMode 方法是否存在
    if (!this.vrLibrary.switchDisplayMode) {
      console.error('VideoPlayerPage: switchDisplayMode method does not exist on vrLibrary');
      promptAction.showToast({ message: '切换显示模式失败：方法不存在', duration: 1000 });
      return;
    }
    
    try {
      // 先切换显示模式
      console.log('VideoPlayerPage: Calling vrLibrary.switchDisplayMode...');
      PerformanceMonitor.measure('vrLibrary.switchDisplayMode()', () => {
        this.vrLibrary!.switchDisplayMode(this.vrContext!, mode);
      });
      console.log('VideoPlayerPage: vrLibrary.switchDisplayMode completed');
      
      // 然后调用底层 VR 模式接口
      console.log('VideoPlayerPage: Setting VR mode...');
      const isVRMode: boolean = mode === MDVRLibrary.DISPLAY_MODE_GLASS;
      console.log('VideoPlayerPage: Calling setVRModeEnabled with:', isVRMode);
      
      try {
        const result: number = PerformanceMonitor.measure('vrLibrary.setVRModeEnabled()', () => {
          return this.vrLibrary!.setVRModeEnabled(isVRMode);
        });
        console.log('VideoPlayerPage: setVRModeEnabled returned:', result);
        
        if (result === 0) {
          console.log('VideoPlayerPage: ✓ VR mode enabled successfully:', isVRMode);
        } else {
          console.warn('VideoPlayerPage: ✗ Failed to set VR mode, result:', result);
        }
      } catch (napiError) {
        console.error('VideoPlayerPage: ✗ Error calling setVRModeEnabled:', napiError);
      }
      
      this.currentDisplayMode = mode;
      const modeName = mode === MDVRLibrary.DISPLAY_MODE_NORMAL ? '普通模式' : 'VR模式';
      promptAction.showToast({ message: `显示模式: ${modeName}`, duration: 1000 });
      console.log('VideoPlayerPage: Display mode switched to:', mode, '(' + modeName + ')');
      console.log('========== VideoPlayerPage: switchDisplayMode END ==========');
    } catch (error) {
      console.error('VideoPlayerPage: ✗ Failed to switch display mode:', error);
      if (error instanceof Error) {
        console.error('VideoPlayerPage: Error message:', error.message);
        console.error('VideoPlayerPage: Error stack:', error.stack);
      }
      promptAction.showToast({ message: '切换显示模式失败', duration: 1000 });
      console.log('========== VideoPlayerPage: switchDisplayMode END (ERROR) ==========');
    }
  }

  /**
   * 切换交互模式
   */
  private switchInteractiveMode(mode: number): void {
    console.log('MD360_DEBUG switchInteractiveMode: start, mode =', mode);
    if (!this.vrLibrary || !this.vrContext) {
      console.error('MD360_DEBUG switchInteractiveMode: vrLibrary or vrContext is null');
      return;
    }
    try {
      // 先检查陀螺仪支持情况（仅在需要陀螺仪的模式下）
      const needGyro: boolean = mode === MDVRLibrary.INTERACTIVE_MODE_MOTION
        || mode === MDVRLibrary.INTERACTIVE_MODE_MOTION_WITH_TOUCH;

      if (needGyro) {
        console.log('MD360_DEBUG switchInteractiveMode: needGyro = true, vrLibrary exists =', !!this.vrLibrary);
        if (this.vrLibrary) {
          try {
            const support: boolean = PerformanceMonitor.measure('vrLibrary.isGyroSupported()', () => {
              return this.vrLibrary!.isGyroSupported();
            });
            console.log('MD360_DEBUG switchInteractiveMode: isGyroSupported() =', support);
            if (!support) {
              promptAction.showToast({ message: '当前设备不支持陀螺仪', duration: 1500 });
              console.warn('MD360_DEBUG switchInteractiveMode: Gyro is not supported on this device');
              return;
            }
          } catch (e) {
            console.warn('MD360_DEBUG switchInteractiveMode: Failed to query gyro support, continue anyway:', e);
          }
        }
      }

      PerformanceMonitor.measure('vrLibrary.switchInteractiveMode()', () => {
        this.vrLibrary!.switchInteractiveMode(this.vrContext!, mode);
      });
      this.currentInteractiveMode = mode;
      
      // 更新触摸手势启用状态
      this.updateTouchGestureState(mode);
      
      this.updateGyroStateByInteractiveMode(mode);

      promptAction.showToast({ message: `交互模式: ${this.getInteractiveModeText(mode)}`, duration: 1000 });
      console.log('MD360_DEBUG switchInteractiveMode: Interactive mode switched to', mode);
    } catch (error) {
      console.error('MD360_DEBUG switchInteractiveMode: Failed to switch interactive mode:', error);
      promptAction.showToast({ message: '切换交互模式失败', duration: 1000 });
    }
  }

  /**
   * 根据交互模式更新触摸手势启用状态
   */
  private updateTouchGestureState(mode: number): void {
    // 纯运动模式下禁用触摸手势，其他模式启用
    const isMotionOnly = mode === MDVRLibrary.INTERACTIVE_MODE_MOTION;
    
    this.touchGestureEnabled = !isMotionOnly;
  }

  /**
   * 获取交互模式文本
   */
  private getInteractiveModeText(mode: number): string {
    switch (mode) {
      case MDVRLibrary.INTERACTIVE_MODE_MOTION:
        return '运动感应';
      case MDVRLibrary.INTERACTIVE_MODE_TOUCH:
        return '触摸控制';
      case MDVRLibrary.INTERACTIVE_MODE_MOTION_WITH_TOUCH:
        return '运动+触摸';
      default:
        return '未知模式';
    }
  }

  /**
   * 根据当前交互模式更新底层陀螺仪状态
   * - 运动相关模式：开启陀螺仪 + GL 内部更新
   * - 纯触摸模式：关闭陀螺仪
   */
  private updateGyroStateByInteractiveMode(mode: number): void {
    console.log('MD360_DEBUG updateGyroStateByInteractiveMode: start, mode =', mode);
    if (!this.vrLibrary) {
      console.warn('MD360_DEBUG updateGyroStateByInteractiveMode: vrLibrary is null');
      return;
    }

    const needGyro: boolean = mode === MDVRLibrary.INTERACTIVE_MODE_MOTION
      || mode === MDVRLibrary.INTERACTIVE_MODE_MOTION_WITH_TOUCH;

    try {
      if (needGyro) {
        console.log('MD360_DEBUG updateGyroStateByInteractiveMode: needGyro = true');
        PerformanceMonitor.measure('vrLibrary.turnOnGyro()', () => {
          this.vrLibrary!.turnOnGyro();
        });
        console.log('MD360_DEBUG updateGyroStateByInteractiveMode: Gyro turned ON for interactive mode', mode);
        // 启动 HarmonyOS 传感器并通过 NAPI 将四元数喂给 C++ MotionStrategy
        this.startGyroSensor();
      } else {
        console.log('MD360_DEBUG updateGyroStateByInteractiveMode: needGyro = false');
        PerformanceMonitor.measure('vrLibrary.turnOffGyro()', () => {
          this.vrLibrary!.turnOffGyro();
        });
        console.log('MD360_DEBUG updateGyroStateByInteractiveMode: Gyro turned OFF for interactive mode', mode);
        // 关闭传感器订阅
        this.stopGyroSensor();
      }
    } catch (error) {
      console.error('MD360_DEBUG updateGyroStateByInteractiveMode: Failed to update gyro state by interactive mode:', error);
    }
  }

  /**
   * 启动陀螺仪（旋转矢量）传感器，并通过 MDVRLibrary.updateGyroData 把四元数传给 C++ MotionStrategy
   */
  private startGyroSensor(): void {
    if (this.gyroSensorEnabled) {
      console.log('MD360_DEBUG GyroSensor: already enabled, skip start');
      return;
    }

    if (!this.vrLibrary) {
      console.warn('MD360_DEBUG GyroSensor: VR Library not ready, cannot start sensor');
      return;
    }

    // 回调里将传感器数据转换为四元数 (x, y, z, w) 并喂给 C++
    this.rotationVectorCallback = (data: ESObject) => {
      try {
        // HarmonyOS 旋转矢量通常提供 x/y/z/w 或 values[0..3] / data[0..3]
        let x: number = 0;
        let y: number = 0;
        let z: number = 0;
        let w: number = 1;

        if (data) {
          const anyData = data as ESObject as Record<string, ESObject>;
          // 优先使用 x/y/z/w 字段
          if (typeof anyData['x'] === 'number') {
            x = anyData['x'] as ESObject as number;
          }
          if (typeof anyData['y'] === 'number') {
            y = anyData['y'] as ESObject as number;
          }
          if (typeof anyData['z'] === 'number') {
            z = anyData['z'] as ESObject as number;
          }
          if (typeof anyData['w'] === 'number') {
            w = anyData['w'] as ESObject as number;
          }

          // 兼容 values/data 数组形式
          const values = (anyData['values'] as ESObject as number[]) || (anyData['data'] as ESObject as number[]);
          if (values && values.length >= 4) {
            x = values[0];
            y = values[1];
            z = values[2];
            w = values[3];
          }
        }

        // 基本校验，避免 NaN 传入 C++
        if (!isFinite(x) || !isFinite(y) || !isFinite(z) || !isFinite(w)) {
          return;
        }

        // 将四元数传给 C++ 侧 MotionStrategy
        // 注意：updateGyroData 是高频调用（每100ms一次），每60次才打印一次日志
        if (this.vrLibrary) {
          PerformanceMonitor.measure('vrLibrary.updateGyroData()', () => {
            this.vrLibrary!.updateGyroData(x, y, z, w);
          }, 60);
        }
      } catch (e) {
        console.error('VideoPlayerPage: GyroSensor updateGyroData error:', e);
      }
    };

    try {
      sensor.on(sensor.SensorType.SENSOR_TYPE_ID_ROTATION_VECTOR, this.rotationVectorCallback, { interval: 1000000 });
      this.gyroSensorEnabled = true;
    } catch (e) {
      console.error('VideoPlayerPage: Failed to subscribe rotation vector sensor:', e);
      this.rotationVectorCallback = null;
    }
  }

  /**
   * 停止陀螺仪（旋转矢量）传感器订阅
   */
  private stopGyroSensor(): void {
    if (!this.gyroSensorEnabled || !this.rotationVectorCallback) {
      return;
    }

    try {
      sensor.off(sensor.SensorType.SENSOR_TYPE_ID_ROTATION_VECTOR, this.rotationVectorCallback);
    } catch (e) {
      console.error('VideoPlayerPage: Failed to unsubscribe rotation vector sensor:', e);
    } finally {
      this.gyroSensorEnabled = false;
      this.rotationVectorCallback = null;
    }
  }

  /**
   * 切换投影模式
   */
  private switchProjectionMode(mode: number): void {
    if (!this.vrLibrary || !this.vrContext) {
      console.error('VideoPlayerPage: vrLibrary or vrContext is null');
      return;
    }
    try {
      PerformanceMonitor.measure('vrLibrary.switchProjectionMode()', () => {
        this.vrLibrary!.switchProjectionMode(this.vrContext!, mode);
      });
      this.currentProjectionMode = mode;
      const modeName = this.getProjectionModeText(mode);
      promptAction.showToast({ message: `投影模式: ${modeName}`, duration: 1000 });
      console.log('VideoPlayerPage: Projection mode switched to:', mode);
    } catch (error) {
      console.error('VideoPlayerPage: Failed to switch projection mode:', error);
      promptAction.showToast({ message: '切换投影模式失败', duration: 1000 });
    }
  }

  /**
   * 获取投影模式文本
   */
  private getProjectionModeText(mode: number): string {
    switch (mode) {
      case MDVRLibrary.PROJECTION_MODE_SPHERE:
        return '球面';
      default:
        return '未知模式';
    }
  }

  /**
   * 格式化时间（毫秒转 mm:ss）
   */
  private formatTime(timeMs: number): string {
    if (timeMs <= 0 || !isFinite(timeMs)) {
      return '00:00';
    }
    const totalSeconds = Math.floor(timeMs / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

}

