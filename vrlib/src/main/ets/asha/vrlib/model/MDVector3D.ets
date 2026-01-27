/**
 * Created by hzqiujiadi on 16/8/5.
 * hzqiujiadi ashqalcn@gmail.com
 */

/**
 * 3D向量类
 */
export class MDVector3D {
  private values: number[] = [0, 0, 0, 1.0];

  constructor() {
    this.values = [0, 0, 0, 1.0];
  }

  setX(x: number): MDVector3D {
    this.values[0] = x;
    return this;
  }

  setY(y: number): MDVector3D {
    this.values[1] = y;
    return this;
  }

  setZ(z: number): MDVector3D {
    this.values[2] = z;
    return this;
  }

  getX(): number {
    return this.values[0];
  }

  getY(): number {
    return this.values[1];
  }

  getZ(): number {
    return this.values[2];
  }

  x(): number {
    return this.values[0];
  }

  y(): number {
    return this.values[1];
  }

  z(): number {
    return this.values[2];
  }

  /**
   * 矩阵与向量相乘
   * @param mat 4x4矩阵
   */
  multiplyMV(mat: number[]): void {
    // Matrix.multiplyMV 等价实现
    const x = this.values[0];
    const y = this.values[1];
    const z = this.values[2];
    const w = this.values[3];

    this.values[0] = mat[0] * x + mat[4] * y + mat[8] * z + mat[12] * w;
    this.values[1] = mat[1] * x + mat[5] * y + mat[9] * z + mat[13] * w;
    this.values[2] = mat[2] * x + mat[6] * y + mat[10] * z + mat[14] * w;
    this.values[3] = mat[3] * x + mat[7] * y + mat[11] * z + mat[15] * w;
  }

  toString(): string {
    return `MDVector3D{x=${this.getX()}, y=${this.getY()}, z=${this.getZ()}}`;
  }

  /**
   * 计算欧几里得长度
   * @param x X坐标
   * @param y Y坐标
   * @param z Z坐标
   * @returns 向量的长度
   */
  static len(x: number, y: number, z: number): number {
    return Math.sqrt(x * x + y * y + z * z);
  }
}

