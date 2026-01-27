/**
 * Created by hzqiujiadi on 16/3/12.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { GLUtil } from './common/GLUtil';
import { MDGLHandler } from './common/MDGLHandler';
import { MDMainHandler } from './common/MDMainHandler';
import { VRUtil } from './common/VRUtil';
import { CompactEyePickAdapter } from './compat/CompactEyePickAdapter';
import { CompactTouchPickAdapter } from './compat/CompactTouchPickAdapter';
import { BarrelDistortionConfig } from './model/BarrelDistortionConfig';
import { MDDirectorBrief } from './model/MDDirectorBrief';
import { MDFlingConfig } from './model/MDFlingConfig';
import { MDHitEvent } from './model/MDHitEvent';
import { MDMainPluginBuilder } from './model/MDMainPluginBuilder';
import { MDPinchConfig } from './model/MDPinchConfig';
import { MDRay } from './model/MDRay';
import { IMDHotspot } from './plugins/hotspot/IMDHotspot';
import { MDAbsPlugin } from './plugins/MDAbsPlugin';
import { MDPluginManager } from './plugins/MDPluginManager';
import { MDAbsView } from './plugins/hotspot/MDAbsView';
import { DisplayModeManager } from './strategy/display/DisplayModeManager';
import { InteractiveModeManager } from './strategy/interactive/InteractiveModeManager';
import { InteractiveModeManagerParams } from './strategy/interactive/AbsInteractiveStrategy';
import { IMDProjectionFactory } from './strategy/projection/IMDProjectionFactory';
import { ProjectionModeManager, ProjectionModeManagerParams } from './strategy/projection/ProjectionModeManager';
import { MD360BitmapTexture } from './texture/MD360BitmapTexture';
import { MD360CubemapTexture, MD360CubemapTextureCallback, ICubemapProvider } from './texture/MD360CubemapTexture';
import { MD360Texture } from './texture/MD360Texture';
import { MD360VideoTexture } from './texture/MD360VideoTexture';
import { MD360Director } from './MD360Director';
import { MD360DirectorFactory, DefaultDirectorFactory } from './MD360DirectorFactory';
import { MDDirectorCamUpdate } from './MDDirectorCamUpdate';
import { MDDirectorFilter } from './MDDirectorFilter';
import { MDGLScreenWrapper } from './MDGLScreenWrapper';
import { MDPickerManager } from './MDPickerManager';
import { MDTouchHelper, IAdvanceGestureListener } from './MDTouchHelper';
import { MD360Renderer } from './MD360Renderer';
import { MD360Player, MD360PlayerCmd } from 'libmd360player.so';
import { IEyePickListener, IEyePickListener2, ITouchPickListener, ITouchPickListener2, IGestureListener, IOnSurfaceReadyCallback, IBitmapProvider } from './model/MDTypes';
import { SensorEventListener, Uri, MotionEvent, Surface, View, GLSurfaceView, GLTextureView, Toast } from './AndroidTypes';

import { Context, RectF } from '../../google/android/apps/muzei/render/ViewTypes';
import { INotSupportCallback } from './strategy/ModeManager';
import { IDirectorFilter } from './MDDirectorFilter';

// TODO: 当相关类型迁移后，取消注释并删除类型占位符

// type Context = any;
// type RectF = {
//   set(left: number, top: number, right: number, bottom: number): void;
//   width(): number;
//   height(): number;
// };

/**
 * VR库主类
 */
export class MDVRLibrary {
  // private static readonly TAG: string = "MDVRLibrary";
  // public static readonly sMultiScreenSize: number = 2;

  // interactive mode
  // public static readonly INTERACTIVE_MODE_MOTION: number = 1;
  // public static readonly INTERACTIVE_MODE_TOUCH: number = 2;
  // public static readonly INTERACTIVE_MODE_MOTION_WITH_TOUCH: number = 3;
  // public static readonly INTERACTIVE_MODE_CARDBORAD_MOTION: number = 4;
  // public static readonly INTERACTIVE_MODE_CARDBORAD_MOTION_WITH_TOUCH: number = 5;

  // display mode
  // public static readonly DISPLAY_MODE_NORMAL: number = 101;
  // public static readonly DISPLAY_MODE_GLASS: number = 102;

