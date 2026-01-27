/**
 * Created by hzqiujiadi on 2017/4/20.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDRay } from './MDRay';
import { MDHitPoint } from './MDHitPoint';
import { IMDHotspot } from '../plugins/hotspot/IMDHotspot';

/**
 * 命中事件类
 * 使用对象池模式管理实例
 */
export class MDHitEvent {
  private static sPool: MDHitEvent[] = [];

  private hotspot: IMDHotspot | null = null;
  private timestamp: number = 0;
  private ray: MDRay | null = null;
  private hitPoint: MDHitPoint | null = null;

  getHotspot(): IMDHotspot | null {
    return this.hotspot;
  }

  setHotspot(hotspot: IMDHotspot | null): void {
    this.hotspot = hotspot;
  }

  getTimestamp(): number {
    return this.timestamp;
  }

  setTimestamp(timestamp: number): void {
    this.timestamp = timestamp;
  }

  getRay(): MDRay | null {
    return this.ray;
  }

  setRay(ray: MDRay | null): void {
    this.ray = ray;
  }

  getHitPoint(): MDHitPoint | null {
    return this.hitPoint;
  }

  setHitPoint(hitPoint: MDHitPoint | null): void {
    this.hitPoint = hitPoint;
  }

  /**
   * 从对象池获取实例
   */
  static obtain(): MDHitEvent {
    const event = MDHitEvent.sPool.pop();
    if (event == null) {
      return new MDHitEvent();
    }
    return event;
  }

  /**
   * 回收实例到对象池
   */
  static recycle(event: MDHitEvent): void {
    event.hotspot = null;
    event.timestamp = 0;
    event.ray = null;
    event.hitPoint = null;
    MDHitEvent.sPool.push(event);
  }
}

