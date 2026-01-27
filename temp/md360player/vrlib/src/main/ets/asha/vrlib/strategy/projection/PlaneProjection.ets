/**
 * Created by hzqiujiadi on 16/6/26.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { AbsProjectionStrategy } from './AbsProjectionStrategy';
import { MDMainPluginBuilder } from '../../model/MDMainPluginBuilder';
import { MDPosition } from '../../model/MDPosition';
import { MDObject3DHelper } from '../../objects/MDObject3DHelper';
import { MDPlane, PlaneScaleCalculator } from '../../objects/MDPlane';
import { MDPanoramaPlugin } from '../../plugins/MDPanoramaPlugin';
import { MD360DirectorFactory, OrthogonalDirectorFactory } from '../../MD360DirectorFactory';
import { MD360Director, Builder as MD360DirectorBuilder } from '../../MD360Director';
import { MDVRLibrary } from '../../MDVRLibrary';
import { MDAbsObject3D } from '../../objects/MDAbsObject3D';
import { MDAbsPlugin } from '../../plugins/MDAbsPlugin';
import { Context, RectF } from '../../../../google/android/apps/muzei/render/ViewTypes';
import { MDMutablePosition } from '../../model/position/MDMutablePosition';
import { MatrixUtil } from '../../common/MatrixUtil';

/**
 * 平面投影策略类
 */
export class PlaneProjection extends AbsProjectionStrategy {
  private object3D: MDPlane | null = null;
  private planeScaleCalculator: PlaneScaleCalculator;
  private static readonly position: MDPosition = MDMutablePosition.newInstance().setZ(-2.0);

  private constructor(calculator: PlaneScaleCalculator) {
    super();
    this.planeScaleCalculator = calculator;
  }

  turnOnInGL(context: Context): void {
    this.object3D = new MDPlane(this.planeScaleCalculator);
    MDObject3DHelper.loadObj(context, this.object3D);
  }

  turnOffInGL(context: Context): void {
    // 空实现
  }

  isSupport(context: Context): boolean {
    return true;
  }

  getObject3D(): MDAbsObject3D {
    return this.object3D!;
  }

  getModelPosition(): MDPosition {
    return PlaneProjection.position;
  }

  buildMainPlugin(builder: MDMainPluginBuilder): MDAbsPlugin {
    return new MDPanoramaPlugin(builder);
  }

  // 必须与基类保持同样的可见性（public），否则 ArkTS 会报继承错误
  public hijackDirectorFactory(): MD360DirectorFactory | null {
    return new OrthogonalDirectorFactoryImpl(this.planeScaleCalculator);
  }

  /**
   * 创建平面投影
   * @param scaleType 缩放类型
   * @param textureSize 纹理大小
   */
  static create(scaleType: number, textureSize: RectF): PlaneProjection {
    return new PlaneProjection(new PlaneScaleCalculatorImpl(scaleType, textureSize));
  }
}

/**
 * 平面缩放计算器类
 */
export class PlaneScaleCalculatorImpl implements PlaneScaleCalculator {
  private static readonly sBaseValue: number = 1.0;

  private mTextureSize: RectF;
  private mViewportRatio: number = 0;
  private mScaleType: number;
  private mViewportWidth: number = PlaneScaleCalculatorImpl.sBaseValue;
  private mViewportHeight: number = PlaneScaleCalculatorImpl.sBaseValue;
  private mTextureWidth: number = PlaneScaleCalculatorImpl.sBaseValue;
  private mTextureHeight: number = PlaneScaleCalculatorImpl.sBaseValue;

  constructor(scaleType: number, textureSize: RectF) {
    this.mScaleType = scaleType;
    this.mTextureSize = textureSize;
  }

  getTextureRatio(): number {
    return this.mTextureSize.width() / this.mTextureSize.height();
  }

  setViewportRatio(viewportRatio: number): void {
    this.mViewportRatio = viewportRatio;
  }

