/**
 * Android 兼容类型定义
 */

export class MotionEvent {
  private x: number = 0;
  private y: number = 0;
  private action: number = 0;

  constructor(x: number, y: number, action: number) {
    this.x = x;
    this.y = y;
    this.action = action;
  }

  getX(): number { return this.x; }
  getY(): number { return this.y; }
  getAction(): number { return this.action; }
}

export interface Sensor {
  getType(): number;
}

export interface SensorEvent {
  sensor: Sensor;
  accuracy: number;
  values: number[];
  timestamp: number;
}

export interface SensorEventListener {
  onSensorChanged(event: SensorEvent): void;
  onAccuracyChanged(sensor: Object, accuracy: number): void;
}

// Uri 占位类型，避免类型导入报错
export class Uri {}
export class Surface {}
export class View {}
export class GLSurfaceView {}
export class GLTextureView {}
export class Toast {
  static makeText(context: Object, text: string, duration: number): Toast { return new Toast(); }
  show(): void {}
  static LENGTH_SHORT: number = 0;
}
