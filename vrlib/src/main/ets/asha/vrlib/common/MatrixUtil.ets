/**
 * 矩阵工具类
 * 提供4x4矩阵的基本操作，替代Android的Matrix类，此处影响性能
 */

export class MatrixUtil {
  /**
   * 设置单位矩阵
   */
  static setIdentityM(m: number[], offset: number = 0): void {
    for (let i = 0; i < 16; i++) {
      m[offset + i] = 0;
    }
    m[offset + 0] = 1;
    m[offset + 5] = 1;
    m[offset + 10] = 1;
    m[offset + 15] = 1;
  }

  /**
   * 矩阵乘法
   */
  static multiplyMM(result: number[], resultOffset: number, lhs: number[], lhsOffset: number, rhs: number[], rhsOffset: number): void {
    const a00 = lhs[lhsOffset + 0];
    const a01 = lhs[lhsOffset + 1];
    const a02 = lhs[lhsOffset + 2];
    const a03 = lhs[lhsOffset + 3];
    const a10 = lhs[lhsOffset + 4];
    const a11 = lhs[lhsOffset + 5];
    const a12 = lhs[lhsOffset + 6];
    const a13 = lhs[lhsOffset + 7];
    const a20 = lhs[lhsOffset + 8];
    const a21 = lhs[lhsOffset + 9];
    const a22 = lhs[lhsOffset + 10];
    const a23 = lhs[lhsOffset + 11];
    const a30 = lhs[lhsOffset + 12];
    const a31 = lhs[lhsOffset + 13];
    const a32 = lhs[lhsOffset + 14];
    const a33 = lhs[lhsOffset + 15];

    const b00 = rhs[rhsOffset + 0];
    const b01 = rhs[rhsOffset + 1];
    const b02 = rhs[rhsOffset + 2];
    const b03 = rhs[rhsOffset + 3];
    const b10 = rhs[rhsOffset + 4];
    const b11 = rhs[rhsOffset + 5];
    const b12 = rhs[rhsOffset + 6];
    const b13 = rhs[rhsOffset + 7];
    const b20 = rhs[rhsOffset + 8];
    const b21 = rhs[rhsOffset + 9];
    const b22 = rhs[rhsOffset + 10];
    const b23 = rhs[rhsOffset + 11];
    const b30 = rhs[rhsOffset + 12];
    const b31 = rhs[rhsOffset + 13];
    const b32 = rhs[rhsOffset + 14];
    const b33 = rhs[rhsOffset + 15];

    result[resultOffset + 0] = a00 * b00 + a01 * b10 + a02 * b20 + a03 * b30;
    result[resultOffset + 1] = a00 * b01 + a01 * b11 + a02 * b21 + a03 * b31;
    result[resultOffset + 2] = a00 * b02 + a01 * b12 + a02 * b22 + a03 * b32;
    result[resultOffset + 3] = a00 * b03 + a01 * b13 + a02 * b23 + a03 * b33;

    result[resultOffset + 4] = a10 * b00 + a11 * b10 + a12 * b20 + a13 * b30;
    result[resultOffset + 5] = a10 * b01 + a11 * b11 + a12 * b21 + a13 * b31;
    result[resultOffset + 6] = a10 * b02 + a11 * b12 + a12 * b22 + a13 * b32;
    result[resultOffset + 7] = a10 * b03 + a11 * b13 + a12 * b23 + a13 * b33;

    result[resultOffset + 8] = a20 * b00 + a21 * b10 + a22 * b20 + a23 * b30;
    result[resultOffset + 9] = a20 * b01 + a21 * b11 + a22 * b21 + a23 * b31;
    result[resultOffset + 10] = a20 * b02 + a21 * b12 + a22 * b22 + a23 * b32;
    result[resultOffset + 11] = a20 * b03 + a21 * b13 + a22 * b23 + a23 * b33;

    result[resultOffset + 12] = a30 * b00 + a31 * b10 + a32 * b20 + a33 * b30;
    result[resultOffset + 13] = a30 * b01 + a31 * b11 + a32 * b21 + a33 * b31;
    result[resultOffset + 14] = a30 * b02 + a31 * b12 + a32 * b22 + a33 * b32;
    result[resultOffset + 15] = a30 * b03 + a31 * b13 + a32 * b23 + a33 * b33;
  }

