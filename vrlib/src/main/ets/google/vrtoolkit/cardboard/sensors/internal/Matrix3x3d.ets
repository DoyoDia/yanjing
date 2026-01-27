/**
 * 3x3矩阵类
 */
import { Vector3d } from './Vector3d';

export class Matrix3x3d {
  public m: number[];

  constructor();
  constructor(m00: number, m01: number, m02: number, m10: number, m11: number, m12: number, m20: number, m21: number, m22: number);
  constructor(o: Matrix3x3d);
  constructor(
    m00OrO?: number | Matrix3x3d,
    m01?: number,
    m02?: number,
    m10?: number,
    m11?: number,
    m12?: number,
    m20?: number,
    m21?: number,
    m22?: number
  ) {
    this.m = new Array(9).fill(0);
    if (m00OrO instanceof Matrix3x3d) {
      // 复制构造函数
      const o = m00OrO;
      this.m[0] = o.m[0];
      this.m[1] = o.m[1];
      this.m[2] = o.m[2];
      this.m[3] = o.m[3];
      this.m[4] = o.m[4];
      this.m[5] = o.m[5];
      this.m[6] = o.m[6];
      this.m[7] = o.m[7];
      this.m[8] = o.m[8];
    } else if (m00OrO !== undefined && m01 !== undefined && m02 !== undefined &&
      m10 !== undefined && m11 !== undefined && m12 !== undefined &&
      m20 !== undefined && m21 !== undefined && m22 !== undefined) {
      // 参数构造函数
      this.m[0] = m00OrO;
      this.m[1] = m01;
      this.m[2] = m02;
      this.m[3] = m10;
      this.m[4] = m11;
      this.m[5] = m12;
      this.m[6] = m20;
      this.m[7] = m21;
      this.m[8] = m22;
    }
  }

  set(m00: number, m01: number, m02: number, m10: number, m11: number, m12: number, m20: number, m21: number, m22: number): void;
  set(o: Matrix3x3d): void;
  set(
    m00OrO: number | Matrix3x3d,
    m01?: number,
    m02?: number,
    m10?: number,
    m11?: number,
    m12?: number,
    m20?: number,
    m21?: number,
    m22?: number
  ): void {
    if (m00OrO instanceof Matrix3x3d) {
      const o = m00OrO;
      this.m[0] = o.m[0];
      this.m[1] = o.m[1];
      this.m[2] = o.m[2];
      this.m[3] = o.m[3];
      this.m[4] = o.m[4];
      this.m[5] = o.m[5];
      this.m[6] = o.m[6];
      this.m[7] = o.m[7];
      this.m[8] = o.m[8];
    } else if (m01 !== undefined && m02 !== undefined && m10 !== undefined &&
      m11 !== undefined && m12 !== undefined && m20 !== undefined &&
      m21 !== undefined && m22 !== undefined) {
      this.m[0] = m00OrO;
      this.m[1] = m01;
      this.m[2] = m02;
      this.m[3] = m10;
      this.m[4] = m11;
      this.m[5] = m12;
      this.m[6] = m20;
      this.m[7] = m21;
      this.m[8] = m22;
    }
  }

  setZero(): void {
    for (let i = 0; i < 9; i++) {
      this.m[i] = 0;
    }
  }

  setIdentity(): void {
    this.setZero();
    this.m[0] = 1;
    this.m[4] = 1;
    this.m[8] = 1;
  }

  setSameDiagonal(d: number): void {
    this.m[0] = d;
    this.m[4] = d;
    this.m[8] = d;
  }

  get(row: number, col: number): number {
    return this.m[3 * row + col];
  }

  setValue(row: number, col: number, value: number): void {
    this.m[3 * row + col] = value;
  }

  getColumn(col: number, v: Vector3d): void {
    v.x = this.m[col];
    v.y = this.m[col + 3];
    v.z = this.m[col + 6];
  }

  setColumn(col: number, v: Vector3d): void {
    this.m[col] = v.x;
    this.m[col + 3] = v.y;
    this.m[col + 6] = v.z;
  }

  scale(s: number): void {
    for (let i = 0; i < 9; i++) {
      this.m[i] *= s;
    }
  }

  plusEquals(b: Matrix3x3d): void {
    for (let i = 0; i < 9; i++) {
      this.m[i] += b.m[i];
    }
  }

  minusEquals(b: Matrix3x3d): void {
    for (let i = 0; i < 9; i++) {
      this.m[i] -= b.m[i];
    }
  }

