/**
 * Created by hzqiujiadi on 16/6/26.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { AbsProjectionStrategy } from './AbsProjectionStrategy';
import { MDMainPluginBuilder } from '../../model/MDMainPluginBuilder';
import { MDPosition } from '../../model/MDPosition';
import { MDDirection } from '../../common/MDDirection';
import { MDObject3DHelper } from '../../objects/MDObject3DHelper';
import { MDStereoSphere3D } from '../../objects/MDStereoSphere3D';
import { MDPanoramaPlugin } from '../../plugins/MDPanoramaPlugin';
import { MD360DirectorFactory } from '../../MD360DirectorFactory';
import { MD360Director } from '../../MD360Director';
import { MDAbsObject3D } from '../../objects/MDAbsObject3D';
import { MDAbsPlugin } from '../../plugins/MDAbsPlugin';

import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 立体球体投影策略类
 */
export class StereoSphereProjection extends AbsProjectionStrategy {
  private direction: MDDirection;
  private object3D: MDAbsObject3D | null = null;

  constructor(direction: MDDirection) {
    super();
    this.direction = direction;
  }

  turnOnInGL(context: Context): void {
    this.object3D = new MDStereoSphere3D(this.direction);
    MDObject3DHelper.loadObj(context, this.object3D!);
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

  // 必须与基类保持同样的可见性（public），否则 ArkTS 会报继承错误
  public hijackDirectorFactory(): MD360DirectorFactory | null {
    return new FixedDirectorFactory();
  }

  buildMainPlugin(builder: MDMainPluginBuilder): MDAbsPlugin {
    return new MDPanoramaPlugin(builder);
  }
}

/**
 * 固定导演工厂类
 */
class FixedDirectorFactory extends MD360DirectorFactory {
  override createDirector(index: number): MD360Director {
    return MD360Director.builder().build();
  }
}