  // projection mode
  // public static readonly PROJECTION_MODE_SPHERE: number = 201;
  // public static readonly PROJECTION_MODE_DOME180: number = 202;
  // public static readonly PROJECTION_MODE_DOME230: number = 203;
  // public static readonly PROJECTION_MODE_DOME180_UPPER: number = 204;
  // public static readonly PROJECTION_MODE_DOME230_UPPER: number = 205;
  /**
   * @deprecated since 2.0.4
   * use {@link #PROJECTION_MODE_STEREO_SPHERE_VERTICAL}
   */
  // public static readonly PROJECTION_MODE_STEREO_SPHERE: number = 206;
  // public static readonly PROJECTION_MODE_PLANE_FIT: number = 207;
  // public static readonly PROJECTION_MODE_PLANE_CROP: number = 208;
  // public static readonly PROJECTION_MODE_PLANE_FULL: number = 209;
  // public static readonly PROJECTION_MODE_MULTI_FISH_EYE_HORIZONTAL: number = 210;
  // public static readonly PROJECTION_MODE_MULTI_FISH_EYE_VERTICAL: number = 211;
  // public static readonly PROJECTION_MODE_STEREO_SPHERE_HORIZONTAL: number = 212;
  // public static readonly PROJECTION_MODE_STEREO_SPHERE_VERTICAL: number = 213;
  // public static readonly PROJECTION_MODE_CUBE: number = 214;

  public static readonly INTERACTIVE_MODE_MOTION: number = 1;
  public static readonly INTERACTIVE_MODE_TOUCH: number = 2;
  public static readonly INTERACTIVE_MODE_MOTION_WITH_TOUCH: number = 3;
  public static readonly INTERACTIVE_MODE_CARDBORAD_MOTION: number = 4;
  public static readonly INTERACTIVE_MODE_CARDBORAD_MOTION_WITH_TOUCH: number = 5;

  public static readonly DISPLAY_MODE_NORMAL: number = 101;
  public static readonly DISPLAY_MODE_GLASS: number = 102;

  public static readonly PROJECTION_MODE_SPHERE: number = 201;
  public static readonly PROJECTION_MODE_DOME180: number = 202;
  public static readonly PROJECTION_MODE_DOME230: number = 203;
  public static readonly PROJECTION_MODE_DOME180_UPPER: number = 204;
  public static readonly PROJECTION_MODE_DOME230_UPPER: number = 205;
  public static readonly PROJECTION_MODE_STEREO_SPHERE: number = 206;
  public static readonly PROJECTION_MODE_PLANE_FIT: number = 207;
  public static readonly PROJECTION_MODE_PLANE_CROP: number = 208;
  public static readonly PROJECTION_MODE_PLANE_FULL: number = 209;
  public static readonly PROJECTION_MODE_MULTI_FISH_EYE_HORIZONTAL: number = 210;
  public static readonly PROJECTION_MODE_MULTI_FISH_EYE_VERTICAL: number = 211;
  public static readonly PROJECTION_MODE_STEREO_SPHERE_HORIZONTAL: number = 212;
  public static readonly PROJECTION_MODE_STEREO_SPHERE_VERTICAL: number = 213;
  public static readonly PROJECTION_MODE_CUBE: number = 214;

  private mTextureSize: RectF = new RectF(0, 0, 1024, 1024);
  private mInteractiveModeManager: InteractiveModeManager | null = null;
  private mDisplayModeManager: DisplayModeManager | null = null;
  public mProjectionModeManager: ProjectionModeManager | null = null;
  private mPluginManager: MDPluginManager | null = null;
  private mPickerManager: MDPickerManager | null = null;
  private mScreenWrapper: MDGLScreenWrapper | null = null;
  private mTouchHelper: MDTouchHelper | null = null;
  private mTexture: MD360Texture | null = null;
  private mGLHandler: MDGLHandler | null = null;
  private mDirectorCameraUpdate: MDDirectorCamUpdate | null = null;
  private mDirectorFilter: MDDirectorFilter | null = null;
  
  private mNapi: MD360Player | null = null;
  private mRenderer: MD360Renderer | null = null;
  private mTimerId: number = -1;

  public constructor(builder: Builder) {
    // init main handler
    MDMainHandler.init();

    // init gl handler
    this.mGLHandler = new MDGLHandler();

    // init texture size
    this.mTextureSize = new RectF(0, 0, 1024, 1024);

    // init NAPI - 必须在 initModeManager 之前初始化，因为 InteractiveModeManager 需要 napi 实例
    this.mNapi = new MD360Player();
    this.mNapi.runCmd(MD360PlayerCmd.INIT); // kCmdInit

    // init mode manager
    this.initModeManager(builder);

    // init plugin manager
    this.initPluginManager(builder);

    // init glSurfaceViews
    this.initOpenGL(builder.mContext, builder.mScreenWrapper);

    this.mTexture = builder.mTexture;

    this.mTouchHelper = new MDTouchHelper(builder.mContext);

    // init touch helper
    this.initTouchHelper(builder);

    // init picker manager
    this.initPickerManager(builder);

    // add plugin
    this.initPlugin();
  }
  
  public onSurfaceReady(surfaceId: string): void {
    if (this.mScreenWrapper) {
      this.mScreenWrapper.setSurfaceId(surfaceId);
    }
    if (this.mNapi) {
      this.mNapi.setSurfaceId(surfaceId);
    }
    this.startLoop();
  }
  
