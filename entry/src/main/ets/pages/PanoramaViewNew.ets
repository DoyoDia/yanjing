/**
 * PanoramaView - 全景渲染视图页面（使用 md360player）
 * 使用 MDVRLibrary 进行 360° 全景视频渲染
 * 支持视频播放、传感器控制和外部显示器输出
 */

import { MDVRLibrary, IOnSurfaceReadyCallback, Context } from '@ohos/md360player';
import { SensorManager, DeviceHoldMode, getSensorManager } from '../sensor/SensorManager';
import { GlassesImuManager, GlassesConnectionState, getGlassesImuManager } from '../sensor/GlassesImuManager';
import { Quaternion } from '../utils/MathUtils';
import { GlassesImuListenerImpl } from '../utils/ListenerImplementations';
import { ExternalDisplayManager, DisplayInfo, ExternalDisplayListener, DisplayType, getExternalDisplayManager } from '../display/ExternalDisplayManager';
import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

// File truncated due to bash command length limits
