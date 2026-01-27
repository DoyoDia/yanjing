/**
 * Created by hzqiujiadi on 2017/4/20.
 * hzqiujiadi ashqalcn@gmail.com
 * 
 * 适配器类：将新的 IEyePickListener2 接口适配到旧的 IEyePickListener 接口
 * 
 * 注意：以下类型需要在对应的模块迁移后替换：
 * - MDHitEvent: 应在 model/MDHitEvent 中定义
 * - IMDHotspot: 应在 plugins/hotspot/IMDHotspot 中定义
 */

import { MDHitEvent } from '../model/MDHitEvent';
import { IMDHotspot } from '../plugins/hotspot/IMDHotspot';
import { IEyePickListener, IEyePickListener2 } from '../model/MDTypes';

/**
 * 眼球拾取监听器适配器
 * 用于兼容旧版本的 IEyePickListener 接口
 */
export class CompactEyePickAdapter implements IEyePickListener2 {
  private listener: IEyePickListener | null = null;

  constructor(listener: IEyePickListener | null) {
    this.listener = listener;
  }

  /**
   * 实现 IEyePickListener2 接口
   * @param hitEvent 命中事件
   */
  onHotspotHit(hitEvent: MDHitEvent): void {
    const hotspot = hitEvent.getHotspot();
    if (this.listener != null && hitEvent != null && hotspot != null) {
      this.listener.onHotspotHit(hotspot, hitEvent.getTimestamp());
    }
  }
}

