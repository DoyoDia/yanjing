/**
 * 立方体投影策略类
 */

import { AbsProjectionStrategy } from './AbsProjectionStrategy';
import { MDMainPluginBuilder } from '../../model/MDMainPluginBuilder';
import { MDPosition } from '../../model/MDPosition';
import { MDObject3DHelper } from '../../objects/MDObject3DHelper';
import { MDCubeMap } from '../../objects/MDCubeMap';
import { MDPanoramaPlugin } from '../../plugins/MDPanoramaPlugin';
import { MDAbsObject3D } from '../../objects/MDAbsObject3D';
import { MDAbsPlugin } from '../../plugins/MDAbsPlugin';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';

// TODO: 当相关类型迁移后，取消注释并删除类型占位符
// import { MDAbsObject3D } from '../../objects/MDAbsObject3D';
// import { MDAbsPlugin } from '../../plugins/MDAbsPlugin';

// type MDAbsObject3D = any;
// type MDAbsPlugin = any;
// type Context = any;

/**
 * 立方体投影策略类
 */
export class CubeProjection extends AbsProjectionStrategy {
  private object3D: MDAbsObject3D | null = null;

  constructor() {
    super();
  }

  getObject3D(): MDAbsObject3D | null {
    return this.object3D;
  }

  getModelPosition(): MDPosition {
    return MDPosition.getOriginalPosition();
  }

  turnOnInGL(context: Context): void {
    this.object3D = new MDCubeMap();
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

