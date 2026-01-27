/**
 * Created by hzqiujiadi on 2017/5/13.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDQuaternion } from './MDQuaternion';

/**
 * 导演简要信息类
 * 包含 pitch、yaw、roll 角度信息
 */
export class MDDirectorBrief {
  private pitch: number = 0;
  private yaw: number = 0;
  private roll: number = 0;

  /**
   * 从四元数生成角度信息
   * @param quaternion 四元数
   */
  make(quaternion: MDQuaternion): void {
    this.pitch = quaternion.getPitch();
    this.yaw = quaternion.getYaw();
    this.roll = quaternion.getRoll();
  }

  /**
   * 获取 pitch 角度
   * @returns 角度值（度）
   */
  getPitch(): number {
    return this.pitch;
  }

  /**
   * 获取 yaw 角度
   * @returns 角度值（度）
   */
  getYaw(): number {
    return this.yaw;
  }

  /**
   * 获取 roll 角度
   * @returns 角度值（度）
   */
  getRoll(): number {
    return this.roll;
  }

  toString(): string {
    return `{pitch=${this.pitch}, yaw=${this.yaw}, roll=${this.roll}}`;
  }
}

