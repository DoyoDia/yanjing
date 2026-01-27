/**
 * Generic Quaternion
 * Written for maximum portability between desktop and Android
 * Not in performance critical sections
 *
 * copy from package com.example.android.rs.vr.engine.Quaternion;
 */

import { MathUtils } from '../../../badlogic/gdx/math/MathUtils';
import { MDVector3D } from './MDVector3D';

/**
 * 四元数类
 */
export class MDQuaternion {
  private q: number[] = [1, 0, 0, 0]; // w, x, y, z

  constructor(x0?: number, x1?: number, x2?: number, x3?: number) {
    if (x0 !== undefined && x1 !== undefined && x2 !== undefined && x3 !== undefined) {
      this.q[0] = x0;
      this.q[1] = x1;
      this.q[2] = x2;
      this.q[3] = x3;
    } else {
      this.idt();
    }
  }

  private set(w: number, x: number, y: number, z: number): void {
    this.q[0] = w;
    this.q[1] = x;
    this.q[2] = y;
    this.q[3] = z;
  }

  private setFromVectors(v1: number[], v2: number[]): void {
    const vec1 = this.normal(v1);
    const vec2 = this.normal(v2);
    const axis = this.normal(this.cross(vec1, vec2));
    const angle = Math.acos(this.dot(vec1, vec2));
    this.setFromAngleAndAxis(angle, axis);
  }

  private setFromAngleAndAxis(angle: number, axis: number[]): void {
    this.q[0] = Math.cos(angle / 2);
    const sin = Math.sin(angle / 2);
    this.q[1] = axis[0] * sin;
    this.q[2] = axis[1] * sin;
    this.q[3] = axis[2] * sin;
  }

  clone(src: MDQuaternion): void {
    for (let i = 0; i < 4; i++) {
      this.q[i] = src.q[i];
    }
  }

  idt(): void {
    this.set(1, 0, 0, 0);
  }

  private cross(a: number[], b: number[]): number[] {
    const out0 = a[1] * b[2] - b[1] * a[2];
    const out1 = a[2] * b[0] - b[2] * a[0];
    const out2 = a[0] * b[1] - b[0] * a[1];
    return [out0, out1, out2];
  }

  private dot(a: number[], b: number[]): number {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
  }

  private normal(a: number[]): number[] {
    const norm = Math.sqrt(this.dot(a, a));
    return [a[0] / norm, a[1] / norm, a[2] / norm];
  }

  static calcAngle(v1: number[], v2: number[]): number {
    const q = new MDQuaternion();
    const vec1 = q.normal(v1);
    const vec2 = q.normal(v2);
    return Math.acos(Math.min(q.dot(vec1, vec2), 1));
  }

  static calcAxis(v1: number[], v2: number[]): number[] {
    const q = new MDQuaternion();
    const vec1 = q.normal(v1);
    const vec2 = q.normal(v2);
    return q.normal(q.cross(vec1, vec2));
  }

  conjugate(): MDQuaternion {
    return new MDQuaternion(this.q[0], -this.q[1], -this.q[2], -this.q[3]);
  }

  plus(b: MDQuaternion): MDQuaternion {
    const a = this;
    return new MDQuaternion(a.q[0] + b.q[0], a.q[1] + b.q[1], a.q[2] + b.q[2], a.q[3] + b.q[3]);
  }

  times(b: MDQuaternion): MDQuaternion {
    const a = this;
    const y0 = a.q[0] * b.q[0] - a.q[1] * b.q[1] - a.q[2] * b.q[2] - a.q[3] * b.q[3];
    const y1 = a.q[0] * b.q[1] + a.q[1] * b.q[0] + a.q[2] * b.q[3] - a.q[3] * b.q[2];
    const y2 = a.q[0] * b.q[2] - a.q[1] * b.q[3] + a.q[2] * b.q[0] + a.q[3] * b.q[1];
    const y3 = a.q[0] * b.q[3] + a.q[1] * b.q[2] - a.q[2] * b.q[1] + a.q[3] * b.q[0];
    return new MDQuaternion(y0, y1, y2, y3);
  }