  calculate(): void {
    const viewportRatio = this.mViewportRatio;
    const textureRatio = this.getTextureRatio();

    switch (this.mScaleType) {
      case MDVRLibrary.PROJECTION_MODE_PLANE_FULL:
        // fullscreen
        this.mViewportWidth = this.mViewportHeight = this.mTextureWidth = this.mTextureHeight = PlaneScaleCalculatorImpl.sBaseValue;
        break;
      case MDVRLibrary.PROJECTION_MODE_PLANE_CROP:
        if (textureRatio > viewportRatio) {
          // crop width of texture
          this.mViewportWidth = PlaneScaleCalculatorImpl.sBaseValue * viewportRatio;
          this.mViewportHeight = PlaneScaleCalculatorImpl.sBaseValue;
          this.mTextureWidth = PlaneScaleCalculatorImpl.sBaseValue * textureRatio;
          this.mTextureHeight = PlaneScaleCalculatorImpl.sBaseValue;
        } else {
          // crop height of texture
          this.mViewportWidth = PlaneScaleCalculatorImpl.sBaseValue;
          this.mViewportHeight = PlaneScaleCalculatorImpl.sBaseValue / viewportRatio;
          this.mTextureWidth = PlaneScaleCalculatorImpl.sBaseValue;
          this.mTextureHeight = PlaneScaleCalculatorImpl.sBaseValue / textureRatio;
        }
        break;
      case MDVRLibrary.PROJECTION_MODE_PLANE_FIT:
      default:
        if (viewportRatio > textureRatio) {
          // fit height of viewport
          this.mViewportWidth = PlaneScaleCalculatorImpl.sBaseValue * viewportRatio;
          this.mViewportHeight = PlaneScaleCalculatorImpl.sBaseValue;
          this.mTextureWidth = PlaneScaleCalculatorImpl.sBaseValue * textureRatio;
          this.mTextureHeight = PlaneScaleCalculatorImpl.sBaseValue;
        } else {
          // fit width of viewport
          this.mViewportWidth = PlaneScaleCalculatorImpl.sBaseValue;
          this.mViewportHeight = PlaneScaleCalculatorImpl.sBaseValue / viewportRatio;
          this.mTextureWidth = PlaneScaleCalculatorImpl.sBaseValue;
          this.mTextureHeight = PlaneScaleCalculatorImpl.sBaseValue / textureRatio;
        }
        break;
    }
  }

  getViewportWidth(): number {
    return this.mViewportWidth;
  }

  getViewportHeight(): number {
    return this.mViewportHeight;
  }

  getTextureWidth(): number {
    return this.mTextureWidth;
  }

  getTextureHeight(): number {
    return this.mTextureHeight;
  }
}

/**
 * 正交导演工厂类
 */
class OrthogonalDirectorFactoryImpl extends OrthogonalDirectorFactory {
  private planeScaleCalculator: PlaneScaleCalculatorImpl;

  constructor(calculator: PlaneScaleCalculator) {
    super();
    this.planeScaleCalculator = calculator as PlaneScaleCalculatorImpl;
  }

  override createDirector(index: number): MD360Director {
    const builder = new MD360DirectorBuilder();
    return new OrthogonalDirector(builder, this.planeScaleCalculator);
  }
}

/**
 * 正交导演类
 * 注意：这个类依赖于MD360Director，需要在MD360Director迁移后完善
 */
class OrthogonalDirector extends MD360Director {
  private sNearBase: number;
  private planeScaleCalculator: PlaneScaleCalculatorImpl;

  constructor(builder: MD360DirectorBuilder, calculator: PlaneScaleCalculatorImpl) {
    super(builder);
    this.sNearBase = this.getNear();
    this.planeScaleCalculator = calculator;
  }

  setDeltaX(mDeltaX: number): void {
    // nop
  }

  setDeltaY(mDeltaY: number): void {
    // nop
  }

  updateSensorMatrix(sensorMatrix: number[]): void {
    // nop
  }

  override beforeShot(): void {
    // 对于正交投影，总是更新投影矩阵（因为 viewport 可能已经改变）
    // 先调用父类方法更新视图矩阵
    this.updateViewMatrixIfNeed();
    // 然后强制更新投影矩阵
    this.updateProjection();
  }

  protected updateProjection(): void {
    this.planeScaleCalculator.setViewportRatio(this.getRatio());
    this.planeScaleCalculator.calculate();
    const scale = this.sNearBase / this.getNear();
    const left = -this.planeScaleCalculator.getViewportWidth() / 2 * scale;
    const right = this.planeScaleCalculator.getViewportWidth() / 2 * scale;
    const bottom = -this.planeScaleCalculator.getViewportHeight() / 2 * scale;
    const top = this.planeScaleCalculator.getViewportHeight() / 2 * scale;
    const far = 500;
    MatrixUtil.orthoM(this.getProjectionMatrix(), 0, left, right, bottom, top, 1, far);
  }
}