  /**
   * 获取视频纹理的 SurfaceId
   * 这个方法返回 NativeImage 创建的 SurfaceId，用于连接 AVPlayer
   */
  public getVideoSurfaceId(): string | null {
    if (this.mNapi) {
      return this.mNapi.getVideoSurfaceId();
    }
    return null;
  }


  /**
   * 设置视口
   * @param x 视口左上角 X 坐标
   * @param y 视口左上角 Y 坐标
   * @param width 视口宽度
   * @param height 视口高度
   */
  public setViewport(x: number, y: number, width: number, height: number): void {
    if (this.mNapi && typeof this.mNapi.setViewport === 'function') {
      this.mNapi.setViewport(x, y, width, height);
    }
  }

  /**
   * 设置 VR 模式是否启用
   * @param enabled 是否启用 VR 模式
   * @returns 返回操作结果，0 表示成功
   */
  public setVRModeEnabled(enabled: boolean): number {
    if (this.mNapi && typeof this.mNapi.setVRModeEnabled === 'function') {
      return this.mNapi.setVRModeEnabled(enabled);
    }
    return -1;
  }

  /**
   * 检查是否支持陀螺仪
   * @returns 是否支持陀螺仪
   */
  public isGyroSupported(): boolean {
    if (this.mNapi && typeof this.mNapi.isSupport === 'function') {
      return this.mNapi.isSupport();
    }
    return false;
  }

  /**
   * 开启陀螺仪
   */
  public turnOnGyro(): void {
    if (this.mNapi) {
      if (typeof this.mNapi.turnOnGyro === 'function') {
        this.mNapi.turnOnGyro();
      }
      if (typeof this.mNapi.turnOnInGL === 'function') {
        this.mNapi.turnOnInGL();
      }
      if (typeof this.mNapi.onResume === 'function') {
        this.mNapi.onResume();
      }
    }
  }

  /**
   * 关闭陀螺仪
   */
  public turnOffGyro(): void {
    if (this.mNapi) {
      if (typeof this.mNapi.turnOffGyro === 'function') {
        this.mNapi.turnOffGyro();
      }
      if (typeof this.mNapi.turnOffInGL === 'function') {
        this.mNapi.turnOffInGL();
      }
      if (typeof this.mNapi.onPause === 'function') {
        this.mNapi.onPause();
      }
    }
  }

  /**
   * 更新陀螺仪数据
   * @param x 四元数 X 分量
   * @param y 四元数 Y 分量
   * @param z 四元数 Z 分量
   * @param w 四元数 W 分量
   */
  public updateGyroData(x: number, y: number, z: number, w: number): void {
    if (this.mNapi && typeof this.mNapi.updateGyroData === 'function') {
      this.mNapi.updateGyroData(x, y, z, w);
    }
  }
  
  private startLoop(): void {
    if (this.mTimerId !== -1) clearInterval(this.mTimerId);
    this.mTimerId = setInterval(() => {
      this.mRenderer?.onDrawFrame(null!);
    }, 16);
  }

  private initTouchHelper(builder: Builder): void {
    this.mTouchHelper = new MDTouchHelper(builder.mContext);
    if (builder.mGestureListener != null) {
      this.mTouchHelper.addClickListener(builder.mGestureListener);
    }
    const updatePinchRunnable = new UpdatePinchRunnable(this);
    this.mTouchHelper.setAdvanceGestureListener(new AdvanceGestureListenerImpl(this.mInteractiveModeManager, updatePinchRunnable, this.mGLHandler));
    this.mTouchHelper!.setPinchEnabled(builder.mPinchEnabled);
    if (builder.mPinchConfig != null) {
      this.mTouchHelper!.setPinchConfig(builder.mPinchConfig);
    }

    this.mTouchHelper!.setFlingEnabled(builder.mFlingEnabled);
    if (builder.mFlingConfig != null) {
      this.mTouchHelper!.setFlingConfig(builder.mFlingConfig);
    }

    this.mTouchHelper!.setTouchSensitivity(builder.mTouchSensitivity);

    // mScreenWrapper.getView().setOnTouchListener(new View.OnTouchListener() {
    //   @Override
    //   public boolean onTouch(View v, MotionEvent event) {
    //     if (event.getAction() == MotionEvent.ACTION_DOWN) {
    //       v.getParent().requestDisallowInterceptTouchEvent(true);
    //     } else if(event.getAction() == MotionEvent.ACTION_UP) {
    //       v.getParent().requestDisallowInterceptTouchEvent(false);
    //     }
    //     return mTouchHelper.handleTouchEvent(event);
    //   }
    // });
    // 在鸿蒙中，需要使用对应的事件处理API
  }

