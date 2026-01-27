/**
 * Created by hzqiujiadi on 16/6/25.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { AbsProjectionStrategy } from './AbsProjectionStrategy';
import { MDMainPluginBuilder } from '../../model/MDMainPluginBuilder';
import { MDPosition } from '../../model/MDPosition';
import { MDObject3DHelper } from '../../objects/MDObject3DHelper';
import { MDDome3D } from '../../objects/MDDome3D';
import { MDPanoramaPlugin } from '../../plugins/MDPanoramaPlugin';
import { MDAbsObject3D } from '../../objects/MDAbsObject3D';
import { MDAbsPlugin } from '../../plugins/MDAbsPlugin';
import { Context, RectF } from '../../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 圆顶投影策略类
 */
export class DomeProjection extends AbsProjectionStrategy {
  private object3D: MDAbsObject3D | null = null;
  private mDegree: number;
  private mIsUpper: boolean;
  private mTextureSize: RectF;

  constructor(textureSize: RectF, degree: number, isUpper: boolean) {
    super();
    this.mTextureSize = textureSize;
    this.mDegree = degree;
    this.mIsUpper = isUpper;
  }

  turnOnInGL(context: Context): void {
    this.object3D = new MDDome3D(this.mTextureSize, this.mDegree, this.mIsUpper);
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
    return MDPosition.getOriginalPosition();
  }

  buildMainPlugin(builder: MDMainPluginBuilder): MDAbsPlugin {
    return new MDPanoramaPlugin(builder);
  }
}

