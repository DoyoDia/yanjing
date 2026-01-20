/**
 * MathUtils - 数学工具模块
 * 提供四元数和矩阵运算，用于姿态数据转换
 */

/**
 * 四元数类
 * 采用 (x, y, z, w) 格式，其中 w 是标量部分
 */
export class Quaternion {
  x: number;
  y: number;
  z: number;
  w: number;

  constructor(x: number = 0, y: number = 0, z: number = 0, w: number = 1) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
  }

  /**
   * 设置四元数值
   */
  set(x: number, y: number, z: number, w: number): Quaternion {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
    return this;
  }

  /**
   * 从另一个四元数复制值
   */
  copy(q: Quaternion): Quaternion {
    this.x = q.x;
    this.y = q.y;
    this.z = q.z;
    this.w = q.w;
    return this;
  }

  /**
   * 克隆当前四元数
   */
  clone(): Quaternion {
    return new Quaternion(this.x, this.y, this.z, this.w);
  }

  /**
   * 归一化四元数
   */
  normalize(): Quaternion {
    const len = Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
    if (len > 0.00001) {
      const invLen = 1.0 / len;
      this.x *= invLen;
      this.y *= invLen;
      this.z *= invLen;
      this.w *= invLen;
    }
    return this;
  }

  /**
   * 四元数共轭（逆旋转）
   */
  conjugate(): Quaternion {
    this.x = -this.x;
    this.y = -this.y;
    this.z = -this.z;
    // w 保持不变
    return this;
  }

  /**
   * 四元数乘法: this = this * q
   * 用于组合旋转
   */
  multiply(q: Quaternion): Quaternion {
    const ax = this.x, ay = this.y, az = this.z, aw = this.w;
    const bx = q.x, by = q.y, bz = q.z, bw = q.w;

    this.x = ax * bw + aw * bx + ay * bz - az * by;
    this.y = ay * bw + aw * by + az * bx - ax * bz;
    this.z = az * bw + aw * bz + ax * by - ay * bx;
    this.w = aw * bw - ax * bx - ay * by - az * bz;

    return this;
  }

  /**
   * 四元数乘法: this = q * this
   * 用于在当前旋转之前应用旋转
   */
  premultiply(q: Quaternion): Quaternion {
    const ax = q.x, ay = q.y, az = q.z, aw = q.w;
    const bx = this.x, by = this.y, bz = this.z, bw = this.w;

    this.x = ax * bw + aw * bx + ay * bz - az * by;
    this.y = ay * bw + aw * by + az * bx - ax * bz;
    this.z = az * bw + aw * bz + ax * by - ay * bx;
    this.w = aw * bw - ax * bx - ay * by - az * bz;

    return this;
  }

  /**
   * 从轴角创建四元数
   * @param axis 旋转轴 [x, y, z]，需要归一化
   * @param angle 旋转角度（弧度）
   */
  setFromAxisAngle(axis: number[], angle: number): Quaternion {
    const halfAngle = angle / 2;
    const s = Math.sin(halfAngle);
    this.x = axis[0] * s;
    this.y = axis[1] * s;
    this.z = axis[2] * s;
    this.w = Math.cos(halfAngle);
    return this;
  }

  /**
   * 从欧拉角创建四元数（ZYX顺序，即Yaw-Pitch-Roll）
   * @param yaw 偏航角（绕Z轴，弧度）
   * @param pitch 俯仰角（绕Y轴，弧度）
   * @param roll 翻滚角（绕X轴，弧度）
   */
  setFromEulerZYX(yaw: number, pitch: number, roll: number): Quaternion {
    const cy = Math.cos(yaw * 0.5);
    const sy = Math.sin(yaw * 0.5);
    const cp = Math.cos(pitch * 0.5);
    const sp = Math.sin(pitch * 0.5);
    const cr = Math.cos(roll * 0.5);
    const sr = Math.sin(roll * 0.5);

    this.w = cr * cp * cy + sr * sp * sy;
    this.x = sr * cp * cy - cr * sp * sy;
    this.y = cr * sp * cy + sr * cp * sy;
    this.z = cr * cp * sy - sr * sp * cy;

    return this;
  }
}

/**
 * 4x4 矩阵类
 * 采用列主序（Column-Major）存储，与 OpenGL 兼容
 * 矩阵元素布局：
 * | m0  m4  m8  m12 |
 * | m1  m5  m9  m13 |
 * | m2  m6  m10 m14 |
 * | m3  m7  m11 m15 |
 */
export class Matrix4 {
  elements: number[];

  constructor() {
    this.elements = [
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    ];
  }