  private initModeManager(builder: Builder): void {
    // init director camera update
    this.mDirectorCameraUpdate = new MDDirectorCamUpdate();

    // init director
    this.mDirectorFilter = new MDDirectorFilter();
    this.mDirectorFilter.setDelegate(builder.mDirectorFilter);

    // init ProjectionModeManager
    const projectionManagerParams = new ProjectionModeManagerParams();
    projectionManagerParams.textureSize = this.mTextureSize;
    projectionManagerParams.directorFactory = builder.mDirectorFactory;
    projectionManagerParams.projectionFactory = builder.mProjectionFactory;
    projectionManagerParams.mainPluginBuilder = new MDMainPluginBuilder()
      .setCameraUpdate(this.mDirectorCameraUpdate)
      .setFilter(this.mDirectorFilter)
      .setContentType(builder.mContentType)
      .setTexture(builder.mTexture!);

    this.mProjectionModeManager = new ProjectionModeManager(builder.mProjectionMode, this.mGLHandler!, projectionManagerParams);
    this.mProjectionModeManager.prepare(builder.mContext, builder.mNotSupportCallback);

    // init DisplayModeManager
    this.mDisplayModeManager = new DisplayModeManager(builder.mDisplayMode, this.mGLHandler!);
    this.mDisplayModeManager.setBarrelDistortionConfig(builder.mBarrelDistortionConfig);
    // Glass模式下自动启用桶形畸变，否则使用配置的默认值
    const isGlassMode = builder.mDisplayMode === MDVRLibrary.DISPLAY_MODE_GLASS;
    const defaultEnabled = builder.mBarrelDistortionConfig?.isDefaultEnabled() || false;
    this.mDisplayModeManager.setAntiDistortionEnabled(isGlassMode || defaultEnabled);
    this.mDisplayModeManager.prepare(builder.mContext, builder.mNotSupportCallback);

    // init InteractiveModeManager
    const interactiveManagerParams = new InteractiveModeManagerParams();
    interactiveManagerParams.projectionModeManager = this.mProjectionModeManager;
    interactiveManagerParams.mMotionDelay = builder.mMotionDelay;
    interactiveManagerParams.mSensorListener = builder.mSensorListener;
    interactiveManagerParams.napi = this.mNapi;  // 传递 NAPI 实例，用于将触摸数据传递到 C++ 层
    this.mInteractiveModeManager = new InteractiveModeManager(builder.mInteractiveMode, this.mGLHandler!, interactiveManagerParams);
    this.mInteractiveModeManager.prepare(builder.mContext, builder.mNotSupportCallback);
  }

  private initPluginManager(builder: Builder): void {
    this.mPluginManager = new MDPluginManager();
  }

  private initPickerManager(builder: Builder): void {
    this.mPickerManager = MDPickerManager.with()
      .setPluginManager(this.mPluginManager!)
      .setDisplayModeManager(this.mDisplayModeManager!)
      .setProjectionModeManager(this.mProjectionModeManager!)
      .build();
    this.setEyePickEnable(builder.mEyePickEnabled);
    this.mPickerManager.setEyePickChangedListener(builder.mEyePickChangedListener);
    this.mPickerManager.setTouchPickListener(builder.mTouchPickChangedListener);

    // listener
    this.mTouchHelper?.addClickListener(this.mPickerManager.getTouchPicker());
  }

  private initOpenGL(context: Context, screenWrapper: MDGLScreenWrapper | null): void {
    // if (GLUtil.supportsEs2(context)) {
    if (true) { // 占位实现
      screenWrapper?.init(context);
      // Request an OpenGL ES 2.0 compatible context.

      const renderer = MD360Renderer.with(context)
        .setGLHandler(this.mGLHandler!)
        .setPluginManager(this.mPluginManager!)
        .setProjectionModeManager(this.mProjectionModeManager!)
        .setDisplayModeManager(this.mDisplayModeManager!)
        .build();
      
      renderer.setNapi(this.mNapi);
      this.mRenderer = renderer;

      // Set the renderer to our demo renderer, defined below.
      screenWrapper?.setRenderer(renderer);
      this.mScreenWrapper = screenWrapper;
    } else {
      // this.mScreenWrapper.getView().setVisibility(View.GONE);
      // Toast.makeText(context, "OpenGLES2 not supported.", Toast.LENGTH_SHORT).show();
      // 在鸿蒙中，需要使用对应的UI API
    }
  }

  private initPlugin(): void {
    this.addPlugin(this.mProjectionModeManager?.getDirectorUpdatePlugin());
    this.addPlugin(this.mPickerManager?.getEyePicker());
  }

  updateCamera(): MDDirectorCamUpdate | null {
    return this.mDirectorCameraUpdate;
  }

  getDirectorBrief(): MDDirectorBrief | null {
    return this.mProjectionModeManager?.getDirectorBrief() || null;
  }

