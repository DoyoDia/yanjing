/**
 * 主页面 - 传感器测试与调试界面
 * 用于验证 SensorManager 模块的功能
 */

import { SensorManager, SensorDataListener, DeviceHoldMode, getSensorManager } from '../sensor/SensorManager';
import { Quaternion, Matrix4, radToDeg } from '../utils/MathUtils';
import { SensorListenerImpl } from '../utils/ListenerImplementations';
import { router } from '@kit.ArkUI';

/**
 * 欧拉角接口
 */
interface EulerAngles {
  pitch: number;
  yaw: number;
  roll: number;
}

@Entry
@Component
struct Index {
  // 传感器管理器实例
  private sensorManager: SensorManager = getSensorManager();

  // 显示状态
  @State isRunning: boolean = false;
  @State holdMode: string = 'LANDSCAPE_TELESCOPE';

  // 四元数数据显示
  @State quatX: string = '0.000';
  @State quatY: string = '0.000';
  @State quatZ: string = '0.000';
  @State quatW: string = '1.000';

  // 欧拉角估算（仅用于调试显示）
  @State pitch: string = '0.0°';
  @State yaw: string = '0.0°';
  @State roll: string = '0.0°';

  // 视图矩阵显示（前4个元素作为示例）
  @State matrixPreview: string = '[1, 0, 0, 0, ...]';

  // 传感器数据监听器
  private sensorListener: SensorListenerImpl | null = null;

  /**
   * 从四元数提取欧拉角（ZYX顺序）
   * 仅用于调试显示，不用于实际渲染
   */
  private quaternionToEuler(q: Quaternion): EulerAngles {
    const x = q.x, y = q.y, z = q.z, w = q.w;

    // Roll (X轴旋转)
    const sinr_cosp = 2 * (w * x + y * z);
    const cosr_cosp = 1 - 2 * (x * x + y * y);
    const rollAngle = Math.atan2(sinr_cosp, cosr_cosp);

    // Pitch (Y轴旋转)
    const sinp = 2 * (w * y - z * x);
    let pitchAngle: number;
    if (Math.abs(sinp) >= 1) {
      pitchAngle = Math.sign(sinp) * Math.PI / 2;
    } else {
      pitchAngle = Math.asin(sinp);
    }

    // Yaw (Z轴旋转)
    const siny_cosp = 2 * (w * z + x * y);
    const cosy_cosp = 1 - 2 * (y * y + z * z);
    const yawAngle = Math.atan2(siny_cosp, cosy_cosp);

    const result: EulerAngles = { pitch: pitchAngle, yaw: yawAngle, roll: rollAngle };
    return result;
  }

  /**
   * 页面即将出现时的回调
   */
  aboutToAppear(): void {
    // 创建传感器监听器
    this.sensorListener = new SensorListenerImpl((quaternion: Quaternion, viewMatrix: Matrix4) => {
      // 更新四元数显示
      this.quatX = quaternion.x.toFixed(3);
      this.quatY = quaternion.y.toFixed(3);
      this.quatZ = quaternion.z.toFixed(3);
      this.quatW = quaternion.w.toFixed(3);

      // 从四元数估算欧拉角（仅用于可视化）
      const euler = this.quaternionToEuler(quaternion);
      this.pitch = radToDeg(euler.pitch).toFixed(1) + '°';
      this.yaw = radToDeg(euler.yaw).toFixed(1) + '°';
      this.roll = radToDeg(euler.roll).toFixed(1) + '°';

      // 显示视图矩阵预览
      const m = viewMatrix.elements;
      this.matrixPreview = `[${m[0].toFixed(2)}, ${m[1].toFixed(2)}, ${m[2].toFixed(2)}, ${m[3].toFixed(2)}, ...]`;
    });

    // 添加传感器监听器
    this.sensorManager.addListener(this.sensorListener);
  }

  /**
   * 页面即将消失时的回调
   */
  aboutToDisappear(): void {
    // 停止传感器并移除监听器
    this.sensorManager.stop();
    if (this.sensorListener) {
      this.sensorManager.removeListener(this.sensorListener);
    }
  }

  /**
   * 切换传感器运行状态
   */
  private toggleSensor(): void {
    if (this.isRunning) {
      this.sensorManager.stop();
    } else {
      this.sensorManager.start();
    }
    this.isRunning = !this.isRunning;
  }

