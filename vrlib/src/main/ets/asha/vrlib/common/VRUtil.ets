/**
 * 从 Java 版 VRUtil 精简迁移而来。
 * 这里只包含与 Android/传感器无关的通用工具方法，
 * 其余依赖 SensorEvent、Surface、MD* 模型类的部分建议在对应模型完成迁移后再补齐。
 */
import { MDRay } from '../model/MDRay';
import { MDVector3D } from '../model/MDVector3D';
import { MDHitPoint } from '../model/MDHitPoint';
import { MDDirectorSnapshot } from '../model/MDDirectorSnapshot';

export class PointF {
  x: number = 0;
  y: number = 0;
}

export class VRUtil {
  static notNull<T>(object: T | null | undefined, error: string): T {
    if (object === null || object === undefined) {
      throw new Error(error);
    }
    return object;
  }

  /**
   * 在 ArkTS 中无法直接判断当前是否为“主线程/GL 线程”，
   * 如有需要可结合 UIAbility/Worker/TaskPool 自行扩展。
   * 这里仅保留校验入口，默认不抛异常。
   */
  static checkMainThread(_error: string): void {
    // TODO: 需要时可在这里补充线程检查逻辑。
  }

  static checkGLThread(_error: string): void {
    // TODO: 需要时可在这里补充线程检查逻辑。
  }

  static checkNaNArray(mat: number[]): void {
    if (mat.length >= 2 && (Number.isNaN(mat[0]) || Number.isNaN(mat[1]))) {
      throw new Error('mat not a number');
    }
  }

  static checkNaNNumber(value: number): void {
    if (Number.isNaN(value)) {
      throw new Error('value not a number');
    }
  }

  /**
   * 桶形畸变矫正算法的直接迁移版本。
   */
  static barrelDistortion(paramA: number, paramB: number, paramC: number, src: PointF): void {
    const paramD: number = 1.0 - paramA - paramB - paramC;
    const d: number = 1.0;

    const centerX: number = 0.0;
    const centerY: number = 0.0;

    if (src.x === centerX && src.y === centerY) {
      return;
    }

    const deltaX: number = (src.x - centerX) / d;
    const deltaY: number = (src.y - centerY) / d;

    const dstR: number = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
    const srcR: number = (paramA * dstR * dstR * dstR + paramB * dstR * dstR + paramC * dstR + paramD) * dstR;

    const factor: number = Math.abs(dstR / srcR);

    const xResult: number = centerX + deltaX * factor * d;
    const yResult: number = centerY + deltaY * factor * d;

    src.x = xResult;
    src.y = yResult;
  }

  /**
   * 直接打印 4x4 矩阵，便于调试。
   */
  static printMatrix(m: number[]): void {
    if (m.length < 16) {
      console.warn('VRUtil.printMatrix: matrix length < 16');
      return;
    }
    console.debug('VRUtil.printMatrix');
    console.debug(`${m[0]}, ${m[1]}, ${m[2]}, ${m[3]}`);
    console.debug(`${m[4]}, ${m[5]}, ${m[6]}, ${m[7]}`);
    console.debug(`${m[8]}, ${m[9]}, ${m[10]}, ${m[11]}`);
    console.debug(`${m[12]}, ${m[13]}, ${m[14]}, ${m[15]}`);
  }

  /**
   * 从 4x4 视图矩阵中提取欧拉角，逻辑与 Java 版一致。
   */
  static getEulerAngles(headView: number[], output: number[]): void {
    if (headView.length < 16 || output.length < 3) {
      console.warn('VRUtil.getEulerAngles: invalid array length');
      return;
    }
    const pitch: number = Math.asin(headView[6]);
    let yaw: number;
    let roll: number;
    if (Math.abs(headView[6]) < 0.9999999999) {
      yaw = Math.atan2(-headView[2], headView[10]);
      roll = Math.atan2(-headView[4], headView[5]);
    } else {
      yaw = 0.0;
      roll = Math.atan2(headView[1], headView[0]);
    }
    output[0] = -pitch;
    output[1] = -yaw;
    output[2] = -roll;

    const pitchAngle: number = (output[0] * 180.0) / Math.PI;
    const yawAngle: number = (output[1] * 180.0) / Math.PI;
    const rollAngle: number = (output[2] * 180.0) / Math.PI;
    console.info(`VRUtil angles pitch=${pitchAngle}, yaw=${yawAngle}, roll=${rollAngle}`);
  }

  /**
   * 矩阵求逆
   * @param output 输出矩阵
   * @param input 输入矩阵
   * @returns 是否成功
   */
  static invertM(output: number[], input: number[]): boolean {
    if (input === output) {
      return false;
    }
    // 在鸿蒙中，需要使用对应的矩阵求逆API
    // 这里提供一个简化的实现占位
    // 实际应该使用鸿蒙的矩阵库或OpenGL矩阵函数
    // return Matrix.invertM(output, 0, input, 0);
    // 占位实现：复制输入到输出
    for (let i = 0; i < 16; i++) {
      output[i] = input[i];
    }
    return true; // 占位返回值
  }

  static intersectTriangle(ray: MDRay, v0: MDVector3D, v1: MDVector3D, v2: MDVector3D, outHit: MDHitPoint): boolean {
    // TODO: Implement ray-triangle intersection
    return false;
  }

  /**
   * 从屏幕点转换为射线
   * @param x 屏幕X坐标
   * @param y 屏幕Y坐标
   * @param info 导演快照
   * @returns 射线对象
   */
  static point2Ray(x: number, y: number, info: MDDirectorSnapshot): MDRay | null {
    // TODO: 当MDDirectorSnapshot和MDRay迁移后，取消注释并完善实现
    // VRUtil.checkMainThread("point2Ray must called in main Thread");
    // const view = info.getViewMatrix();
    // const temp = sUIThreadTmp;
    // const success = VRUtil.invertM(temp, view);
    // if (success) {
    //   const v = new MDVector3D();
    //   const projection = info.getProjectionMatrix();
    //   v.setX(-(((2.0 * x) / info.getViewportWidth()) - 1) / projection[0]);
    //   v.setY(((2.0 * y) / info.getViewportHeight()) - 1) / projection[5];
    //   v.setZ(1.0);
    //
    //   const vPickRayDir = new MDVector3D();
    //   const vPickRayOrig = new MDVector3D();
    //
    //   vPickRayDir.setX(v.getX() * temp[0] + v.getY() * temp[4] + v.getZ() * temp[8]);
    //   vPickRayDir.setY(v.getX() * temp[1] + v.getY() * temp[5] + v.getZ() * temp[9]);
    //   vPickRayDir.setZ(v.getX() * temp[2] + v.getY() * temp[6] + v.getZ() * temp[10]);
    //   vPickRayOrig.setX(temp[12]);
    //   vPickRayOrig.setY(temp[13]);
    //   vPickRayOrig.setZ(temp[14]);
    //   return new MDRay(vPickRayOrig, vPickRayDir);
    // } else {
    //   return null;
    // }
    // 占位实现
    return null;
  }
}