  /**
   * 旋转矩阵
   */
  static rotateM(m: number[], mOffset: number, a: number, x: number, y: number, z: number): void {
    const temp: number[] = new Array(16);
    MatrixUtil.setIdentityM(temp, 0);
    
    const s = Math.sin(a * Math.PI / 180.0);
    const c = Math.cos(a * Math.PI / 180.0);
    const len = Math.sqrt(x * x + y * y + z * z);
    
    if (len !== 0) {
      const invLen = 1.0 / len;
      x *= invLen;
      y *= invLen;
      z *= invLen;
    }

    const xx = x * x;
    const yy = y * y;
    const zz = z * z;
    const xy = x * y;
    const yz = y * z;
    const zx = z * x;
    const xs = x * s;
    const ys = y * s;
    const zs = z * s;
    const oneMinusC = 1.0 - c;

    temp[0] = (oneMinusC * xx) + c;
    temp[1] = (oneMinusC * xy) + zs;
    temp[2] = (oneMinusC * zx) - ys;
    temp[4] = (oneMinusC * xy) - zs;
    temp[5] = (oneMinusC * yy) + c;
    temp[6] = (oneMinusC * yz) + xs;
    temp[8] = (oneMinusC * zx) + ys;
    temp[9] = (oneMinusC * yz) - xs;
    temp[10] = (oneMinusC * zz) + c;

    const result: number[] = new Array(16);
    MatrixUtil.multiplyMM(result, 0, m, mOffset, temp, 0);
    for (let i = 0; i < 16; i++) {
      m[mOffset + i] = result[i];
    }
  }

  /**
   * 透视投影矩阵
   */
  static frustumM(m: number[], offset: number, left: number, right: number, bottom: number, top: number, near: number, far: number): void {
    const r_width = 1.0 / (right - left);
    const r_height = 1.0 / (top - bottom);
    const r_depth = 1.0 / (near - far);
    const x = 2.0 * (near * r_width);
    const y = 2.0 * (near * r_height);
    const A = (right + left) * r_width;
    const B = (top + bottom) * r_height;
    const C = (far + near) * r_depth;
    const D = 2.0 * (far * near * r_depth);

    m[offset + 0] = x;
    m[offset + 5] = y;
    m[offset + 8] = A;
    m[offset + 9] = B;
    m[offset + 10] = C;
    m[offset + 14] = D;
    m[offset + 11] = -1.0;
    m[offset + 1] = 0.0;
    m[offset + 2] = 0.0;
    m[offset + 3] = 0.0;
    m[offset + 4] = 0.0;
    m[offset + 6] = 0.0;
    m[offset + 7] = 0.0;
    m[offset + 12] = 0.0;
    m[offset + 13] = 0.0;
    m[offset + 15] = 0.0;
  }

  /**
   * 正交投影矩阵
   */
  static orthoM(m: number[], offset: number, left: number, right: number, bottom: number, top: number, near: number, far: number): void {
    const r_width = 1.0 / (right - left);
    const r_height = 1.0 / (top - bottom);
    const r_depth = 1.0 / (near - far);
    const x = 2.0 * r_width;
    const y = 2.0 * r_height;
    const z = -2.0 * r_depth;
    const tx = -(right + left) * r_width;
    const ty = -(top + bottom) * r_height;
    const tz = -(far + near) * r_depth;

    m[offset + 0] = x;
    m[offset + 5] = y;
    m[offset + 10] = z;
    m[offset + 12] = tx;
    m[offset + 13] = ty;
    m[offset + 14] = tz;
    m[offset + 15] = 1.0;
    m[offset + 1] = 0.0;
    m[offset + 2] = 0.0;
    m[offset + 3] = 0.0;
    m[offset + 4] = 0.0;
    m[offset + 6] = 0.0;
    m[offset + 7] = 0.0;
    m[offset + 8] = 0.0;
    m[offset + 9] = 0.0;
    m[offset + 11] = 0.0;
  }