  /**
   * 切换交互模式
   * @param context 上下文
   * @param mode 模式 (可选)
   */
  switchInteractiveMode(context: Context, mode?: number): void {
    if (mode === undefined) {
      this.mInteractiveModeManager?.switchToNextMode(context);
    } else {
      this.mInteractiveModeManager?.switchMode(context, mode);
    }
  }

  /**
   * 切换显示模式
   * @param context 上下文
   * @param mode 模式 (可选)
   */
  switchDisplayMode(context: Context, mode?: number): void {
    if (mode === undefined) {
      this.mDisplayModeManager?.switchToNextMode(context);
    } else {
      this.mDisplayModeManager?.switchMode(context, mode);
    }
  }

  /**
   * 切换投影模式
   * @param context 上下文
   * @param mode 模式
   */
  switchProjectionMode(context: Context, mode: number): void {
    this.mProjectionModeManager?.switchMode(context, mode);
    
    // 通知 C++ 侧切换投影模式
    if (this.mNapi) {
      this.mNapi.setProjectionMode(mode);
      console.log('MDVRLibrary: SetProjectionMode called with mode:', mode);
    }
  }

  resetTouch(): void {
    this.mGLHandler?.post(() => {
      const directors = this.mProjectionModeManager?.getDirectors() || [];
      for (const director of directors) {
        director.reset();
      }
    });
  }

  /**
   * 处理拖拽事件（用于触摸控制）
   * @param distanceX X方向移动距离
   * @param distanceY Y方向移动距离
   */
  onDrag(distanceX: number, distanceY: number): void {
    this.mInteractiveModeManager?.handleDrag(Math.floor(distanceX), Math.floor(distanceY));
  }

  resetPinch(): void {
    this.mTouchHelper?.reset();
  }

  resetEyePick(): void {
    this.mPickerManager?.resetEyePick();
  }

  setAntiDistortionEnabled(enabled: boolean): void {
    this.mDisplayModeManager?.setAntiDistortionEnabled(enabled);
  }

  isAntiDistortionEnabled(): boolean {
    return this.mDisplayModeManager?.isAntiDistortionEnabled() || false;
  }

  isEyePickEnable(): boolean {
    return this.mPickerManager?.isEyePickEnable() || false;
  }

  setEyePickEnable(eyePickEnable: boolean): void {
    this.mPickerManager?.setEyePickEnable(eyePickEnable);
  }

  /**
   * setEyePickChangedListener
   * @deprecated
   */
  setEyePickChangedListenerLegacy(listener: IEyePickListener): void {
    this.mPickerManager?.setEyePickChangedListener(new CompactEyePickAdapter(listener));
  }

  /**
   * setTouchPickListener
   * @deprecated
   */
  setTouchPickListenerLegacy(listener: ITouchPickListener): void {
    this.mPickerManager?.setTouchPickListener(new CompactTouchPickAdapter(listener));
  }
  setEyePickChangedListener(listener: IEyePickListener2 | null): void {
    this.mPickerManager?.setEyePickChangedListener(listener);
  }

  setTouchPickListener(listener: ITouchPickListener2 | null): void {
    this.mPickerManager?.setTouchPickListener(listener);
  }

  setPinchScale(scale: number): void {
    this.mTouchHelper?.scaleTo(scale);
  }

  isPinchEnabled(): boolean {
    return this.mTouchHelper?.isPinchEnabled() || false;
  }

  setPinchEnabled(enabled: boolean): void {
    this.mTouchHelper?.setPinchEnabled(enabled);
  }

  setPinchConfig(pinchConfig: MDPinchConfig): void {
    this.mTouchHelper?.setPinchConfig(pinchConfig);
  }

  isFlingEnabled(): boolean {
    return this.mTouchHelper?.isFlingEnabled() || false;
  }

  setFlingEnabled(enabled: boolean): void {
    this.mTouchHelper?.setFlingEnabled(enabled);
  }

  setFlingConfig(flingConfig: MDFlingConfig): void {
    this.mTouchHelper?.setFlingConfig(flingConfig);
  }

  setDirectorFilter(filter: IDirectorFilter | null): void {
    this.mDirectorFilter?.setDelegate(filter);
  }

  addPlugin(plugin: MDAbsPlugin | null | undefined): void {
    if (plugin != null) {
      this.mPluginManager?.add(plugin);
    }
  }

  removePlugin(plugin: MDAbsPlugin): void {
    this.mPluginManager?.remove(plugin);
  }

  removePlugins(): void {
    this.mPluginManager?.removeAll();
  }

  findHotspotByTag(tag: string): IMDHotspot | null {
    return this.mPluginManager?.findHotspotByTag(tag) || null;
  }

  findViewByTag(tag: string): MDAbsView | null {
    return this.mPluginManager?.findViewByTag(tag) || null;
  }

  onTextureResize(width: number, height: number): void {
    // mTextureSize.set(0, 0, width, height);
    // 在鸿蒙中，需要使用对应的RectF API
  }

