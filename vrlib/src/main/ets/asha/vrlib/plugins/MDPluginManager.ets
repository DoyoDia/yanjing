/**
 * Created by hzqiujiadi on 16/7/22.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsPlugin } from './MDAbsPlugin';

import { IMDHotspot } from './hotspot/IMDHotspot';
import { MDAbsView } from './hotspot/MDAbsView';
import { MDAbsHotspot } from './hotspot/MDAbsHotspot';

// type IMDHotspot = any;
// type MDAbsView = any;

/**
 * 插件管理器类
 */
export class MDPluginManager {
  private static readonly TAG: string = "MDPluginManager";

  private mList: MDAbsPlugin[] = [];

  constructor() {
    this.mList = [];
  }

  /**
   * 添加插件
   * @param plugin 插件对象
   */
  add(plugin: MDAbsPlugin): void {
    this.mList.push(plugin);
  }

  /**
   * 获取所有插件
   */
  getPlugins(): MDAbsPlugin[] {
    return this.mList;
  }

  /**
   * 移除插件
   * @param plugin 插件对象
   */
  remove(plugin: MDAbsPlugin): void {
    if (plugin != null) {
      const index = this.mList.indexOf(plugin);
      if (index >= 0) {
        this.mList.splice(index, 1);
      }
    }
  }

  /**
   * 移除所有可移除的插件
   */
  removeAll(): void {
    this.mList = this.mList.filter(plugin => !plugin.removable());
  }

  /**
   * 根据标签查找热点
   * @param tag 标签
   */
  findHotspotByTag(tag: string | null): IMDHotspot | null {
    if (tag == null) return null;
    
    for (const plugin of this.mList) {
      if (plugin.removable() && this.isIMDHotspot(plugin)) {
        const hotspot = plugin as Object as IMDHotspot;
        if (hotspot.getTag() === tag) {
          return hotspot;
        }
      }
    }
    return null;
  }

  /**
   * 根据标签查找视图
   * @param tag 标签
   */
  findViewByTag(tag: string | null): MDAbsView | null {
    if (tag == null) return null;
    
    for (const plugin of this.mList) {
      if (plugin.removable() && this.isMDAbsView(plugin)) {
        const mdView = plugin as Object as MDAbsView;
        if (mdView.getTag() === tag) {
          return mdView;
        }
      }
    }
    return null;
  }

  private isIMDHotspot(plugin: MDAbsPlugin): boolean {
    return plugin instanceof MDAbsHotspot;
  }

  private isMDAbsView(plugin: MDAbsPlugin): boolean {
    return plugin instanceof MDAbsView;
  }

  /**
   * 销毁方法，清理所有插件和引用防止内存泄漏
   */
  destroy(): void {
    // 销毁所有插件
    for (const plugin of this.mList) {
      try {
        plugin.destroyInGL?.();
      } catch (e) {
        console.warn('MDPluginManager: Failed to destroy plugin', e);
      }
    }
    this.mList.length = 0;
  }
}

