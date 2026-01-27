/**
 * Created by hzqiujiadi on 16/7/29.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { SphereProjection } from './SphereProjection';
import { MDMainPluginBuilder } from '../../model/MDMainPluginBuilder';
import { MDDirection } from '../../common/MDDirection';
import { MDMultiFishEyePlugin } from '../../plugins/MDMultiFishEyePlugin';
import { MDAbsPlugin } from '../../plugins/MDAbsPlugin';

// TODO: 当相关类型迁移后，取消注释并删除类型占位符
// import { MDAbsPlugin } from '../../plugins/MDAbsPlugin';

// type MDAbsPlugin = any;

/**
 * 多鱼眼投影策略类
 */
export class MultiFishEyeProjection extends SphereProjection {
  private radius: number;
  private direction: MDDirection;

  constructor(radius: number, direction: MDDirection) {
    super();
    this.radius = radius;
    this.direction = direction;
  }

  override buildMainPlugin(builder: MDMainPluginBuilder): MDAbsPlugin {
    return new MDMultiFishEyePlugin(builder, this.radius, this.direction);
  }
}

