/**
 * 系统时钟实现
 */
import { Clock } from './Clock';

export class SystemClock implements Clock {
  constructor() {
  }

  nanoTime(): number {
    return Date.now() * 1000000; // 将毫秒转换为纳秒（占位实现）
    // 在鸿蒙中，需要使用对应的高精度时间API
    // return System.nanoTime();
  }
}

