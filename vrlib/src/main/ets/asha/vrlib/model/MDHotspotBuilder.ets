/**
 * Created by hzqiujiadi on 16/8/10.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDPluginBuilder } from './MDPluginBuilder';
import { MDPosition } from './MDPosition';
import { MDUtil } from '../common/MDUtil';
import { ITouchPickListener } from './MDTypes';

/**
 * 图片加载提供者接口（精简版）
 * 在 HarmonyOS 适配中，我们只需要一个简单的回调签名，实际加载逻辑由应用侧实现。
 */
export interface IImageLoadProvider {
  onProvideBitmap(uri: string, callback: (bitmap: object) => void): void;
}

/**
 * 热点构建器类
 */
export class MDHotspotBuilder {
  public builderDelegate: MDPluginBuilder;
  public uriList: Map<number, string> = new Map();
  public statusList: number[] | null = null;
  public checkedStatusList: number[] | null = null;
  public imageLoadProvider: IImageLoadProvider | null = null;

  static create(imageLoadProvider: IImageLoadProvider): MDHotspotBuilder {
    return new MDHotspotBuilder(imageLoadProvider);
  }

  constructor(imageLoadProvider: IImageLoadProvider | null) {
    this.imageLoadProvider = imageLoadProvider;
    this.builderDelegate = new MDPluginBuilder();
  }

  /**
   * 统一设置未选中状态的三种图片（normal / focused / pressed）。
   * 通过可选参数，兼容原来的多种重载写法。
   */
  private setStatus(normal: number, focused: number, pressed: number): MDHotspotBuilder {
    this.statusList = [normal, focused, pressed];
    return this;
  }

  status(normal: number, focused?: number, pressed?: number): MDHotspotBuilder {
    if (focused === undefined && pressed === undefined) {
      // 只有 normal：三个状态都用 normal
      return this.setStatus(normal, normal, normal);
    }
    if (pressed === undefined) {
      // normal + focused：pressed 与 focused 一致
      return this.setStatus(normal, focused!, focused!);
    }
    // 三个参数都传入
    return this.setStatus(normal, focused!, pressed);
  }

  /**
   * 统一设置“选中”状态的三种图片。
   */
  private setCheckedStatus(normal: number, focused: number, pressed: number): MDHotspotBuilder {
    this.checkedStatusList = [normal, focused, pressed];
    return this;
  }

  checkedStatus(normal: number, focused?: number, pressed?: number): MDHotspotBuilder {
    if (focused === undefined && pressed === undefined) {
      return this.setCheckedStatus(normal, normal, normal);
    }
    if (pressed === undefined) {
      return this.setCheckedStatus(normal, focused!, focused!);
    }
    return this.setCheckedStatus(normal, focused!, pressed);
  }

  /**
   * 注册图片资源。
   * - provider(uri)                  → 使用 key = 0
   * - provider(key, uri)            → 显式指定 key
   */
  provider(keyOrUri: number | string, maybeUri?: string): MDHotspotBuilder {
    if (typeof keyOrUri === 'string') {
      // 只有 uri，默认 key = 0
      this.uriList.set(0, keyOrUri);
    } else if (typeof keyOrUri === 'number' && typeof maybeUri === 'string') {
      this.uriList.set(keyOrUri, maybeUri);
    }
    return this;
  }

  // 委托方法
  title(title: string): MDHotspotBuilder {
    this.builderDelegate.title(title);
    return this;
  }

  size(width: number, height: number): MDHotspotBuilder {
    this.builderDelegate.size(width, height);
    return this;
  }

  position(position: MDPosition): MDHotspotBuilder {
    this.builderDelegate.position(position);
    return this;
  }

  listenClick(listener: ITouchPickListener): MDHotspotBuilder {
    this.builderDelegate.listenClick(listener);
    return this;
  }

  tag(tag: string): MDHotspotBuilder {
    this.builderDelegate.tag(tag);
    return this;
  }
}