  /**
   * 设置旋转矩阵（使用欧拉角）
   * @param rm 结果矩阵
   * @param rmOffset 结果矩阵偏移
   * @param x 绕X轴旋转角度（度）
   * @param y 绕Y轴旋转角度（度）
   * @param z 绕Z轴旋转角度（度）
   */
  static setRotateEulerM(rm: number[], rmOffset: number, x: number, y: number, z: number): void {
    MatrixUtil.setIdentityM(rm, rmOffset);
    
    // 转换为弧度
    const xRad = x * Math.PI / 180.0;
    const yRad = y * Math.PI / 180.0;
    const zRad = z * Math.PI / 180.0;
    
    const cx = Math.cos(xRad);
    const sx = Math.sin(xRad);
    const cy = Math.cos(yRad);
    const sy = Math.sin(yRad);
    const cz = Math.cos(zRad);
    const sz = Math.sin(zRad);
    
    // 组合旋转：R = Rz * Ry * Rx
    const cxsy = cx * sy;
    const sxsy = sx * sy;
    
    rm[rmOffset + 0] = cy * cz;
    rm[rmOffset + 1] = -cy * sz;
    rm[rmOffset + 2] = sy;
    rm[rmOffset + 3] = 0.0;
    
    rm[rmOffset + 4] = cxsy * cz + cx * sz;
    rm[rmOffset + 5] = -cxsy * sz + cx * cz;
    rm[rmOffset + 6] = -sx * cy;
    rm[rmOffset + 7] = 0.0;
    
    rm[rmOffset + 8] = -sxsy * cz + sx * sz;
    rm[rmOffset + 9] = sxsy * sz + sx * cz;
    rm[rmOffset + 10] = cx * cy;
    rm[rmOffset + 11] = 0.0;
    
    rm[rmOffset + 12] = 0.0;
    rm[rmOffset + 13] = 0.0;
    rm[rmOffset + 14] = 0.0;
    rm[rmOffset + 15] = 1.0;
  }

  /**
   * 平移矩阵
   */
  static translateM(m: number[], mOffset: number, x: number, y: number, z: number): void {
    const temp: number[] = new Array(16);
    MatrixUtil.setIdentityM(temp, 0);
    temp[12] = x;
    temp[13] = y;
    temp[14] = z;
    
    const result: number[] = new Array(16);
    MatrixUtil.multiplyMM(result, 0, m, mOffset, temp, 0);
    for (let i = 0; i < 16; i++) {
      m[mOffset + i] = result[i];
    }
  }

  /**
   * LookAt矩阵
   */
  static setLookAtM(rm: number[], rmOffset: number, eyeX: number, eyeY: number, eyeZ: number, centerX: number, centerY: number, centerZ: number, upX: number, upY: number, upZ: number): void {
    let fx = centerX - eyeX;
    let fy = centerY - eyeY;
    let fz = centerZ - eyeZ;

    const rlf = 1.0 / Math.sqrt(fx * fx + fy * fy + fz * fz);
    fx *= rlf;
    fy *= rlf;
    fz *= rlf;

    let sx = fy * upZ - fz * upY;
    let sy = fz * upX - fx * upZ;
    let sz = fx * upY - fy * upX;

    const rls = 1.0 / Math.sqrt(sx * sx + sy * sy + sz * sz);
    sx *= rls;
    sy *= rls;
    sz *= rls;

    const ux = sy * fz - sz * fy;
    const uy = sz * fx - sx * fz;
    const uz = sx * fy - sy * fx;

    rm[rmOffset + 0] = sx;
    rm[rmOffset + 1] = ux;
    rm[rmOffset + 2] = -fx;
    rm[rmOffset + 3] = 0.0;
    rm[rmOffset + 4] = sy;
    rm[rmOffset + 5] = uy;
    rm[rmOffset + 6] = -fy;
    rm[rmOffset + 7] = 0.0;
    rm[rmOffset + 8] = sz;
    rm[rmOffset + 9] = uz;
    rm[rmOffset + 10] = -fz;
    rm[rmOffset + 11] = 0.0;
    rm[rmOffset + 12] = 0.0;
    rm[rmOffset + 13] = 0.0;
    rm[rmOffset + 14] = 0.0;
    rm[rmOffset + 15] = 1.0;

    const tx = -sx * eyeX - sy * eyeY - sz * eyeZ;
    const ty = -ux * eyeX - uy * eyeY - uz * eyeZ;
    const tz = fx * eyeX + fy * eyeY + fz * eyeZ;

    rm[rmOffset + 12] = tx;
    rm[rmOffset + 13] = ty;
    rm[rmOffset + 14] = tz;
  }
}

