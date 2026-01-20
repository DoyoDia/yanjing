/**
 * ExternalPanoramaView - 外部显示器（智能眼镜）专用全景渲染页面
 * 此页面将在智能眼镜上显示分屏双眼视图
 */

import { SensorManager, SensorDataListener, getSensorManager } from '../sensor/SensorManager';
import { Quaternion, Matrix4 } from '../utils/MathUtils';
import { SensorListenerImpl } from '../utils/ListenerImplementations';
import panoramaRenderer from 'libpanorama_renderer.so';

@Entry
@Component
struct ExternalPanoramaView {
  // XComponent 控制器
  private xComponentController: XComponentController = new XComponentController();

  // 传感器管理器
  private sensorManager: SensorManager = getSensorManager();

  // 渲染状态
  @State rendererReady: boolean = false;
  @State isRendering: boolean = false;

  // 渲染循环定时器 ID
  private renderTimerId: number = -1;

  // 传感器监听器
  private sensorListener: SensorListenerImpl | null = null;

  aboutToAppear(): void {
    // 创建传感器监听器
    this.sensorListener = new SensorListenerImpl((quaternion: Quaternion, viewMatrix: Matrix4) => {
      if (this.rendererReady) {
        panoramaRenderer.setViewMatrix(viewMatrix.toFloat32Array());
      }
    });

    // 添加传感器监听器
    this.sensorManager.addListener(this.sensorListener);
  }

  aboutToDisappear(): void {
    this.stopRendering();
    if (this.sensorListener) {
      this.sensorManager.removeListener(this.sensorListener);
    }
  }

  private startRendering(): void {
    if (this.isRendering) return;

    this.isRendering = true;

    // 使用 setInterval 替代 requestAnimationFrame（约60fps）
    this.renderTimerId = setInterval(() => {
      if (!this.isRendering || !this.rendererReady) return;
      panoramaRenderer.render();
    }, 16);
  }

  private stopRendering(): void {
    this.isRendering = false;
    if (this.renderTimerId !== -1) {
      clearInterval(this.renderTimerId);
      this.renderTimerId = -1;
    }
  }

  private onXComponentLoad(): void {
    console.info('ExternalPanoramaView: XComponent loaded');

    setTimeout(() => {
      if (panoramaRenderer.isInitialized()) {
        this.rendererReady = true;
        // 外部显示器始终使用分屏模式
        panoramaRenderer.setStereoMode(true);
        // 自动开始渲染
        this.startRendering();
        console.info('ExternalPanoramaView: Renderer ready, started rendering');
      } else {
        console.error('ExternalPanoramaView: Renderer failed to initialize');
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
        libraryname: 'panorama_renderer',
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
