/**
 * ExternalPanoramaView - 外部显示器（智能眼镜）专用全景渲染页面
 * 此页面在智能眼镜上显示单画面视图
 * 使用 md360player 库进行渲染
 */

import { SensorManager, SensorDataListener, getSensorManager } from '../sensor/SensorManager';
import { GlassesImuManager, GlassesConnectionState, getGlassesImuManager } from '../sensor/GlassesImuManager';
import { Quaternion, Matrix4 } from '../utils/MathUtils';
import { SensorListenerImpl, GlassesImuListenerImpl } from '../utils/ListenerImplementations';
import { MDVRLibrary, IOnSurfaceReadyCallback, Context } from '@ohos/md360player';
import { media } from '@kit.MediaKit';

@Entry
@Component
struct ExternalPanoramaView {
  // XComponent 控制器
  private xComponentController: XComponentController = new XComponentController();

  // 传感器管理器
  private sensorManager: SensorManager = getSensorManager();
  private glassesManager: GlassesImuManager = getGlassesImuManager();

  // md360player 核心对象
  private vrLibrary: MDVRLibrary | null = null;
  private vrContext: Context | null = null;

  // 眼镜 IMU 状态
  private glassesConnected: boolean = false;

  // 渲染状态
  @State rendererReady: boolean = false;
  @State isRendering: boolean = false;

  // 传感器监听器
  private sensorListener: SensorListenerImpl | null = null;
  private glassesListener: GlassesImuListenerImpl | null = null;

  aboutToAppear(): void {
    // 创建传感器监听器
    this.sensorListener = new SensorListenerImpl((quaternion: Quaternion, viewMatrix: Matrix4) => {
      // 传感器数据由 md360player 内部处理
    });

    // Glasses IMU listener
    this.glassesListener = new GlassesImuListenerImpl(
      (state: GlassesConnectionState) => {
        this.glassesConnected = state.connected && state.hasPermission;
        if (this.isRendering) {
          if (this.glassesConnected) {
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
        console.error('ExternalPanoramaView: Glasses IMU error', message);
      }
    );


    // 添加传感器监听器
    this.sensorManager.addListener(this.sensorListener);
    if (this.glassesListener) {
      this.glassesManager.addListener(this.glassesListener);
    }

    this.glassesManager.initialize();
  }

  aboutToDisappear(): void {
    this.stopRendering();
    if (this.sensorListener) {
      this.sensorManager.removeListener(this.sensorListener);
    }
    if (this.glassesListener) {
      this.glassesManager.removeListener(this.glassesListener);
    }
    this.glassesManager.stopImu();
    this.glassesManager.stopMonitoring();
    
    if (this.vrLibrary) {
      this.vrLibrary.onDestroy();
    }
  }

  private startRendering(): void {
    if (this.isRendering) return;

    this.isRendering = true;
    if (this.glassesConnected) {
      this.glassesManager.startImu();
    } else {
      this.sensorManager.start();
    }
  }

  private stopRendering(): void {
    this.isRendering = false;
    this.glassesManager.stopImu();
    this.sensorManager.stop();
  }

  private async initVR(surfaceId: string): Promise<void> {
    console.info('ExternalPanoramaView: Initializing VR with surfaceId:', surfaceId);
    
    // 创建 Context
    this.vrContext = new Context();
    
    // 构建 MDVRLibrary (单画面模式)
    let builder = MDVRLibrary.with(this.vrContext)
      .displayMode(MDVRLibrary.DISPLAY_MODE_NORMAL)
      .interactiveMode(MDVRLibrary.INTERACTIVE_MODE_MOTION);
    
    this.vrLibrary = builder.build(this.xComponentController);
    
    // 通知 Surface 准备就绪
    this.vrLibrary.onSurfaceReady(surfaceId);
    
    this.rendererReady = true;
  }

  private onXComponentLoad(): void {
    console.info('ExternalPanoramaView: XComponent loaded');

    setTimeout(async () => {
      const surfaceId = this.xComponentController.getXComponentSurfaceId();
      if (surfaceId && surfaceId.length > 0) {
        await this.initVR(surfaceId);
        this.startRendering();
        console.info('ExternalPanoramaView: VR initialized and rendering started');
      } else {
        console.error('ExternalPanoramaView: Failed to get surfaceId');
      }
    }, 100);
  }

  private onXComponentDestroy(): void {
    console.info('ExternalPanoramaView: XComponent destroyed');
    this.rendererReady = false;
    this.stopRendering();
  }

  build() {
    Stack() {
      // 全屏渲染视图（无任何 UI 覆盖层）
      XComponent({
        id: 'externalPanoramaXComponent',
        type: XComponentType.SURFACE,
        libraryname: 'md360player',
        controller: this.xComponentController
      })
        .onLoad(() => this.onXComponentLoad())
        .onDestroy(() => this.onXComponentDestroy())
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
