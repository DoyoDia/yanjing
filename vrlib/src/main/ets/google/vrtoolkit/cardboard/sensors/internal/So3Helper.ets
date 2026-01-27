/**
 * SO3辅助类
 */
import { Matrix3x3d } from './Matrix3x3d';
import { Vector3d } from './Vector3d';

export class So3Helper {
  private static readonly M_SQRT1_2: number = 0.7071067811865476;
  private static readonly ONE_6TH: number = 0.1666666716337204;
  private static readonly ONE_20TH: number = 0.1666666716337204;
  private temp31: Vector3d;
  private sO3FromTwoVecN: Vector3d;
  private sO3FromTwoVecA: Vector3d;
  private sO3FromTwoVecB: Vector3d;
  private sO3FromTwoVecRotationAxis: Vector3d;
  private sO3FromTwoVec33R1: Matrix3x3d;
  private sO3FromTwoVec33R2: Matrix3x3d;
  private muFromSO3R2: Vector3d;
  private rotationPiAboutAxisTemp: Vector3d;

  constructor() {
    this.temp31 = new Vector3d();
    this.sO3FromTwoVecN = new Vector3d();
    this.sO3FromTwoVecA = new Vector3d();
    this.sO3FromTwoVecB = new Vector3d();
    this.sO3FromTwoVecRotationAxis = new Vector3d();
    this.sO3FromTwoVec33R1 = new Matrix3x3d();
    this.sO3FromTwoVec33R2 = new Matrix3x3d();
    this.muFromSO3R2 = new Vector3d();
    this.rotationPiAboutAxisTemp = new Vector3d();
  }

  sO3FromTwoVec(a: Vector3d, b: Vector3d, result: Matrix3x3d): void {
    Vector3d.cross(a, b, this.sO3FromTwoVecN);
    if (this.sO3FromTwoVecN.length() === 0.0) {
      const dot = Vector3d.dot(a, b);
      if (dot >= 0.0) {
        result.setIdentity();
      } else {
        Vector3d.ortho(a, this.sO3FromTwoVecRotationAxis);
        this.rotationPiAboutAxis(this.sO3FromTwoVecRotationAxis, result);
      }
      return;
    }
    this.sO3FromTwoVecA.set(a);
    this.sO3FromTwoVecB.set(b);
    this.sO3FromTwoVecN.normalize();
    this.sO3FromTwoVecA.normalize();
    this.sO3FromTwoVecB.normalize();
    const r1 = this.sO3FromTwoVec33R1;
    r1.setColumn(0, this.sO3FromTwoVecA);
    r1.setColumn(1, this.sO3FromTwoVecN);
    Vector3d.cross(this.sO3FromTwoVecN, this.sO3FromTwoVecA, this.temp31);
    r1.setColumn(2, this.temp31);
    const r2 = this.sO3FromTwoVec33R2;
    r2.setColumn(0, this.sO3FromTwoVecB);
    r2.setColumn(1, this.sO3FromTwoVecN);
    Vector3d.cross(this.sO3FromTwoVecN, this.sO3FromTwoVecB, this.temp31);
    r2.setColumn(2, this.temp31);
    r1.transpose();
    Matrix3x3d.mult(r2, r1, result);
  }

  private rotationPiAboutAxis(v: Vector3d, result: Matrix3x3d): void {
    this.rotationPiAboutAxisTemp.set(v);
    this.rotationPiAboutAxisTemp.scale(3.141592653589793 / this.rotationPiAboutAxisTemp.length());
    const invTheta = 0.3183098861837907;
    const kA = 0.0;
    const kB = 0.20264236728467558;
    this.rodriguesSo3Exp(this.rotationPiAboutAxisTemp, kA, kB, result);
  }

  muFromSO3(so3: Matrix3x3d, result: Vector3d): void {
    const cosAngle = (so3.get(0, 0) + so3.get(1, 1) + so3.get(2, 2) - 1.0) * 0.5;
    result.set(
      (so3.get(2, 1) - so3.get(1, 2)) / 2.0,
      (so3.get(0, 2) - so3.get(2, 0)) / 2.0,
      (so3.get(1, 0) - so3.get(0, 1)) / 2.0
    );
    const sinAngleAbs = result.length();
    if (cosAngle > So3Helper.M_SQRT1_2) {
      if (sinAngleAbs > 0.0) {
        result.scale(Math.asin(sinAngleAbs) / sinAngleAbs);
      }
    } else if (cosAngle > -So3Helper.M_SQRT1_2) {
      const angle = Math.acos(cosAngle);
      result.scale(angle / sinAngleAbs);
    } else {
      const angle = 3.141592653589793 - Math.asin(sinAngleAbs);
      const d0 = so3.get(0, 0) - cosAngle;
      const d = so3.get(1, 1) - cosAngle;
      const d2 = so3.get(2, 2) - cosAngle;
      const r2 = this.muFromSO3R2;
      if (d0 * d0 > d * d && d0 * d0 > d2 * d2) {
        r2.set(d0, (so3.get(1, 0) + so3.get(0, 1)) / 2.0, (so3.get(0, 2) + so3.get(2, 0)) / 2.0);
      } else if (d * d > d2 * d2) {
        r2.set((so3.get(1, 0) + so3.get(0, 1)) / 2.0, d, (so3.get(2, 1) + so3.get(1, 2)) / 2.0);
      } else {
        r2.set((so3.get(0, 2) + so3.get(2, 0)) / 2.0, (so3.get(2, 1) + so3.get(1, 2)) / 2.0, d2);
      }
      if (Vector3d.dot(r2, result) < 0.0) {
        r2.scale(-1.0);
      }
      r2.normalize();
      r2.scale(angle);
      result.set(r2);
    }
  }

  private rodriguesSo3Exp(w: Vector3d, kA: number, kB: number, result: Matrix3x3d): void {
    const wx2 = w.x * w.x;
    const wy2 = w.y * w.y;
    const wz2 = w.z * w.z;
    result.setValue(0, 0, 1.0 - kB * (wy2 + wz2));
    result.setValue(1, 1, 1.0 - kB * (wx2 + wz2));
    result.setValue(2, 2, 1.0 - kB * (wx2 + wy2));
    let a = kA * w.z;
    let b = kB * (w.x * w.y);
    result.setValue(0, 1, b - a);
    result.setValue(1, 0, b + a);
    a = kA * w.y;
    b = kB * (w.x * w.z);
    result.setValue(0, 2, b + a);
    result.setValue(2, 0, b - a);
    a = kA * w.x;
    b = kB * (w.y * w.z);
    result.setValue(1, 2, b - a);
    result.setValue(2, 1, b + a);
  }
}