  onOrientationChanged(context: Context): void {
    this.mInteractiveModeManager?.onOrientationChanged(context);
  }

  onResume(context: Context): void {
    this.mInteractiveModeManager?.onResume(context);
    if (this.mScreenWrapper != null) {
      this.mScreenWrapper.onResume();
    }
  }

  onPause(context: Context): void {
    this.mInteractiveModeManager?.onPause(context);
    if (this.mScreenWrapper != null) {
      this.mScreenWrapper.onPause();
    }
  }

  onDestroy(): void {
    // 1. 立即停止定时器，防止继续触发回调
    if (this.mTimerId !== -1) {
      clearInterval(this.mTimerId);
      this.mTimerId = -1;
    }

    // 2. 同步执行资源清理（不使用异步post，避免任务丢失）
    this.fireDestroy();

    // 3. 通知Native层销毁
    if (this.mNapi) {
      const napiRef = this.mNapi;
      this.mNapi = null;
      setTimeout(() => {
        try {
          napiRef.runCmd(MD360PlayerCmd.DESTROY);
        } catch (error) {
          console.error('MDVRLibrary: Error during async destroy:', error);
        }
      }, 0);
    }

    // 4. 清理所有manager引用，打破循环引用
    if (this.mInteractiveModeManager) {
      this.mInteractiveModeManager.destroy();
      this.mInteractiveModeManager = null;
    }

    if (this.mDisplayModeManager) {
      this.mDisplayModeManager.destroy();
      this.mDisplayModeManager = null;
    }

    if (this.mProjectionModeManager) {
      this.mProjectionModeManager.destroy();
      this.mProjectionModeManager = null;
    }

    if (this.mPickerManager) {
      this.mPickerManager.destroy();
      this.mPickerManager = null;
    }

    if (this.mPluginManager) {
      this.mPluginManager.destroy();
      this.mPluginManager = null;
    }

    if (this.mTouchHelper) {
      this.mTouchHelper.destroy();
      this.mTouchHelper = null;
    }

    if (this.mScreenWrapper) {
      this.mScreenWrapper.destroy();
      this.mScreenWrapper = null;
    }

    if (this.mRenderer) {
      this.mRenderer.destroy();
      this.mRenderer = null;
    }

    // 5. 清理其他引用
    this.mDirectorCameraUpdate = null;
    this.mDirectorFilter = null;

    // 6. 最后标记GLHandler销毁并清理
    if (this.mGLHandler) {
      this.mGLHandler.markAsDestroy();
      this.mGLHandler = null;
    }
  }

  private fireDestroy(): void {
    // 销毁所有插件
    const plugins = this.mPluginManager?.getPlugins() || [];
    for (const plugin of plugins) {
      try {
        plugin.destroyInGL();
      } catch (e) {
        console.error('MDVRLibrary: Failed to destroy plugin', e);
      }
    }

    // 销毁主插件
    const mainPlugin = this.mProjectionModeManager?.getMainPlugin();
    if (mainPlugin != null) {
      try {
        mainPlugin.destroyInGL();
      } catch (e) {
        console.error('MDVRLibrary: Failed to destroy main plugin', e);
      }
    }


    if (this.mTexture != null) {
      this.mTexture.destroy();
      this.mTexture.release();
      this.mTexture = null;
    }
  }

  /**
   * 处理触摸事件以旋转模型
   * @deprecated deprecated since 2.0
   */
  handleTouchEvent(event: MotionEvent): boolean {
    console.error("MDVRLibrary", "please remove the handleTouchEvent in context!");
    return false;
  }
  getInteractiveMode(): number {
    return this.mInteractiveModeManager?.getMode() || 0;
  }

  getDisplayMode(): number {
    return this.mDisplayModeManager?.getMode() || 0;
  }

  getProjectionMode(): number {
    return this.mProjectionModeManager?.getMode() || 0;
  }

  notifyPlayerChanged(): void {
    if (this.mTexture != null) {
      this.mTexture.notifyChanged();
    }
  }

  static with(context: Context): Builder {
    return new Builder(context);
  }
}

/**
 * 更新捏合任务类
 * 使用WeakRef避免循环引用导致的内存泄漏
 */
class UpdatePinchRunnable {
  private scale: number = 0;
  private libraryRef: WeakRef<MDVRLibrary> | null;

  constructor(library: MDVRLibrary) {
    // 使用WeakRef弱引用，避免循环引用
    this.libraryRef = new WeakRef(library);
  }

  setScale(scale: number): void {
    this.scale = scale;
  }

  run(): void {
    const library = this.libraryRef?.deref();
    if (!library) {
      return; // library已被回收，直接返回
    }
    const directors = library.mProjectionModeManager?.getDirectors() || [];
    for (const director of directors) {
      director.setNearScale(this.scale);
    }
  }

