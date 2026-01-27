/**
 * Created by hzqiujiadi on 16/6/25.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { IModeStrategy } from '../IModeStrategy';
import { IProjectionMode } from './IProjectionMode';
import { MDMainPluginBuilder } from '../../model/MDMainPluginBuilder';
import { MDAbsObject3D } from '../../objects/MDAbsObject3D';
import { MDPosition } from '../../model/MDPosition';

import { MD360DirectorFactory } from '../../MD360DirectorFactory';
import { MDAbsPlugin } from '../../plugins/MDAbsPlugin';
import { Context } from '../../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 抽象投影策略类
 */
export abstract class AbsProjectionStrategy implements IModeStrategy, IProjectionMode {
  onResume(context: Context): void {
    // 空实现，子类可重写
  }

  onPause(context: Context): void {
    // 空实现，子类可重写
  }

  abstract turnOnInGL(context: Context): void;
  abstract turnOffInGL(context: Context): void;
  abstract isSupport(context: Context): boolean;
  abstract getObject3D(): MDAbsObject3D | null;
  abstract getModelPosition(): MDPosition;

  /**
   * 劫持导演工厂（子类可重写）
   */
  public hijackDirectorFactory(): MD360DirectorFactory | null {
    return null;
  }

  /**
   * 构建主插件（子类实现）
   * @param builder 主插件构建器
   */
  abstract buildMainPlugin(builder: MDMainPluginBuilder): MDAbsPlugin;
}

