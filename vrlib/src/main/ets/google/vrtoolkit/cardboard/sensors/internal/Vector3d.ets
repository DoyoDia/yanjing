/**
 * 3D向量类
 */
export class Vector3d {
  public x: number = 0;
  public y: number = 0;
  public z: number = 0;

  constructor();
  constructor(xx: number, yy: number, zz: number);
  constructor(xx?: number, yy?: number, zz?: number) {
    if (xx !== undefined && yy !== undefined && zz !== undefined) {
      this.set(xx, yy, zz);
    }
  }

  // 重载：既支持 set(x, y, z)，也支持 set(otherVector)
  set(xx: number, yy: number, zz: number): void;
  set(other: Vector3d): void;
  set(a: number | Vector3d, b?: number, c?: number): void {
    if (typeof a === 'number') {
      // 形式：set(x, y, z)
      this.x = a;
      this.y = b ?? 0;
      this.z = c ?? 0;
    } else {
      // 形式：set(otherVector)
      this.x = a.x;
      this.y = a.y;
      this.z = a.z;
    }
  }

  setComponent(i: number, val: number): void {
    if (i === 0) {
      this.x = val;
    } else if (i === 1) {
      this.y = val;
    } else {
      this.z = val;
    }
  }

  setZero(): void {
    this.x = 0.0;
    this.y = 0.0;
    this.z = 0.0;
  }

  scale(s: number): void {
    this.x *= s;
    this.y *= s;
    this.z *= s;
  }

  normalize(): void {
    const d = this.length();
    if (d !== 0.0) {
      this.scale(1.0 / d);
    }
  }

  static dot(a: Vector3d, b: Vector3d): number {
    return a.x * b.x + a.y * b.y + a.z * b.z;
  }

  length(): number {
    return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
  }

  sameValues(other: Vector3d): boolean {
    return this.x === other.x && this.y === other.y && this.z === other.z;
  }

  static add(a: Vector3d, b: Vector3d, result: Vector3d): void {
    result.set(a.x + b.x, a.y + b.y, a.z + b.z);
  }

  static sub(a: Vector3d, b: Vector3d, result: Vector3d): void {
    result.set(a.x - b.x, a.y - b.y, a.z - b.z);
  }

  static cross(a: Vector3d, b: Vector3d, result: Vector3d): void {
    result.set(
      a.y * b.z - a.z * b.y,
      a.z * b.x - a.x * b.z,
      a.x * b.y - a.y * b.x
    );
  }

  static ortho(v: Vector3d, result: Vector3d): void {
    let k = Vector3d.largestAbsComponent(v) - 1;
    if (k < 0) {
      k = 2;
    }
    result.setZero();
    result.setComponent(k, 1.0);
    Vector3d.cross(v, result, result);
    result.normalize();
  }

  static largestAbsComponent(v: Vector3d): number {
    const xAbs = Math.abs(v.x);
    const yAbs = Math.abs(v.y);
    const zAbs = Math.abs(v.z);
    if (xAbs > yAbs) {
      if (xAbs > zAbs) {
        return 0;
      }
      return 2;
    } else {
      if (yAbs > zAbs) {
        return 1;
      }
      return 2;
    }
  }

  toString(): string {
    return `{ ${this.x}, ${this.y}, ${this.z} }`;
  }
}