  inverse(): MDQuaternion {
    const d = this.q[0] * this.q[0] + this.q[1] * this.q[1] + this.q[2] * this.q[2] + this.q[3] * this.q[3];
    return new MDQuaternion(this.q[0] / d, -this.q[1] / d, -this.q[2] / d, -this.q[3] / d);
  }

  divides(b: MDQuaternion): MDQuaternion {
    return this.inverse().times(b);
  }

  rotateVec(v: number[]): number[] {
    const v0 = v[0];
    const v1 = v[1];
    const v2 = v[2];

    const s = this.q[1] * v0 + this.q[2] * v1 + this.q[3] * v2;

    const n0 = 2 * (this.q[0] * (v0 * this.q[0] - (this.q[2] * v2 - this.q[3] * v1)) + s * this.q[1]) - v0;
    const n1 = 2 * (this.q[0] * (v1 * this.q[0] - (this.q[3] * v0 - this.q[1] * v2)) + s * this.q[2]) - v1;
    const n2 = 2 * (this.q[0] * (v2 * this.q[0] - (this.q[1] * v1 - this.q[2] * v0)) + s * this.q[3]) - v2;

    return [n0, n1, n2];
  }

  toMatrix(m: number[]): void {
    const xx = this.q[1] * this.q[1];
    const xy = this.q[1] * this.q[2];
    const xz = this.q[1] * this.q[3];
    const xw = this.q[1] * this.q[0];

    const yy = this.q[2] * this.q[2];
    const yz = this.q[2] * this.q[3];
    const yw = this.q[2] * this.q[0];

    const zz = this.q[3] * this.q[3];
    const zw = this.q[3] * this.q[0];

    m[0] = 1 - 2 * (yy + zz);
    m[1] = 2 * (xy - zw);
    m[2] = 2 * (xz + yw);

    m[4] = 2 * (xy + zw);
    m[5] = 1 - 2 * (xx + zz);
    m[6] = 2 * (yz - xw);

    m[8] = 2 * (xz - yw);
    m[9] = 2 * (yz + xw);
    m[10] = 1 - 2 * (xx + yy);

    m[3] = m[7] = m[11] = m[12] = m[13] = m[14] = 0;
    m[15] = 1;
  }

  fromMatrix(matrix: number[]): void {
    this.setFromAxes(false, matrix[0], matrix[1], matrix[2],
      matrix[4], matrix[5], matrix[6],
      matrix[8], matrix[9], matrix[10]);
  }

  setFromAxis(x: number, y: number, z: number, degrees: number): void {
    this.setFromAxisRad(x, y, z, degrees * MathUtils.degreesToRadians);
  }

  setFromAxisRad(x: number, y: number, z: number, radians: number): void {
    const d = MDVector3D.len(x, y, z);
    if (d === 0) {
      this.idt();
      return;
    }

    const invD = 1 / d;
    const l_ang = radians < 0 ? MathUtils.PI2 - (-radians % MathUtils.PI2) : radians % MathUtils.PI2;
    const l_sin = Math.sin(l_ang / 2);
    const l_cos = Math.cos(l_ang / 2);
    this.set(l_cos, invD * x * l_sin, invD * y * l_sin, invD * z * l_sin);
    this.nor();
  }

  private setFromAxes(normalizeAxes: boolean, xx: number, xy: number, xz: number,
    yx: number, yy: number, yz: number, zx: number, zy: number, zz: number): void {
    let w: number, x: number, y: number, z: number;

    if (normalizeAxes) {
      const lx = 1 / MDVector3D.len(xx, xy, xz);
      const ly = 1 / MDVector3D.len(yx, yy, yz);
      const lz = 1 / MDVector3D.len(zx, zy, zz);
      xx *= lx;
      xy *= lx;
      xz *= lx;
      yx *= ly;
      yy *= ly;
      yz *= ly;
      zx *= lz;
      zy *= lz;
      zz *= lz;
    }

    const t = xx + yy + zz;

    if (t >= 0) {
      const s = Math.sqrt(t + 1);
      w = 0.5 * s;
      const invS = 0.5 / s;
      x = (zy - yz) * invS;
      y = (xz - zx) * invS;
      z = (yx - xy) * invS;
    } else if ((xx > yy) && (xx > zz)) {
      const s = Math.sqrt(1.0 + xx - yy - zz);
      x = s * 0.5;
      const invS = 0.5 / s;
      y = (yx + xy) * invS;
      z = (xz + zx) * invS;
      w = (zy - yz) * invS;
    } else if (yy > zz) {
      const s = Math.sqrt(1.0 + yy - xx - zz);
      y = s * 0.5;
      const invS = 0.5 / s;
      x = (yx + xy) * invS;
      z = (zy + yz) * invS;
      w = (xz - zx) * invS;
    } else {
      const s = Math.sqrt(1.0 + zz - xx - yy);
      z = s * 0.5;
      const invS = 0.5 / s;
      x = (xz + zx) * invS;
      y = (zy + yz) * invS;
      w = (yx - xy) * invS;
    }

    this.set(w, x, y, z);
  }

