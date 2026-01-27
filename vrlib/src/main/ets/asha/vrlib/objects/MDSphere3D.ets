/**
 * Created by hzqiujiadi on 16/1/8.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsObject3D, FloatBuffer, ShortBuffer } from './MDAbsObject3D';
import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 球体3D对象类
 */
export class MDSphere3D extends MDAbsObject3D {
  private static readonly TAG: string = "MDSphere3D";

  executeLoad(context: Context): void {
    MDSphere3D.generateSphere(this);
  }

  private static generateSphere(object3D: MDAbsObject3D): void {
    MDSphere3D.generateSphereImpl(18, 75, 150, object3D);
  }

  /**
   * 生成球体几何数据
   * copied from https://github.com/shulja/viredero/blob/a7d28b21d762e8479dc10cde1aa88054497ff649/viredroid/src/main/java/org/viredero/viredroid/Sphere.java
   */
  private static generateSphereImpl(radius: number, rings: number, sectors: number, object3D: MDAbsObject3D): void {
    const PI = Math.PI;
    const PI_2 = Math.PI / 2;

    const R = 1.0 / rings;
    const S = 1.0 / sectors;
    let r: number, s: number;
    let x: number, y: number, z: number;

    const numPoint = (rings + 1) * (sectors + 1);
    const vertexs: number[] = new Array(numPoint * 3);
    const texcoords: number[] = new Array(numPoint * 2);
    const indices: number[] = new Array(numPoint * 6);

    let t = 0, v = 0;
    for (r = 0; r < rings + 1; r++) {
      for (s = 0; s < sectors + 1; s++) {
        x = Math.cos(2 * PI * s * S) * Math.sin(PI * r * R);
        y = -Math.sin(-PI_2 + PI * r * R);
        z = Math.sin(2 * PI * s * S) * Math.sin(PI * r * R);

        texcoords[t++] = s * S;
        texcoords[t++] = 1 - r * R;

        vertexs[v++] = x * radius;
        vertexs[v++] = y * radius;
        vertexs[v++] = z * radius;
      }
    }

    let counter = 0;
    const sectorsPlusOne = sectors + 1;
    for (r = 0; r < rings; r++) {
      for (s = 0; s < sectors; s++) {
        indices[counter++] = r * sectorsPlusOne + s;       // (a)
        indices[counter++] = (r + 1) * sectorsPlusOne + s;    // (b)
        indices[counter++] = r * sectorsPlusOne + (s + 1);  // (c)
        indices[counter++] = r * sectorsPlusOne + (s + 1);  // (c)
        indices[counter++] = (r + 1) * sectorsPlusOne + s;    // (b)
        indices[counter++] = (r + 1) * sectorsPlusOne + (s + 1);  // (d)
      }
    }

    // 创建FloatBuffer和ShortBuffer
    const vertexBuffer = new Float32Array(vertexs);
    const texBuffer = new Float32Array(texcoords);
    const indexBuffer = new Uint16Array(indices);

    object3D.setIndicesBuffer(indexBuffer);
    object3D.setTexCoordinateBuffer(0, texBuffer);
    object3D.setTexCoordinateBuffer(1, texBuffer);
    object3D.setVerticesBuffer(0, vertexBuffer);
    object3D.setVerticesBuffer(1, vertexBuffer);
    object3D.setNumIndices(indices.length);
  }
}

