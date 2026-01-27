/**
 * SO3工具类
 */
import { Matrix3x3d } from './Matrix3x3d';
import { Vector3d } from './Vector3d';

export class So3Util {
  private static readonly M_SQRT1_2: number = 0.7071067811865476;
  private static readonly ONE_6TH: number = 0.1666666716337204;
  private static readonly ONE_20TH: number = 0.1666666716337204;
  private static temp31: Vector3d = new Vector3d();
  private static sO3FromTwoVecN: Vector3d = new Vector3d();
  private static sO3FromTwoVecA: Vector3d = new Vector3d();
  private static sO3FromTwoVecB: Vector3d = new Vector3d();
  private static sO3FromTwoVecRotationAxis: Vector3d = new Vector3d();
  private static sO3FromTwoVec33R1: Matrix3x3d = new Matrix3x3d();
  private static sO3FromTwoVec33R2: Matrix3x3d = new Matrix3x3d();
  private static muFromSO3R2: Vector3d = new Vector3d();
  private static rotationPiAboutAxisTemp: Vector3d = new Vector3d();

  static sO3FromTwoVec(a: Vector3d, b: Vector3d, result: Matrix3x3d): void {
    Vector3d.cross(a, b, So3Util.sO3FromTwoVecN);
    if (So3Util.sO3FromTwoVecN.length() === 0.0) {
      const dot = Vector3d.dot(a, b);
      if (dot >= 0.0) {
        result.setIdentity();
      } else {
        Vector3d.ortho(a, So3Util.sO3FromTwoVecRotationAxis);
        So3Util.rotationPiAboutAxis(So3Util.sO3FromTwoVecRotationAxis, result);
      }
      return;
    }
    So3Util.sO3FromTwoVecA.set(a);
    So3Util.sO3FromTwoVecB.set(b);
    So3Util.sO3FromTwoVecN.normalize();
    So3Util.sO3FromTwoVecA.normalize();
    So3Util.sO3FromTwoVecB.normalize();
    const r1 = So3Util.sO3FromTwoVec33R1;
    r1.setColumn(0, So3Util.sO3FromTwoVecA);
    r1.setColumn(1, So3Util.sO3FromTwoVecN);
    Vector3d.cross(So3Util.sO3FromTwoVecN, So3Util.sO3FromTwoVecA, So3Util.temp31);
    r1.setColumn(2, So3Util.temp31);
    const r2 = So3Util.sO3FromTwoVec33R2;
    r2.setColumn(0, So3Util.sO3FromTwoVecB);
    r2.setColumn(1, So3Util.sO3FromTwoVecN);
    Vector3d.cross(So3Util.sO3FromTwoVecN, So3Util.sO3FromTwoVecB, So3Util.temp31);
    r2.setColumn(2, So3Util.temp31);
    r1.transpose();
    Matrix3x3d.mult(r2, r1, result);
  }

  private static rotationPiAboutAxis(v: Vector3d, result: Matrix3x3d): void {
    So3Util.rotationPiAboutAxisTemp.set(v);
    So3Util.rotationPiAboutAxisTemp.scale(3.141592653589793 / So3Util.rotationPiAboutAxisTemp.length());
    const invTheta = 0.3183098861837907;
    const kA = 0.0;
    const kB = 0.20264236728467558;
    So3Util.rodriguesSo3Exp(So3Util.rotationPiAboutAxisTemp, kA, kB, result);
  }

  static sO3FromMu(w: Vector3d, result: Matrix3x3d): void {
    const thetaSq = Vector3d.dot(w, w);
    const theta = Math.sqrt(thetaSq);
    let kA: number;
    let kB: number;
    if (thetaSq < 1.0E-8) {
      kA = 1.0 - So3Util.ONE_6TH * thetaSq;
      kB = 0.5;
    } else if (thetaSq < 1.0E-6) {
      kB = 0.5 - 0.0416666679084301 * thetaSq;
      kA = 1.0 - thetaSq * So3Util.ONE_6TH * (1.0 - So3Util.ONE_6TH * thetaSq);
    } else {
      const invTheta = 1.0 / theta;
      kA = Math.sin(theta) * invTheta;
      kB = (1.0 - Math.cos(theta)) * (invTheta * invTheta);
    }
    So3Util.rodriguesSo3Exp(w, kA, kB, result);
  }

  static muFromSO3(so3: Matrix3x3d, result: Vector3d): void {
    const cosAngle = (so3.get(0, 0) + so3.get(1, 1) + so3.get(2, 2) - 1.0) * 0.5;
    result.set(
      (so3.get(2, 1) - so3.get(1, 2)) / 2.0,
      (so3.get(0, 2) - so3.get(2, 0)) / 2.0,
      (so3.get(1, 0) - so3.get(0, 1)) / 2.0
    );
    const sinAngleAbs = result.length();
    if (cosAngle > So3Util.M_SQRT1_2) {
      if (sinAngleAbs > 0.0) {
        result.scale(Math.asin(sinAngleAbs) / sinAngleAbs);
      }
    } else if (cosAngle > -So3Util.M_SQRT1_2) {
      const angle = Math.acos(cosAngle);
      result.scale(angle / sinAngleAbs);
    } else {
      const angle = 3.141592653589793 - Math.asin(sinAngleAbs);
      const d0 = so3.get(0, 0) - cosAngle;
      const d = so3.get(1, 1) - cosAngle;
      const d2 = so3.get(2, 2) - cosAngle;
      const r2 = So3Util.muFromSO3R2;
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

  private static rodriguesSo3Exp(w: Vector3d, kA: number, kB: number, result: Matrix3x3d): void {
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

  static generatorField(i: number, pos: Matrix3x3d, result: Matrix3x3d): void {
    result.setValue(i, 0, 0.0);
    result.setValue((i + 1) % 3, 0, -pos.get((i + 2) % 3, 0));
    result.setValue((i + 2) % 3, 0, pos.get((i + 1) % 3, 0));
  }
}

