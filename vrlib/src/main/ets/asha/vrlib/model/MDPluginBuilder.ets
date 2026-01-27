/**
 * Created by hzqiujiadi on 2017/4/12.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDPosition } from './MDPosition';
import { ITouchPickListener } from './MDTypes';

/**
 * 插件构建器类
 */
export class MDPluginBuilder {
  public mWidth: number = 2;
  public mHeight: number = 2;
  public mTag: string | null = null;
  public mTitle: string | null = null;
  public mClickListener: ITouchPickListener | null = null;
  public mPosition: MDPosition | null = null;

  constructor() {
  }

  title(title: string): MDPluginBuilder {
    this.mTitle = title;
    return this;
  }

  size(width: number, height: number): MDPluginBuilder {
    this.mWidth = width;
    this.mHeight = height;
    return this;
  }

  position(position: MDPosition): MDPluginBuilder {
    this.mPosition = position;
    return this;
  }

  listenClick(listener: ITouchPickListener): MDPluginBuilder {
    this.mClickListener = listener;
    return this;
  }

  tag(tag: string): MDPluginBuilder {
    this.mTag = tag;
    return this;
  }
}

