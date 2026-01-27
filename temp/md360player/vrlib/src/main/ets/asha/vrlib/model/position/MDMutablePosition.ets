/**
 * Created by hzqiujiadi on 2017/4/11.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDPosition } from '../MDPosition';
import { VRUtil } from '../../common/VRUtil';

/**
 * 可变位置类
 */
export class MDMutablePosition extends MDPosition {
  private mModelMatrix: number[] | null = null;
  private mRotationMatrix: number[] | null = null;
  private readonly mTmpMatrix: number[] = new Array(16).fill(0);

  private mX: number = 0;
  private mY: number = 0;
  private mZ: number = 0;
  private mAngleX: number = 0;
  private mAngleY: number = 0;
  private mAngleZ: number = 0;
  private mPitch: number = 0; // x-axis
  private mYaw: number = 0; // y-axis
  private mRoll: number = 0; // z-axis
  private changed: boolean = true;

  private constructor() {
    super();
    this.mX = this.mY = this.mZ = 0;
    this.mAngleX = this.mAngleY = this.mAngleZ = 0;
    this.mPitch = this.mYaw = this.mRoll = 0;
    this.changed = true;
  }

  getPitch(): number {
    return this.mPitch;
  }

  setPitch(pitch: number): MDMutablePosition {
    this.changed = this.changed || (this.mPitch !== pitch);
    this.mPitch = pitch;
    return this;
  }

  getYaw(): number {
    return this.mYaw;
  }

  setYaw(yaw: number): MDMutablePosition {
    this.changed = this.changed || (this.mYaw !== yaw);
    this.mYaw = yaw;
    return this;
  }

  getRoll(): number {
    return this.mRoll;
  }

  setRoll(roll: number): MDMutablePosition {
    this.changed = this.changed || (this.mRoll !== roll);
    this.mRoll = roll;
    return this;
  }

  getX(): number {
    return this.mX;
  }

  setX(x: number): MDMutablePosition {
    this.changed = this.changed || (this.mX !== x);
    this.mX = x;
    return this;
  }

  getY(): number {
    return this.mY;
  }

  setY(y: number): MDMutablePosition {
    this.changed = this.changed || (this.mY !== y);
    this.mY = y;
    return this;
  }

  getZ(): number {
    return this.mZ;
  }

  setZ(z: number): MDMutablePosition {
    this.changed = this.changed || (this.mZ !== z);
    this.mZ = z;
    return this;
  }

  getAngleX(): number {
    return this.mAngleX;
  }

  /**
   * 设置 X 轴角度
   * @param angleX 角度（度）
   * @returns 自身引用
   */
  setAngleX(angleX: number): MDMutablePosition {
    this.changed = this.changed || (this.mAngleX !== angleX);
    this.mAngleX = angleX;
    return this;
  }

  getAngleY(): number {
    return this.mAngleY;
  }

  /**
   * 设置 Y 轴角度
   * @param angleY 角度（度）
   * @returns 自身引用
   */
  setAngleY(angleY: number): MDMutablePosition {
    this.changed = this.changed || (this.mAngleY !== angleY);
    this.mAngleY = angleY;
    return this;
  }

  getAngleZ(): number {
    return this.mAngleZ;
  }

  /**
   * 设置 Z 轴角度
   * @param angleZ 角度（度）
   * @returns 自身引用
   */
  setAngleZ(angleZ: number): MDMutablePosition {
    this.changed = this.changed || (this.mAngleZ !== angleZ);
    this.mAngleZ = angleZ;
    return this;
  }

  static newInstance(): MDMutablePosition {
    return new MDMutablePosition();
  }

  toString(): string {
    return `MDPosition{mX=${this.mX}, mY=${this.mY}, mZ=${this.mZ}, mAngleX=${this.mAngleX}, mAngleY=${this.mAngleY}, mAngleZ=${this.mAngleZ}, mPitch=${this.mPitch}, mYaw=${this.mYaw}, mRoll=${this.mRoll}}`;
  }

  private ensure(): void {
    // 初始化模型矩阵
    if (this.mModelMatrix == null) {
      this.mModelMatrix = new Array(16).fill(0);
      this.setIdentityM(this.mModelMatrix, 0);
    }

    if (!this.changed) {
      return;
    }

    this.setIdentityM(this.mModelMatrix, 0);

    // 应用旋转和位移
    this.rotateM(this.mModelMatrix, 0, this.getAngleX(), 1.0, 0.0, 0.0);
    this.rotateM(this.mModelMatrix, 0, this.getAngleY(), 0.0, 1.0, 0.0);
    this.rotateM(this.mModelMatrix, 0, this.getAngleZ(), 0.0, 0.0, 1.0);

    this.translateM(this.mModelMatrix, 0, this.getX(), this.getY(), this.getZ());

    this.rotateM(this.mModelMatrix, 0, this.getYaw(), 1.0, 0.0, 0.0);
    this.rotateM(this.mModelMatrix, 0, this.getPitch(), 0.0, 1.0, 0.0);
    this.rotateM(this.mModelMatrix, 0, this.getRoll(), 0.0, 0.0, 1.0);

    // 应用外部旋转矩阵
    if (this.mRotationMatrix != null) {
      this.multiplyMM(this.mTmpMatrix, 0, this.mRotationMatrix, 0, this.mModelMatrix, 0);
      for (let i = 0; i < 16; i++) {
        this.mModelMatrix[i] = this.mTmpMatrix[i];
      }
    }

    this.changed = false;
  }

