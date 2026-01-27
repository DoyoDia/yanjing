/**
 * Created by hzqiujiadi on 2017/4/20.
 * hzqiujiadi ashqalcn@gmail.com
 * 
 * 适配器类：将新的 ITouchPickListener2 接口适配到旧的 ITouchPickListener 接口
 * 
 * 注意：以下类型需要在对应的模块迁移后替换：
 * - MDHitEvent: 应在 model/MDHitEvent 中定义
 * - IMDHotspot: 应在 plugins/hotspot/IMDHotspot 中定义
 * - MDRay: 应在 model/MDRay 中定义
 */

import { MDHitEvent } from '../model/MDHitEvent';
import { ITouchPickListener, ITouchPickListener2 } from '../model/MDTypes';

/**
 * 触摸拾取监听器适配器
 * 用于兼容旧版本的 ITouchPickListener 接口
 */
export class CompactTouchPickAdapter implements ITouchPickListener2 {
  private listener: ITouchPickListener | null = null;

  constructor(listener: ITouchPickListener | null) {
    this.listener = listener;
  }

  /**
   * 实现 ITouchPickListener2 接口
   * @param hitEvent 命中事件
   */
  onHotspotHit(hitEvent: MDHitEvent): void {
    if (this.listener != null && hitEvent != null) {
      const hotspot = hitEvent.getHotspot();
      const ray = hitEvent.getRay();
      if (hotspot != null && ray != null) {
        this.listener.onHotspotHit(hotspot, ray);
      }
    }
  }
}

