/**
 * 传感器事件提供者接口
 */

import { SensorEventListener } from './AndroidTypes';

export interface SensorEventProvider {
  start(): void;
  stop(): void;
  registerListener(listener: SensorEventListener): void;
  unregisterListener(listener: SensorEventListener): void;
}

