/**
 * Created by hzqiujiadi on 2017/4/12.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDPluginBuilder } from './MDPluginBuilder';
import { MDPosition } from './MDPosition';
import { Context, View } from '../../../google/android/apps/muzei/render/ViewTypes';
import { MDLayoutParams, ITouchPickListener } from './MDTypes';

/**
 * 视图构建器类
 */
export class MDViewBuilder {
  public builderDelegate: MDPluginBuilder;
  public attachedView: View | null = null;
  public layoutParams: MDLayoutParams | null = null;

  constructor() {
    this.builderDelegate = new MDPluginBuilder();
  }

  providerWithSize(view: View, widthInPx: number, heightInPx: number): MDViewBuilder {
    return this.provider(view, { width: widthInPx, height: heightInPx } as MDLayoutParams);
  }

  provider(view: View, layoutParams: MDLayoutParams): MDViewBuilder {
    this.attachedView = view;
    this.layoutParams = layoutParams;
    return this;
  }

  // 委托构建器方法
  title(title: string): MDViewBuilder {
    this.builderDelegate.title(title);
    return this;
  }

  size(width: number, height: number): MDViewBuilder {
    this.builderDelegate.size(width, height);
    return this;
  }

  position(position: MDPosition): MDViewBuilder {
    this.builderDelegate.position(position);
    return this;
  }

  listenClick(listener: ITouchPickListener): MDViewBuilder {
    this.builderDelegate.listenClick(listener);
    return this;
  }

  tag(tag: string): MDViewBuilder {
    this.builderDelegate.tag(tag);
    return this;
  }

  static create(): MDViewBuilder {
    return new MDViewBuilder();
  }
}

