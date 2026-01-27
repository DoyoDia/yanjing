/**
 * Created by hzqiujiadi on 16/8/7.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDMainHandler } from './common/MDMainHandler';
import { VRUtil } from './common/VRUtil';
import { MDDirectorSnapshot } from './model/MDDirectorSnapshot';
import { MDHitEvent } from './model/MDHitEvent';
import { MDHitPoint } from './model/MDHitPoint';
import { MDRay } from './model/MDRay';
import { MDAbsPlugin } from './plugins/MDAbsPlugin';
import { MDPluginAdapter } from './plugins/MDPluginAdapter';
import { MDPluginManager } from './plugins/MDPluginManager';
import { IMDHotspot } from './plugins/hotspot/IMDHotspot';
import { DisplayModeManager } from './strategy/display/DisplayModeManager';
import { ProjectionModeManager } from './strategy/projection/ProjectionModeManager';
import { MD360Director } from './MD360Director';
import { MDAbsHotspot } from './plugins/hotspot/MDAbsHotspot';
import { IEyePickListener2, ITouchPickListener2, IGestureListener } from './model/MDTypes';
import { MotionEvent } from './AndroidTypes';

// TODO: 当相关类型迁移后，取消注释并删除类型占位符
// import { MDVRLibrary } from './MDVRLibrary';

/**
 * 拾取管理器类
 */
export class MDPickerManager {
  private static readonly TAG: string = "MDPickerManager";
  private static readonly HIT_FROM_EYE: number = 1;
  private static readonly HIT_FROM_TOUCH: number = 2;

  public mEyePickEnable: boolean = false;
  public mDisplayModeManager: DisplayModeManager | null = null;
  public mProjectionModeManager: ProjectionModeManager | null = null;
  public mPluginManager: MDPluginManager | null = null;
  public mEyePickChangedListener: IEyePickListener2 | null = null;
  public mTouchPickListener: ITouchPickListener2 | null = null;
  public mEyePickPoster: EyePickPoster;
  public mTouchPickPoster: TouchPickPoster;
  public mRayPickAsTouchRunnable: RayPickAsTouchMainTask;
  public mRayPickAsEyeRunnable: RayPickAsEyeMainTask;
  public mDirectorContext: DirectorContext;
  public readonly mDirectorLock: object = new Object();
  public mTouchPicker: IGestureListener;

  public mEyePicker: MDAbsPlugin;

  constructor(params: MDPickerManagerBuilder) {
    this.mDisplayModeManager = params.displayModeManager;
    this.mProjectionModeManager = params.projectionModeManager;
    this.mPluginManager = params.pluginManager;

    this.mEyePickPoster = new EyePickPoster(this);
    this.mTouchPickPoster = new TouchPickPoster(this);
    this.mRayPickAsTouchRunnable = new RayPickAsTouchMainTask(this);
    this.mRayPickAsEyeRunnable = new RayPickAsEyeMainTask(this);
    this.mDirectorContext = new DirectorContext();

    this.mTouchPicker = new TouchPickerImpl(this);

    this.mEyePicker = new EyePickerPlugin(this);
  }

  isEyePickEnable(): boolean {
    return this.mEyePickEnable;
  }

  setEyePickEnable(eyePickEnable: boolean): void {
    this.mEyePickEnable = eyePickEnable;
  }

  /**
   * 主线程中调用
   */
  public rayPickAsTouch(x: number, y: number, directorContext: DirectorContext): void {
    const size = this.mDisplayModeManager?.getVisibleSize() || 0;
    if (size === 0) {
      return;
    }

    let snapshot = directorContext.getSnapshot(0);
    if (snapshot == null) {
      return;
    }

    const itemWidth = snapshot.getViewportWidth();

    const index = Math.floor(x / itemWidth);
    if (index >= size) {
      return;
    }

    snapshot = directorContext.getSnapshot(index);
    if (snapshot == null) {
      return;
    }

    const ray = VRUtil.point2Ray(x - itemWidth * index, y, snapshot);

    this.pick(ray, MDPickerManager.HIT_FROM_TOUCH);
  }

  /**
   * 主线程中调用
   */
  rayPickAsEye(directorContext: DirectorContext): void {
    const snapshot = directorContext.getSnapshot(0);
    if (snapshot == null) {
      return;
    }
    const ray = VRUtil.point2Ray(snapshot.getViewportWidth() / 2, snapshot.getViewportHeight() / 2, snapshot);

    this.pick(ray, MDPickerManager.HIT_FROM_EYE);
  }

  private pick(ray: MDRay | null, hitType: number): IMDHotspot | null {
    if (ray == null) return null;
    return this.hitTest(ray, hitType);
  }

