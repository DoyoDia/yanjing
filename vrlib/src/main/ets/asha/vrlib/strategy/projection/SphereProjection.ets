/**
 * Created by hzqiujiadi on 16/6/25.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { AbsProjectionStrategy } from './AbsProjectionStrategy';
import { MDMainPluginBuilder } from '../../model/MDMainPluginBuilder';
import { MDPosition } from '../../model/MDPosition';
import { MDObject3DHelper } from '../../objects/MDObject3DHelper';
import { MDSphere3D } from '../../objects/MDSphere3D';
import { MDPanoramaPlugin } from '../../plugins/MDPanoramaPlugin';
import { MDAbsObject3D } from '../../objects/MDAbsObject3D';
import { MDAbsPlugin } from '../../plugins/MDAbsPlugin';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 球体投影策略类
 */
export class SphereProjection extends AbsProjectionStrategy {
  private object3D: MDAbsObject3D | null = null;

  constructor() {
    super();
  }

  getObject3D(): MDAbsObject3D {
    return this.object3D!;
  }

  getModelPosition(): MDPosition {
    return MDPosition.getOriginalPosition();
  }

  turnOnInGL(context: Context): void {
    this.object3D = new MDSphere3D();
    MDObject3DHelper.loadObj(context, this.object3D);
  }

  turnOffInGL(context: Context): void {
    // 空实现
  }

  isSupport(context: Context): boolean {
    return true;
  }

  buildMainPlugin(builder: MDMainPluginBuilder): MDAbsPlugin {
    return new MDPanoramaPlugin(builder);
  }
}