  /**
   * 切换持握模式
   */
  private cycleHoldMode(): void {
    const modes: DeviceHoldMode[] = [
      DeviceHoldMode.LANDSCAPE_TELESCOPE,
      DeviceHoldMode.PORTRAIT,
      DeviceHoldMode.FLAT
    ];
    const modeNames: string[] = ['LANDSCAPE_TELESCOPE', 'PORTRAIT', 'FLAT'];

    const currentIndex = modes.indexOf(this.sensorManager.getHoldMode());
    const nextIndex = (currentIndex + 1) % modes.length;

    this.sensorManager.setHoldMode(modes[nextIndex]);
    this.holdMode = modeNames[nextIndex];
  }

  build() {
    Column() {
      // 标题
      Text('360° VR Sensor Test')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })
        .fontColor('#FFFFFF')

      // 状态卡片
      Column() {
        // 运行状态
        Row() {
          Circle()
            .width(12)
            .height(12)
            .fill(this.isRunning ? '#4CAF50' : '#757575')
          Text(this.isRunning ? '传感器运行中' : '传感器已停止')
            .fontSize(16)
            .fontColor(this.isRunning ? '#4CAF50' : '#757575')
            .margin({ left: 8 })
        }
        .margin({ bottom: 16 })

        // 持握模式
        Text(`持握模式: ${this.holdMode}`)
          .fontSize(14)
          .fontColor('#B0BEC5')
      }
      .width('90%')
      .padding(16)
      .backgroundColor('#1E1E1E')
      .borderRadius(12)
      .margin({ bottom: 16 })

      // 四元数数据卡片
      Column() {
        Text('设备姿态四元数 (x, y, z, w)')
          .fontSize(14)
          .fontColor('#78909C')
          .margin({ bottom: 12 })

        Row() {
          this.DataItem('X', this.quatX, '#F44336')
          this.DataItem('Y', this.quatY, '#4CAF50')
          this.DataItem('Z', this.quatZ, '#2196F3')
          this.DataItem('W', this.quatW, '#FF9800')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      }
      .width('90%')
      .padding(16)
      .backgroundColor('#1E1E1E')
      .borderRadius(12)
      .margin({ bottom: 16 })

      // 欧拉角显示卡片
      Column() {
        Text('估算欧拉角 (仅供参考)')
          .fontSize(14)
          .fontColor('#78909C')
          .margin({ bottom: 12 })

        Row() {
          this.DataItem('Pitch', this.pitch, '#E91E63')
          this.DataItem('Yaw', this.yaw, '#9C27B0')
          this.DataItem('Roll', this.roll, '#00BCD4')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      }
      .width('90%')
      .padding(16)
      .backgroundColor('#1E1E1E')
      .borderRadius(12)
      .margin({ bottom: 16 })

      // 视图矩阵预览
      Column() {
        Text('OpenGL 视图矩阵预览')
          .fontSize(14)
          .fontColor('#78909C')
          .margin({ bottom: 8 })

        Text(this.matrixPreview)
          .fontSize(12)
          .fontColor('#90A4AE')
      }
      .width('90%')
      .padding(16)
      .backgroundColor('#1E1E1E')
      .borderRadius(12)
      .margin({ bottom: 24 })

      // 控制按钮
      Row() {
        Button(this.isRunning ? '停止' : '启动')
          .width('40%')
          .height(48)
          .fontSize(16)
          .backgroundColor(this.isRunning ? '#F44336' : '#4CAF50')
          .onClick(() => this.toggleSensor())

        Button('切换模式')
          .width('40%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#2196F3')
          .onClick(() => this.cycleHoldMode())
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)

      // 进入全景视图按钮
      Button('🌐 进入 360° 全景视图')
        .width('90%')
        .height(56)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#9C27B0')
        .margin({ top: 24 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/PanoramaView' });
        })

      // 使用说明
      Text('横持手机，像望远镜一样观察')
        .fontSize(12)
        .fontColor('#546E7A')
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#121212')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 数据项组件构建器
   */
  @Builder
  DataItem(label: string, value: string, color: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#78909C')
        .margin({ bottom: 4 })
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
    }
    .alignItems(HorizontalAlign.Center)
  }
}