  private hitTest(ray: MDRay, hitType: number): IMDHotspot | null {
    // 主线程
    VRUtil.checkMainThread("hitTest must in main thread");

    const plugins = this.mPluginManager?.getPlugins() || [];
    let hitHotspot: IMDHotspot | null = null;
    let currentDistance = MDHitPoint.notHit();

    for (const plugin of plugins) {
      if (plugin instanceof MDAbsHotspot) {
        const hotspot = plugin as MDAbsHotspot;
        const tmpDistance = hotspot.hit(ray);
        if (!tmpDistance.isNotHit() && tmpDistance.nearThen(currentDistance)) {
          hitHotspot = hotspot;
          currentDistance = tmpDistance;
        }
      }
    }

    switch (hitType) {
      case MDPickerManager.HIT_FROM_TOUCH:
        // 只发送被击中的热点
        if (hitHotspot != null && !currentDistance.isNotHit()) {
          hitHotspot.onTouchHit(ray);
          this.mTouchPickPoster.fire(hitHotspot, ray, currentDistance);
        }
        break;
      case MDPickerManager.HIT_FROM_EYE:
        this.mEyePickPoster.fire(hitHotspot, ray, currentDistance);
        break;
    }

    return hitHotspot;
  }

  getTouchPicker(): IGestureListener {
    return this.mTouchPicker;
  }

  getEyePicker(): MDAbsPlugin {
    return this.mEyePicker;
  }

  static with(): MDPickerManagerBuilder {
    return new MDPickerManagerBuilder();
  }

  setEyePickChangedListener(eyePickChangedListener: IEyePickListener2 | null): void {
    this.mEyePickChangedListener = eyePickChangedListener;
  }

  setTouchPickListener(touchPickListener: ITouchPickListener2 | null): void {
    this.mTouchPickListener = touchPickListener;
  }

  resetEyePick(): void {
    if (this.mEyePickPoster != null) {
      this.mEyePickPoster.setHit(null);
    }
  }

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   */
  destroy(): void {
    this.mDisplayModeManager = null;
    this.mProjectionModeManager = null;
    this.mPluginManager = null;
    this.mEyePickChangedListener = null;
    this.mTouchPickListener = null;
    // 销毁内部组件
    this.mEyePickPoster?.destroy?.();
    this.mTouchPickPoster?.destroy?.();
    this.mRayPickAsTouchRunnable?.destroy?.();
    this.mRayPickAsEyeRunnable?.destroy?.();
    (this.mTouchPicker as TouchPickerImpl)?.destroy?.();
    (this.mEyePicker as EyePickerPlugin)?.destroy?.();
  }
}

/**
 * 构建器类
 */
export class MDPickerManagerBuilder {
  displayModeManager: DisplayModeManager | null = null;
  projectionModeManager: ProjectionModeManager | null = null;
  pluginManager: MDPluginManager | null = null;

  constructor() {
  }

  build(): MDPickerManager {
    return new MDPickerManager(this);
  }

  setPluginManager(pluginManager: MDPluginManager): MDPickerManagerBuilder {
    this.pluginManager = pluginManager;
    return this;
  }

  setDisplayModeManager(displayModeManager: DisplayModeManager): MDPickerManagerBuilder {
    this.displayModeManager = displayModeManager;
    return this;
  }

  setProjectionModeManager(projectionModeManager: ProjectionModeManager): MDPickerManagerBuilder {
    this.projectionModeManager = projectionModeManager;
    return this;
  }
}

/**
 * 触摸拾取主任务类
 * 使用WeakRef避免循环引用导致的内存泄漏
 */
export class RayPickAsTouchMainTask {
  private x: number = 0;
  private y: number = 0;
  private managerRef: WeakRef<MDPickerManager> | null;

  constructor(manager: MDPickerManager) {
    this.managerRef = new WeakRef(manager);
  }

  setEvent(x: number, y: number): void {
    this.x = x;
    this.y = y;
  }

  run(): void {
    const manager = this.managerRef?.deref();
    if (!manager) return;
    // 在ETS中，可以使用锁或其他同步机制
    manager.rayPickAsTouch(this.x, this.y, manager.mDirectorContext);
  }

  destroy(): void {
    this.managerRef = null;
  }
}

/**
 * 眼睛拾取主任务类
 * 使用WeakRef避免循环引用导致的内存泄漏
 */
export class RayPickAsEyeMainTask {
  private managerRef: WeakRef<MDPickerManager> | null;

  constructor(manager: MDPickerManager) {
    this.managerRef = new WeakRef(manager);
  }

  run(): void {
    const manager = this.managerRef?.deref();
    if (!manager) return;
    // 在ETS中，可以使用锁或其他同步机制
    manager.rayPickAsEye(manager.mDirectorContext);
  }

  destroy(): void {
    this.managerRef = null;
  }
}