  // 转置：允许就地转置，也允许把结果写入另一个矩阵
  transpose(): void;
  transpose(result: Matrix3x3d): void;
  transpose(result?: Matrix3x3d): void {
    if (result == null) {
      // 就地转置（原来的 transpose(): void 逻辑）
      let tmp = this.m[1];
      this.m[1] = this.m[3];
      this.m[3] = tmp;
      tmp = this.m[2];
      this.m[2] = this.m[6];
      this.m[6] = tmp;
      tmp = this.m[5];
      this.m[5] = this.m[7];
      this.m[7] = tmp;
    } else {
      // 将转置结果写入 result（原来的 transpose(result) 逻辑）
      const m1 = this.m[1];
      const m2 = this.m[2];
      const m3 = this.m[5];
      result.m[0] = this.m[0];
      result.m[1] = this.m[3];
      result.m[2] = this.m[6];
      result.m[3] = m1;
      result.m[4] = this.m[4];
      result.m[5] = this.m[7];
      result.m[6] = m2;
      result.m[7] = m3;
      result.m[8] = this.m[8];
    }
  }

  static add(a: Matrix3x3d, b: Matrix3x3d, result: Matrix3x3d): void {
    result.m[0] = a.m[0] + b.m[0];
    result.m[1] = a.m[1] + b.m[1];
    result.m[2] = a.m[2] + b.m[2];
    result.m[3] = a.m[3] + b.m[3];
    result.m[4] = a.m[4] + b.m[4];
    result.m[5] = a.m[5] + b.m[5];
    result.m[6] = a.m[6] + b.m[6];
    result.m[7] = a.m[7] + b.m[7];
    result.m[8] = a.m[8] + b.m[8];
  }

  // 矩阵乘法重载：既支持矩阵*矩阵，也支持矩阵*向量
  static mult(a: Matrix3x3d, b: Matrix3x3d, result: Matrix3x3d): void;
  static mult(a: Matrix3x3d, v: Vector3d, result: Vector3d): void;
  static mult(a: Matrix3x3d, second: Matrix3x3d | Vector3d, result: Matrix3x3d | Vector3d): void {
    if (second instanceof Matrix3x3d && result instanceof Matrix3x3d) {
      // 原来的矩阵*矩阵实现
      result.set(
        a.m[0] * second.m[0] + a.m[1] * second.m[3] + a.m[2] * second.m[6],
        a.m[0] * second.m[1] + a.m[1] * second.m[4] + a.m[2] * second.m[7],
        a.m[0] * second.m[2] + a.m[1] * second.m[5] + a.m[2] * second.m[8],
        a.m[3] * second.m[0] + a.m[4] * second.m[3] + a.m[5] * second.m[6],
        a.m[3] * second.m[1] + a.m[4] * second.m[4] + a.m[5] * second.m[7],
        a.m[3] * second.m[2] + a.m[4] * second.m[5] + a.m[5] * second.m[8],
        a.m[6] * second.m[0] + a.m[7] * second.m[3] + a.m[8] * second.m[6],
        a.m[6] * second.m[1] + a.m[7] * second.m[4] + a.m[8] * second.m[7],
        a.m[6] * second.m[2] + a.m[7] * second.m[5] + a.m[8] * second.m[8]
      );
    } else if (second instanceof Vector3d && result instanceof Vector3d) {
      // 原来的矩阵*向量实现
      const x = a.m[0] * second.x + a.m[1] * second.y + a.m[2] * second.z;
      const y = a.m[3] * second.x + a.m[4] * second.y + a.m[5] * second.z;
      const z = a.m[6] * second.x + a.m[7] * second.y + a.m[8] * second.z;
      result.x = x;
      result.y = y;
      result.z = z;
    }
  }

  determinant(): number {
    return this.get(0, 0) * (this.get(1, 1) * this.get(2, 2) - this.get(2, 1) * this.get(1, 2))
      - this.get(0, 1) * (this.get(1, 0) * this.get(2, 2) - this.get(1, 2) * this.get(2, 0))
      + this.get(0, 2) * (this.get(1, 0) * this.get(2, 1) - this.get(1, 1) * this.get(2, 0));
  }

  invert(result: Matrix3x3d): boolean {
    const d = this.determinant();
    if (d === 0.0) {
      return false;
    }
    const invdet = 1.0 / d;
    result.set(
      (this.m[4] * this.m[8] - this.m[7] * this.m[5]) * invdet,
      -(this.m[1] * this.m[8] - this.m[2] * this.m[7]) * invdet,
      (this.m[1] * this.m[5] - this.m[2] * this.m[4]) * invdet,
      -(this.m[3] * this.m[8] - this.m[5] * this.m[6]) * invdet,
      (this.m[0] * this.m[8] - this.m[2] * this.m[6]) * invdet,
      -(this.m[0] * this.m[5] - this.m[3] * this.m[2]) * invdet,
      (this.m[3] * this.m[7] - this.m[6] * this.m[4]) * invdet,
      -(this.m[0] * this.m[7] - this.m[6] * this.m[1]) * invdet,
      (this.m[0] * this.m[4] - this.m[3] * this.m[1]) * invdet
    );
    return true;
  }

  toString(): string {
    let builder = "{ ";
    for (let i = 0; i < 9; i++) {
      builder += this.m[i].toString();
      if (i < 8) {
        builder += ", ";
      }
    }
    builder += " }";
    return builder;
  }
}

