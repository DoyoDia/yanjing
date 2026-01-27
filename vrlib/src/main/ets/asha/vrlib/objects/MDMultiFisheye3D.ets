/**
 * Created by hzqiujiadi on 16/7/29.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsObject3D } from './MDAbsObject3D';
import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 多鱼眼3D对象类
 */
export class MDMultiFisheye3D extends MDAbsObject3D {
  private static readonly TAG: string = "MDMultiFisheye3D";

  // 与基类保持相同的可见性（public），避免 ArkTS 继承错误
  executeLoad(context: Context): void {
    MDMultiFisheye3D.generateSphere(18, 29, 30, this);
  }

  private static generateSphere(radius: number, rings: number, sectors: number, object3D: MDMultiFisheye3D): void {
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

        vertexs[v++] = x * radius;
        vertexs[v++] = y * radius;
        vertexs[v++] = z * radius;

        if (t * 2 < numPoint) {
          const a = (Math.sin(2 * PI * s * S) * r * R * 2 * 0.65) * 0.5 + 0.5;
          const b = (Math.cos(2 * PI * s * S) * r * R * 2 * 0.65) * 0.5 + 0.5;

          texcoords[t * 2] = a;
          texcoords[t * 2 + 1] = b * 0.5;
        } else {
          const a = (Math.sin(2 * PI * s * S) * (1 - r * R) * 2 * 0.65) * 0.5 + 0.5;
          const b = (Math.cos(2 * PI * s * S) * (1 - r * R) * 2 * 0.65) * 0.5 + 0.5;

          texcoords[t * 2] = 1 - a;
          texcoords[t * 2 + 1] = b * 0.5 + 0.5;
        }
        t++;
      }
    }

    // 调试日志（可选）
    // for (let k = 0; k < numPoint; k++) {
    //   console.log(`p ${k},`);
    //   console.log(`v ${k}, x=${vertexs[k * 3]} y=${vertexs[k * 3 + 1]} z=${vertexs[k * 3 + 2]}`);
    //   console.log(`t ${k}, x=${texcoords[k * 2]} y=${texcoords[k * 2 + 1]}`);
    // }

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