  setEulerAngles(pitch: number, yaw: number, roll: number): void {
    this.setEulerAnglesRad(pitch * MathUtils.degreesToRadians, yaw * MathUtils.degreesToRadians, roll * MathUtils.degreesToRadians);
  }

  setEulerAnglesRad(pitch: number, yaw: number, roll: number): void {
    const hr = roll * 0.5;
    const shr = Math.sin(hr);
    const chr = Math.cos(hr);
    const hp = pitch * 0.5;
    const shp = Math.sin(hp);
    const chp = Math.cos(hp);
    const hy = yaw * 0.5;
    const shy = Math.sin(hy);
    const chy = Math.cos(hy);
    const chy_shp = chy * shp;
    const shy_chp = shy * chp;
    const chy_chp = chy * chp;
    const shy_shp = shy * shp;

    this.q[1] = (chy_shp * chr) + (shy_chp * shr);
    this.q[2] = (shy_chp * chr) - (chy_shp * shr);
    this.q[3] = (chy_chp * shr) - (shy_shp * chr);
    this.q[0] = (chy_chp * chr) + (shy_shp * shr);
  }

  getGimbalPole(): number {
    const w = this.q[0];
    const x = this.q[1];
    const y = this.q[2];
    const z = this.q[3];

    const t = y * x + z * w;
    return t > 0.499 ? 1 : (t < -0.499 ? -1 : 0);
  }

  getRollRad(): number {
    const w = this.q[0];
    const x = this.q[1];
    const y = this.q[2];
    const z = this.q[3];

    const pole = this.getGimbalPole();
    return pole === 0 ? MathUtils.atan2(2 * (w * z + y * x), 1 - 2 * (x * x + z * z)) : pole * 2 * MathUtils.atan2(y, w);
  }

  getRoll(): number {
    return this.getRollRad() * MathUtils.radiansToDegrees;
  }

  getPitchRad(): number {
    const w = this.q[0];
    const x = this.q[1];
    const y = this.q[2];
    const z = this.q[3];

    const pole = this.getGimbalPole();
    return pole === 0 ? Math.asin(MathUtils.clamp(2 * (w * x - z * y), -1, 1)) : pole * MathUtils.PI * 0.5;
  }

  getPitch(): number {
    return this.getPitchRad() * MathUtils.radiansToDegrees;
  }

  getYawRad(): number {
    const w = this.q[0];
    const x = this.q[1];
    const y = this.q[2];
    const z = this.q[3];

    return this.getGimbalPole() === 0 ? MathUtils.atan2(2 * (y * w + x * z), 1 - 2 * (y * y + x * x)) : 0;
  }

  getYaw(): number {
    return this.getYawRad() * MathUtils.radiansToDegrees;
  }

  nor(): void {
    const w = this.q[0];
    const x = this.q[1];
    const y = this.q[2];
    const z = this.q[3];

    let len = x * x + y * y + z * z + w * w;
    if (len !== 0 && !MathUtils.isEqual(len, 1)) {
      len = Math.sqrt(len);
      this.set(w / len, x / len, y / len, z / len);
    } else {
      this.set(w, x, y, z);
    }
  }

  toString(): string {
    return `MDQuaternion w=${this.q[0]} x=${this.q[1]}, y=${this.q[2]}, z=${this.q[3]}`;
  }
}