/**
 * 眼睛拾取发布者类
 * 使用WeakRef避免循环引用导致的内存泄漏
 */
export class EyePickPoster {
  private hit: IMDHotspot | null = null;
  private timestamp: number = 0;
  private managerRef: WeakRef<MDPickerManager> | null;

  constructor(manager: MDPickerManager) {
    this.managerRef = new WeakRef(manager);
  }

  fire(hit: IMDHotspot | null, ray: MDRay, hitPoint: MDHitPoint): void {
    const manager = this.managerRef?.deref();
    this.setHit(hit);

    const event = MDHitEvent.obtain();
    event.setHotspot(hit);
    event.setRay(ray);
    event.setTimestamp(this.timestamp);
    event.setHitPoint(hitPoint);

    if (this.hit != null) {
      this.hit.onEyeHitIn(event);
    }

    if (manager?.mEyePickChangedListener != null) {
      manager.mEyePickChangedListener.onHotspotHit(event);
    }

    MDHitEvent.recycle(event);
  }

  setHit(hit: IMDHotspot | null): void {
    if (this.hit !== hit) {
      if (this.hit != null) {
        this.hit.onEyeHitOut(this.timestamp);
      }

      this.timestamp = Date.now();
    }

    this.hit = hit;
  }

  destroy(): void {
    this.hit = null;
    this.managerRef = null;
  }
}

/**
 * 触摸拾取发布者类
 * 使用WeakRef避免循环引用导致的内存泄漏
 */
export class TouchPickPoster {
  private managerRef: WeakRef<MDPickerManager> | null;

  constructor(manager: MDPickerManager) {
    this.managerRef = new WeakRef(manager);
  }

  fire(hitHotspot: IMDHotspot | null, ray: MDRay, hitPoint: MDHitPoint): void {
    const manager = this.managerRef?.deref();
    if (manager?.mTouchPickListener != null) {
      const event = MDHitEvent.obtain();
      event.setHotspot(hitHotspot);
      event.setRay(ray);
      event.setTimestamp(Date.now());
      event.setHitPoint(hitPoint);
      manager.mTouchPickListener.onHotspotHit(event);
      MDHitEvent.recycle(event);
    }
  }

  destroy(): void {
    this.managerRef = null;
  }
}

/**
 * 导演上下文类
 */
export class DirectorContext {
  private size: number = 0;
  private list: MDDirectorSnapshot[] = [];

  snapshot(directorList: MD360Director[]): void {
    VRUtil.checkGLThread("snapshot must in gl thread!");

    this.ensureSize(directorList.length);
    for (let i = 0; i < directorList.length; i++) {
      this.list[i].copy(directorList[i]);
    }
  }

  private ensureSize(size: number): void {
    this.size = size;

    while (this.list.length < size) {
      this.list.push(new MDDirectorSnapshot());
    }
  }

  getSnapshot(i: number): MDDirectorSnapshot | null {
    if (i < this.size) {
      return this.list[0];
    }

    return null;
  }
}

class TouchPickerImpl implements IGestureListener {
  private managerRef: WeakRef<MDPickerManager> | null;

  constructor(manager: MDPickerManager) {
    this.managerRef = new WeakRef(manager);
  }

  onClick(e: MotionEvent): void {
    const manager = this.managerRef?.deref();
    if (!manager) return;
    manager.mRayPickAsTouchRunnable.setEvent(e.getX(), e.getY());
    manager.mRayPickAsTouchRunnable.run();
  }

  destroy(): void {
    this.managerRef = null;
  }
}

class EyePickerPlugin extends MDPluginAdapter {
  private pickTs: number = 0;
  private managerRef: WeakRef<MDPickerManager> | null;
  // 预创建的任务引用，避免每次创建新闭包
  private eyePickTaskRef: (() => void) | null;

  constructor(manager: MDPickerManager) {
    super();
    this.managerRef = new WeakRef(manager);
    this.eyePickTaskRef = () => {
      const mgr = this.managerRef?.deref();
      if (mgr) {
        mgr.mRayPickAsEyeRunnable.run();
      }
    };
  }

  override beforeRenderer(totalWidth: number, totalHeight: number): void {
    const manager = this.managerRef?.deref();
    if (!manager) return;
    // 在ETS中，可以使用锁或其他同步机制
    manager.mDirectorContext.snapshot(manager.mProjectionModeManager?.getDirectors() || []);

    if (manager.isEyePickEnable()) {
      const current = Date.now();
      if (current - this.pickTs > 100) {
        if (this.eyePickTaskRef) {
          MDMainHandler.sharedHandler().post(this.eyePickTaskRef);
        }
        this.pickTs = current;
      }
    }
  }

  destroy(): void {
    this.managerRef = null;
    this.eyePickTaskRef = null;
  }
}

