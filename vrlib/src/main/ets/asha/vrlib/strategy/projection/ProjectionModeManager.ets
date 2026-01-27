/**
 * Created by hzqiujiadi on 16/6/25.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { ModeManager } from '../ModeManager';
import { AbsProjectionStrategy } from './AbsProjectionStrategy';
import { IProjectionMode } from './IProjectionMode';
import { MDGLHandler } from '../../common/MDGLHandler';
import { MDDirection } from '../../common/MDDirection';
import { MDDirectorBrief } from '../../model/MDDirectorBrief';
import { MDMainPluginBuilder } from '../../model/MDMainPluginBuilder';
import { MDPosition } from '../../model/MDPosition';
import { MDPluginAdapter } from '../../plugins/MDPluginAdapter';
import { VRUtil } from '../../common/VRUtil';
import { MD360Director } from '../../MD360Director';
import { MD360DirectorFactory } from '../../MD360DirectorFactory';
import { MDAbsObject3D } from '../../objects/MDAbsObject3D';
import { MDAbsPlugin } from '../../plugins/MDAbsPlugin';
import { IMDProjectionFactory } from './IMDProjectionFactory';
import { Context, RectF } from '../../../../google/android/apps/muzei/render/ViewTypes';

// 导入需要的类
import { SphereProjection } from './SphereProjection';
import { DomeProjection } from './DomeProjection';
import { StereoSphereProjection } from './StereoSphereProjection';
import { PlaneProjection } from './PlaneProjection';
import { MultiFishEyeProjection } from './MultiFishEyeProjection';
import { CubeProjection } from './CubeProjection';

// type RectF = {
//   width(): number;
//   height(): number;
// };
// type Context = any;

/**
 * 投影模式管理器参数
 */
export class ProjectionModeManagerParams {
  public textureSize: RectF | null = null;
  public directorFactory: MD360DirectorFactory | null = null;
  public mainPluginBuilder: MDMainPluginBuilder | null = null;
  public projectionFactory: IMDProjectionFactory | null = null;
}

/**
 * 为避免与 `MDVRLibrary` 的循环依赖，这里本地维护一份投影模式常量。
 * 数值必须与 `MDVRLibrary` 中的 PROJECTION_MODE_* 保持一致。
 */
const PROJECTION_MODE_SPHERE = 201;
const PROJECTION_MODE_DOME180 = 202;
const PROJECTION_MODE_DOME230 = 203;
const PROJECTION_MODE_DOME180_UPPER = 204;
const PROJECTION_MODE_DOME230_UPPER = 205;
const PROJECTION_MODE_STEREO_SPHERE = 206;
const PROJECTION_MODE_PLANE_FIT = 207;
const PROJECTION_MODE_PLANE_CROP = 208;
const PROJECTION_MODE_PLANE_FULL = 209;
const PROJECTION_MODE_MULTI_FISH_EYE_HORIZONTAL = 210;
const PROJECTION_MODE_MULTI_FISH_EYE_VERTICAL = 211;
const PROJECTION_MODE_STEREO_SPHERE_HORIZONTAL = 212;
const PROJECTION_MODE_STEREO_SPHERE_VERTICAL = 213;
const PROJECTION_MODE_CUBE = 214;

/**
 * 投影模式管理器
 */
export class ProjectionModeManager extends ModeManager<AbsProjectionStrategy> implements IProjectionMode {
  public static sModes: number[] = [
    PROJECTION_MODE_SPHERE,
    PROJECTION_MODE_DOME180,
    PROJECTION_MODE_DOME230,
    PROJECTION_MODE_PLANE_FIT
  ];

  private mTextureSize: RectF | null;
  private mCustomDirectorFactory: MD360DirectorFactory | null;
  private mMainPlugin: MDAbsPlugin | null = null;
  private mMainPluginBuilder: MDMainPluginBuilder | null;
  private mProjectionFactory: IMDProjectionFactory | null;
  public readonly mDirectors: MD360Director[];
  public readonly mDirectorBrief: MDDirectorBrief;
  private readonly mDirectorUpdatePlugin: MDAbsPlugin;

  constructor(mode: number, handler: MDGLHandler, projectionManagerParams: ProjectionModeManagerParams) {
    super(mode, handler);
    this.mDirectors = [];
    this.mTextureSize = projectionManagerParams.textureSize;
    this.mCustomDirectorFactory = projectionManagerParams.directorFactory;
    this.mProjectionFactory = projectionManagerParams.projectionFactory;
    this.mMainPluginBuilder = projectionManagerParams.mainPluginBuilder;
    if (this.mMainPluginBuilder != null) {
      this.mMainPluginBuilder.setProjectionModeManager(this);
    }
    this.mDirectorBrief = new MDDirectorBrief();
    this.mDirectorUpdatePlugin = new DirectorUpdatePlugin(this);
  }

  getMainPlugin(): MDAbsPlugin | null {
    if (this.mMainPlugin == null) {
      this.mMainPlugin = this.getStrategy()?.buildMainPlugin(this.mMainPluginBuilder!) || null;
    }
    return this.mMainPlugin;
  }