  destroy(): void {
    this.libraryRef = null;
  }
}

/**
 * 构建器类
 */
export class Builder {
  public mDisplayMode: number = MDVRLibrary.DISPLAY_MODE_NORMAL;
  public mInteractiveMode: number = MDVRLibrary.INTERACTIVE_MODE_MOTION;
  public mProjectionMode: number = MDVRLibrary.PROJECTION_MODE_SPHERE;
  public mContext: Context;
  public mContentType: number = ContentType.DEFAULT;
  public mTexture: MD360Texture | null = null;
  public mNotSupportCallback: INotSupportCallback | null = null;
  public mGestureListener: IGestureListener | null = null;
  public mPinchEnabled: boolean = false; // default false
  public mEyePickEnabled: boolean = true; // default true
  public mBarrelDistortionConfig: BarrelDistortionConfig | null = null;
  public mEyePickChangedListener: IEyePickListener2 | null = null;
  public mTouchPickChangedListener: ITouchPickListener2 | null = null;
  public mDirectorFactory: MD360DirectorFactory | null = null;
  public mMotionDelay: number = 0; // SensorManager.SENSOR_DELAY_GAME
  public mSensorListener: SensorEventListener | null = null;
  public mScreenWrapper: MDGLScreenWrapper | null = null;
  public mProjectionFactory: IMDProjectionFactory | null = null;
  public mPinchConfig: MDPinchConfig | null = null;
  public mDirectorFilter: IDirectorFilter | null = null;
  public mFlingEnabled: boolean = true; // default true
  public mFlingConfig: MDFlingConfig | null = null;
  public mTouchSensitivity: number = 1; // default = 1

  constructor(context: Context) {
    this.mContext = context;
  }

  displayMode(displayMode: number): Builder {
    this.mDisplayMode = displayMode;
    return this;
  }

  interactiveMode(interactiveMode: number): Builder {
    this.mInteractiveMode = interactiveMode;
    return this;
  }

  projectionMode(projectionMode: number): Builder {
    this.mProjectionMode = projectionMode;
    return this;
  }

  ifNotSupport(callback: INotSupportCallback | null): Builder {
    this.mNotSupportCallback = callback;
    return this;
  }

  asVideo(callback: IOnSurfaceReadyCallback): Builder {
    this.mTexture = new MD360VideoTexture(callback);
    this.mContentType = ContentType.VIDEO;
    return this;
  }

  asBitmap(bitmapProvider: IBitmapProvider): Builder {
    VRUtil.notNull(bitmapProvider, "bitmap Provider can't be null!");
    this.mTexture = new MD360BitmapTexture(bitmapProvider);
    this.mContentType = ContentType.BITMAP;
    return this;
  }

  asCubemap(cubemapProvider: ICubemapProvider): Builder {
    VRUtil.notNull(cubemapProvider, "cubemap Provider can't be null!");
    this.mTexture = new MD360CubemapTexture(cubemapProvider);
    this.mContentType = ContentType.CUBEMAP;
    return this;
  }

  /**
   * gesture listener, e.g. onClick
   * @deprecated please use {@link #listenGesture(IGestureListener)}
   * @param listener listener
   * @returns builder
   */
  gesture(listener: IGestureListener | null): Builder {
    this.mGestureListener = listener;
    return this;
  }

  /**
   * enable or disable the pinch gesture
   * @param enabled default is false
   * @returns builder
   */
  pinchEnabled(enabled: boolean): Builder {
    this.mPinchEnabled = enabled;
    return this;
  }

  /**
   * enable or disable the eye picking.
   * @param enabled default is false
   * @returns builder
   */
  eyePickEnabled(enabled: boolean): Builder {
    this.mEyePickEnabled = enabled;
    return this;
  }

  /**
   * gesture listener, e.g. onClick
   * @param listener listener
   * @returns builder
   */
  listenGesture(listener: IGestureListener | null): Builder {
    this.mGestureListener = listener;
    return this;
  }

  /**
   * IPickListener listener
   * @param listener listener
   * @returns builder
   */
  listenEyePick(listener: IEyePickListener): Builder {
    this.mEyePickChangedListener = new CompactEyePickAdapter(listener);
    return this;
  }

  /**
   * IPickListener listener
   * @param listener listener
   * @returns builder
   */
  listenTouchPick(listener: ITouchPickListener): Builder {
    this.mTouchPickChangedListener = new CompactTouchPickAdapter(listener);
    return this;
  }

  /**
   * sensor delay in motion mode.
   * @param motionDelay default is SENSOR_DELAY_GAME
   * @returns builder
   */
  motionDelay(motionDelay: number): Builder {
    this.mMotionDelay = motionDelay;
    return this;
  }

  sensorCallback(callback: SensorEventListener | null): Builder {
    this.mSensorListener = callback;
    return this;
  }