  override setRotationMatrix(rotationMatrix: number[]): void {
    VRUtil.notNull(rotationMatrix, "rotationMatrix can't be null!");
    // VRUtil.checkGLThread("setRotationMatrix must called in gl thread!");

    if (this.mRotationMatrix == null) {
      this.mRotationMatrix = new Array(16).fill(0);
    }

    for (let i = 0; i < 16; i++) {
      this.mRotationMatrix[i] = rotationMatrix[i];
    }
    this.changed = true;
  }

  override getMatrix(): number[] {
    this.ensure();
    return this.mModelMatrix!;
  }

  // 矩阵工具方法
  private setIdentityM(m: number[], offset: number): void {
    for (let i = 0; i < 16; i++) {
      m[offset + i] = 0;
    }
    m[offset + 0] = 1;
    m[offset + 5] = 1;
    m[offset + 10] = 1;
    m[offset + 15] = 1;
  }

  private rotateM(m: number[], mOffset: number, a: number, x: number, y: number, z: number): void {
    // 简化的旋转矩阵实现
    const radians = a * Math.PI / 180;
    const c = Math.cos(radians);
    const s = Math.sin(radians);
    const t = 1 - c;

    const len = Math.sqrt(x * x + y * y + z * z);
    if (len !== 0) {
      x /= len;
      y /= len;
      z /= len;
    }

    const rot: number[] = new Array(16).fill(0);
    rot[0] = t * x * x + c;
    rot[1] = t * x * y - s * z;
    rot[2] = t * x * z + s * y;
    rot[3] = 0;
    rot[4] = t * x * y + s * z;
    rot[5] = t * y * y + c;
    rot[6] = t * y * z - s * x;
    rot[7] = 0;
    rot[8] = t * x * z - s * y;
    rot[9] = t * y * z + s * x;
    rot[10] = t * z * z + c;
    rot[11] = 0;
    rot[12] = 0;
    rot[13] = 0;
    rot[14] = 0;
    rot[15] = 1;

    this.multiplyMM(m, mOffset, m, mOffset, rot, 0);
  }

  private translateM(m: number[], mOffset: number, x: number, y: number, z: number): void {
    m[mOffset + 12] += m[mOffset + 0] * x + m[mOffset + 4] * y + m[mOffset + 8] * z;
    m[mOffset + 13] += m[mOffset + 1] * x + m[mOffset + 5] * y + m[mOffset + 9] * z;
    m[mOffset + 14] += m[mOffset + 2] * x + m[mOffset + 6] * y + m[mOffset + 10] * z;
    m[mOffset + 15] += m[mOffset + 3] * x + m[mOffset + 7] * y + m[mOffset + 11] * z;
  }

  private multiplyMM(result: number[], resultOffset: number, lhs: number[], lhsOffset: number, rhs: number[], rhsOffset: number): void {
    for (let i = 0; i < 4; i++) {
      const rhs_i0 = rhs[rhsOffset + i];
      const rhs_i1 = rhs[rhsOffset + i + 4];
      const rhs_i2 = rhs[rhsOffset + i + 8];
      const rhs_i3 = rhs[rhsOffset + i + 12];
      result[resultOffset + i] = lhs[lhsOffset + 0] * rhs_i0 + lhs[lhsOffset + 1] * rhs_i1 + lhs[lhsOffset + 2] * rhs_i2 + lhs[lhsOffset + 3] * rhs_i3;
      result[resultOffset + i + 4] = lhs[lhsOffset + 4] * rhs_i0 + lhs[lhsOffset + 5] * rhs_i1 + lhs[lhsOffset + 6] * rhs_i2 + lhs[lhsOffset + 7] * rhs_i3;
      result[resultOffset + i + 8] = lhs[lhsOffset + 8] * rhs_i0 + lhs[lhsOffset + 9] * rhs_i1 + lhs[lhsOffset + 10] * rhs_i2 + lhs[lhsOffset + 11] * rhs_i3;
      result[resultOffset + i + 12] = lhs[lhsOffset + 12] * rhs_i0 + lhs[lhsOffset + 13] * rhs_i1 + lhs[lhsOffset + 14] * rhs_i2 + lhs[lhsOffset + 15] * rhs_i3;
    }
  }
}