  override switchMode(context: Context, mode: number): void {
    super.switchMode(context, mode);
  }

  override on(context: Context): void {
    super.on(context);

    // destroy prev main plugin - 同步执行而不是异步，避免资源堆积
    if (this.mMainPlugin != null) {
      try {
        this.mMainPlugin.destroyInGL();
      } catch (e) {
        console.warn('ProjectionModeManager: Failed to destroy main plugin', e);
      }
      this.mMainPlugin = null;
    }

    this.mDirectors.length = 0;

    let factory = this.getStrategy()?.hijackDirectorFactory();
    factory = factory == null ? this.mCustomDirectorFactory : factory;

    // for (let i = 0; i < MDVRLibrary.sMultiScreenSize; i++) {
    for (let i = 0; i < 2; i++) { // 占位实现
      if (factory != null) {
        this.mDirectors.push(factory.createDirector(i));
      }
    }
  }

  protected createStrategy(mode: number): AbsProjectionStrategy {
    if (this.mProjectionFactory != null) {
      const strategy = this.mProjectionFactory.createStrategy(mode);
      if (strategy != null) return strategy;
    }

    switch (mode) {
      case PROJECTION_MODE_DOME180:
        return new DomeProjection(this.mTextureSize!, 180, false);
      case PROJECTION_MODE_DOME230:
        return new DomeProjection(this.mTextureSize!, 230, false);
      case PROJECTION_MODE_DOME180_UPPER:
        return new DomeProjection(this.mTextureSize!, 180, true);
      case PROJECTION_MODE_DOME230_UPPER:
        return new DomeProjection(this.mTextureSize!, 230, true);
      case PROJECTION_MODE_STEREO_SPHERE_HORIZONTAL:
        return new StereoSphereProjection(MDDirection.HORIZONTAL);
      case PROJECTION_MODE_STEREO_SPHERE:
      case PROJECTION_MODE_STEREO_SPHERE_VERTICAL:
        return new StereoSphereProjection(MDDirection.VERTICAL);
      case PROJECTION_MODE_PLANE_FIT:
      case PROJECTION_MODE_PLANE_CROP:
      case PROJECTION_MODE_PLANE_FULL:
        return PlaneProjection.create(mode, this.mTextureSize!);
      case PROJECTION_MODE_MULTI_FISH_EYE_HORIZONTAL:
        return new MultiFishEyeProjection(1.0, MDDirection.HORIZONTAL);
      case PROJECTION_MODE_MULTI_FISH_EYE_VERTICAL:
        return new MultiFishEyeProjection(1.0, MDDirection.VERTICAL);
      case PROJECTION_MODE_CUBE:
        return new CubeProjection();
      case PROJECTION_MODE_SPHERE:
      default:
        return new SphereProjection();
    }
  }

  protected getModes(): number[] {
    return ProjectionModeManager.sModes;
  }

  getModelPosition(): MDPosition {
    return this.getStrategy()?.getModelPosition() || MDPosition.getOriginalPosition();
  }

  getObject3D(): MDAbsObject3D | null {
    return this.getStrategy()?.getObject3D() || null;
  }

  getDirectors(): MD360Director[] {
    return this.mDirectors;
  }

  getDirectorBrief(): MDDirectorBrief {
    return this.mDirectorBrief;
  }

  getDirectorUpdatePlugin(): MDAbsPlugin {
    return this.mDirectorUpdatePlugin;
  }

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   */
  override destroy(): void {
    super.destroy();
    // 销毁所有director
    // ArkTS: MD360Director 没有 destroy 方法，不能调用
    // for (const director of this.mDirectors) {
    //   director.destroy?.();
    // }
    this.mDirectors.length = 0;
    // 销毁主插件
    if (this.mMainPlugin != null) {
      this.mMainPlugin.destroyInGL?.();
      this.mMainPlugin = null;
    }
    // 销毁director更新插件
    if (this.mDirectorUpdatePlugin instanceof DirectorUpdatePlugin) {
      this.mDirectorUpdatePlugin.destroy();
    }
    this.mTextureSize = null;
    this.mCustomDirectorFactory = null;
    this.mMainPluginBuilder = null;
    this.mProjectionFactory = null;
  }
}

/**
 * 导演更新插件类
 * 使用WeakRef避免循环引用导致的内存泄漏
 */
class DirectorUpdatePlugin extends MDPluginAdapter {
  private managerRef: WeakRef<ProjectionModeManager> | null;

  constructor(manager: ProjectionModeManager) {
    super();
    // 使用WeakRef弱引用，避免循环引用
    this.managerRef = new WeakRef(manager);
  }

  override beforeRenderer(totalWidth: number, totalHeight: number): void {
    const manager = this.managerRef?.deref();
    if (!manager) {
      return; // manager已被回收，直接返回
    }
    if (manager.mDirectors.length > 0) {
      manager.mDirectorBrief.make(manager.mDirectors[0].getViewQuaternion());
    }
  }

  destroy(): void {
    this.managerRef = null;
  }
}