  directorFactory(directorFactory: MD360DirectorFactory | null): Builder {
    this.mDirectorFactory = directorFactory;
    return this;
  }

  projectionFactory(projectionFactory: IMDProjectionFactory | null): Builder {
    this.mProjectionFactory = projectionFactory;
    return this;
  }

  barrelDistortionConfig(config: BarrelDistortionConfig | null): Builder {
    this.mBarrelDistortionConfig = config;
    return this;
  }

  pinchConfig(config: MDPinchConfig | null): Builder {
    this.mPinchConfig = config;
    return this;
  }

  directorFilter(filter: IDirectorFilter | null): Builder {
    this.mDirectorFilter = filter;
    return this;
  }

  flingEnabled(enabled: boolean): Builder {
    this.mFlingEnabled = enabled;
    return this;
  }

  flingConfig(config: MDFlingConfig | null): Builder {
    this.mFlingConfig = config;
    return this;
  }

  touchSensitivity(touchSensitivity: number): Builder {
    this.mTouchSensitivity = touchSensitivity;
    return this;
  }

  /**
   * build it!
   * @param glView XComponentController
   * @returns vr lib
   */
  build(glView: XComponentController): MDVRLibrary {
    // if (glView instanceof GLSurfaceView) {
    //   return this.build(glView as GLSurfaceView);
    // } else if (glView instanceof GLTextureView) {
    //   return this.build(glView as GLTextureView);
    // } else {
    //   throw new Error("Please ensure the glViewId is instance of GLSurfaceView or GLTextureView");
    // }
    // 在鸿蒙中，直接使用 XComponentController 进行包装
    return this.buildInternal(MDGLScreenWrapper.wrap(glView));
  }

  // build(glSurfaceView: GLSurfaceView): MDVRLibrary {
  //   return this.build(MDGLScreenWrapper.wrap(glSurfaceView));
  // }

  // build(glTextureView: GLTextureView): MDVRLibrary {
  //   return this.build(MDGLScreenWrapper.wrap(glTextureView));
  // }

  private buildInternal(screenWrapper: MDGLScreenWrapper): MDVRLibrary {
    VRUtil.notNull(this.mTexture, "You must call video/bitmap function before build");
    if (this.mDirectorFactory == null) {
      this.mDirectorFactory = new DefaultDirectorFactory();
    }
    if (this.mBarrelDistortionConfig == null) {
      this.mBarrelDistortionConfig = new BarrelDistortionConfig();
    }
    if (this.mPinchConfig == null) {
      this.mPinchConfig = new MDPinchConfig();
    }
    if (this.mFlingConfig == null) {
      this.mFlingConfig = new MDFlingConfig();
    }
    this.mScreenWrapper = screenWrapper;
    return new MDVRLibrary(this);
  }
}

/**
 * 内容类型
 */
export class ContentType {
  public static readonly VIDEO: number = 0;
  public static readonly BITMAP: number = 1;
  public static readonly FBO: number = 2;
  public static readonly CUBEMAP: number = 3;
  public static readonly DEFAULT: number = ContentType.VIDEO;
}

// 重新导出常用接口，供 vrlib 模块外部使用
export { IOnSurfaceReadyCallback, IBitmapProvider };
export { ICubemapProvider } from './texture/MD360CubemapTexture';
export { INotSupportCallback } from './strategy/ModeManager';
export { IDirectorFilter } from './MDDirectorFilter';
export { MDDirectorCamUpdate } from './MDDirectorCamUpdate';

/**
 * 接口定义
 */
export class DirectorFilterAdapter implements IDirectorFilter {
  onFilterPitch(input: number): number {
    return input;
  }

  onFilterYaw(input: number): number {
    return input;
  }

  onFilterRoll(input: number): number {
    return input;
  }
}

class AdvanceGestureListenerImpl implements IAdvanceGestureListener {
  private mInteractiveModeManager: InteractiveModeManager | null;
  private updatePinchRunnable: UpdatePinchRunnable | null;
  private mGLHandler: MDGLHandler | null;

  constructor(manager: InteractiveModeManager | null, runnable: UpdatePinchRunnable, handler: MDGLHandler | null) {
    this.mInteractiveModeManager = manager;
    this.updatePinchRunnable = runnable;
    this.mGLHandler = handler;
  }

  onDrag(distanceX: number, distanceY: number): void {
    this.mInteractiveModeManager?.handleDrag(Math.floor(distanceX), Math.floor(distanceY));
  }

  onPinch(scale: number): void {
    if (!this.updatePinchRunnable || !this.mGLHandler) {
      return;
    }
    this.updatePinchRunnable.setScale(scale);
    this.mGLHandler.post(() => this.updatePinchRunnable?.run());
  }

  destroy(): void {
    this.mInteractiveModeManager = null;
    this.updatePinchRunnable = null;
    this.mGLHandler = null;
  }
}



