export class Context {
    // 占位成员，防止结构化类型错误
    _dummy: number = 0;
}
export class AttributeSet {}
export class SurfaceTexture {}
export interface TextureView {
    getSurfaceTexture(): SurfaceTexture;
}
export class SurfaceHolder {}
export class Surface {}
export class View {}

export class RectF {
  left: number = 0;
  top: number = 0;
  right: number = 0;
  bottom: number = 0;

  constructor(left?: number, top?: number, right?: number, bottom?: number) {
    this.left = left || 0;
    this.top = top || 0;
    this.right = right || 0;
    this.bottom = bottom || 0;
  }

  set(left: number, top: number, right: number, bottom: number): void {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
  }

  width(): number {
    return this.right - this.left;
  }

  height(): number {
    return this.bottom - this.top;
  }
}

export interface Rect {
  width(): number;
  height(): number;
  set(left: number, top: number, right: number, bottom: number): void;
}