  /**
   * 设置为单位矩阵
   */
  identity(): Matrix4 {
    const e = this.elements;
    e[0] = 1; e[4] = 0; e[8] = 0; e[12] = 0;
    e[1] = 0; e[5] = 1; e[9] = 0; e[13] = 0;
    e[2] = 0; e[6] = 0; e[10] = 1; e[14] = 0;
    e[3] = 0; e[7] = 0; e[11] = 0; e[15] = 1;
    return this;
  }

  /**
   * 从四元数创建旋转矩阵
   */
  setFromQuaternion(q: Quaternion): Matrix4 {
    const x = q.x, y = q.y, z = q.z, w = q.w;
    const x2 = x + x, y2 = y + y, z2 = z + z;
    const xx = x * x2, xy = x * y2, xz = x * z2;
    const yy = y * y2, yz = y * z2, zz = z * z2;
    const wx = w * x2, wy = w * y2, wz = w * z2;

    const e = this.elements;

    e[0] = 1 - (yy + zz);
    e[1] = xy + wz;
    e[2] = xz - wy;
    e[3] = 0;

    e[4] = xy - wz;
    e[5] = 1 - (xx + zz);
    e[6] = yz + wx;
    e[7] = 0;

    e[8] = xz + wy;
    e[9] = yz - wx;
    e[10] = 1 - (xx + yy);
    e[11] = 0;

    e[12] = 0;
    e[13] = 0;
    e[14] = 0;
    e[15] = 1;

    return this;
  }

  /**
   * 矩阵乘法: this = this * m
   */
  multiply(m: Matrix4): Matrix4 {
    return this.multiplyMatrices(this, m);
  }

  /**
   * 矩阵乘法: this = a * b
   */
  multiplyMatrices(a: Matrix4, b: Matrix4): Matrix4 {
    const ae = a.elements;
    const be = b.elements;
    const te = this.elements;

    const a11 = ae[0], a12 = ae[4], a13 = ae[8], a14 = ae[12];
    const a21 = ae[1], a22 = ae[5], a23 = ae[9], a24 = ae[13];
    const a31 = ae[2], a32 = ae[6], a33 = ae[10], a34 = ae[14];
    const a41 = ae[3], a42 = ae[7], a43 = ae[11], a44 = ae[15];

    const b11 = be[0], b12 = be[4], b13 = be[8], b14 = be[12];
    const b21 = be[1], b22 = be[5], b23 = be[9], b24 = be[13];
    const b31 = be[2], b32 = be[6], b33 = be[10], b34 = be[14];
    const b41 = be[3], b42 = be[7], b43 = be[11], b44 = be[15];

    te[0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
    te[4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
    te[8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
    te[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

    te[1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
    te[5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
    te[9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
    te[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

    te[2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
    te[6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
    te[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
    te[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

    te[3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
    te[7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
    te[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
    te[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

    return this;
  }

  /**
   * 转置矩阵
   */
  transpose(): Matrix4 {
    const e = this.elements;
    let tmp: number;

    tmp = e[1]; e[1] = e[4]; e[4] = tmp;
    tmp = e[2]; e[2] = e[8]; e[8] = tmp;
    tmp = e[3]; e[3] = e[12]; e[12] = tmp;
    tmp = e[6]; e[6] = e[9]; e[9] = tmp;
    tmp = e[7]; e[7] = e[13]; e[13] = tmp;
    tmp = e[11]; e[11] = e[14]; e[14] = tmp;

    return this;
  }

  /**
   * 克隆矩阵
   */
  clone(): Matrix4 {
    const m = new Matrix4();
    for (let i = 0; i < 16; i++) {
      m.elements[i] = this.elements[i];
    }
    return m;
  }

  /**
   * 获取 Float32Array 格式的矩阵数据，用于传递给 OpenGL
   */
  toFloat32Array(): Float32Array {
    return new Float32Array(this.elements);
  }
}

/**
 * 创建绕 X 轴旋转的四元数
 */
export function quaternionFromRotationX(angle: number): Quaternion {
  return new Quaternion().setFromAxisAngle([1, 0, 0], angle);
}

/**
 * 创建绕 Y 轴旋转的四元数
 */
export function quaternionFromRotationY(angle: number): Quaternion {
  return new Quaternion().setFromAxisAngle([0, 1, 0], angle);
}

/**
 * 创建绕 Z 轴旋转的四元数
 */
export function quaternionFromRotationZ(angle: number): Quaternion {
  return new Quaternion().setFromAxisAngle([0, 0, 1], angle);
}

/**
 * 角度转弧度
 */
export function degToRad(degrees: number): number {
  return degrees * Math.PI / 180;
}

/**
 * 弧度转角度
 */
export function radToDeg(radians: number): number {
  return radians * 180 / Math.PI;
}
