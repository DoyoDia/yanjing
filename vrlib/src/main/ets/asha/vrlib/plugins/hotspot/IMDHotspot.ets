/**
 * Created by hzqiujiadi on 16/8/5.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDHitPoint } from '../../model/MDHitPoint';
import { MDRay } from '../../model/MDRay';
import { MDHitEvent } from '../../model/MDHitEvent';

/**
 * 热点接口
 */
export interface IMDHotspot {
  /**
   * 射线命中检测
   * @param ray 射线
   * @returns 命中点
   */
  hit(ray: MDRay): MDHitPoint;

  /**
   * 眼球命中进入
   * @param hitEvent 命中事件
   */
  onEyeHitIn(hitEvent: MDHitEvent): void;

  /**
   * 眼球命中退出
   * @param timestamp 时间戳
   */
  onEyeHitOut(timestamp: number): void;

  /**
   * 触摸命中
   * @param ray 射线
   */
  onTouchHit(ray: MDRay): void;

  /**
   * 获取标题
   */
  getTitle(): string | null;

  /**
   * 获取标签
   */
  getTag(): string | null;

  /**
   * 旋转到相机
   */
  rotateToCamera(): void;
}

