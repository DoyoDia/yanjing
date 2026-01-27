/**
 * Created by hzqiujiadi on 16/1/22.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsObject3D, FloatBuffer, ShortBuffer } from './MDAbsObject3D';
import { MD360Program } from '../MD360Program';
import { Context, RectF } from '../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 圆顶3D对象类
 */
export class MDDome3D extends MDAbsObject3D {
  private mDegree: number;
  private mIsUpper: boolean;
  private mTextureSize: RectF;
  private mPrevRatio: number = 1;
  public texCoordinates: number[] | null = null;

  constructor(textureSize: RectF, degree: number, isUpper: boolean) {
    super();
    this.mTextureSize = textureSize;
    this.mDegree = degree;
    this.mIsUpper = isUpper;
  }

  override uploadTexCoordinateBufferIfNeed(program: MD360Program, index: number): void {
    if (super.getTexCoordinateBuffer(index) == null) {
      return;
    }

    if (index === 0 && this.texCoordinates != null) {
      const ratio = this.mTextureSize.width() / this.mTextureSize.height();
      if (ratio !== this.mPrevRatio) {
        const size = this.texCoordinates.length;
        const tmp: number[] = new Array(size);
        for (let i = 0; i < size; i += 2) {
          tmp[i] = (this.texCoordinates[i] - 0.5) / ratio + 0.5;
          tmp[i + 1] = this.texCoordinates[i + 1];
        }

        const buffer = new Float32Array(tmp);
        this.setTexCoordinateBuffer(0, buffer);
        this.setTexCoordinateBuffer(1, buffer);
        this.mPrevRatio = ratio;
      }
    }

    super.uploadTexCoordinateBufferIfNeed(program, index);
  }

  executeLoad(context: Context): void {
    MDDome3D.generateDome(this.mDegree, this.mIsUpper, this);
  }

  private static generateDome(degree: number, isUpper: boolean, object3D: MDDome3D): void {
    MDDome3D.generateDomeImpl(18, 150, degree, isUpper, object3D);
  }

  public static generateDomeImpl(radius: number, sectors: number, degreeY: number, isUpper: boolean, object3D: MDDome3D): void {
    const PI = Math.PI;
    const PI_2 = Math.PI / 2;

    const percent = degreeY / 360;
    const rings = sectors >> 1;

    const R = 1.0 / rings;
    const S = 1.0 / sectors;
    let r: number, s: number;
    let x: number, y: number, z: number;

    const lenRings = Math.floor(rings * percent) + 1;
    const lenSectors = sectors + 1;
    const numPoint = lenRings * lenSectors;

    const vertexs: number[] = new Array(numPoint * 3);
    const texcoords: number[] = new Array(numPoint * 2);
    const indices: number[] = new Array(numPoint * 6);

    const upper: number = isUpper ? 1 : -1;

    let t = 0, v = 0;
    for (r = 0; r < lenRings; r++) {
      for (s = 0; s < lenSectors; s++) {
        x = Math.cos(2 * PI * s * S) * Math.sin(PI * r * R) * upper;
        y = Math.sin(-PI_2 + PI * r * R) * (upper * -1);
        z = Math.sin(2 * PI * s * S) * Math.sin(PI * r * R);

        const a = (Math.cos(2 * PI * s * S) * r * R / percent) / 2.0 + 0.5;
        const b = (Math.sin(2 * PI * s * S) * r * R / percent) / 2.0 + 0.5;

        texcoords[t++] = b;
        texcoords[t++] = a;

        vertexs[v++] = x * radius;
        vertexs[v++] = y * radius;
        vertexs[v++] = z * radius;
      }
    }

    let counter = 0;
    for (r = 0; r < lenRings - 1; r++) {
      for (s = 0; s < lenSectors - 1; s++) {
        indices[counter++] = r * lenSectors + s;       // (a)
        indices[counter++] = (r + 1) * lenSectors + s;    // (b)
        indices[counter++] = r * lenSectors + (s + 1);  // (c)
        indices[counter++] = r * lenSectors + (s + 1);  // (c)
        indices[counter++] = (r + 1) * lenSectors + s;    // (b)
        indices[counter++] = (r + 1) * lenSectors + (s + 1);  // (d)
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

    object3D.texCoordinates = texcoords;
  }
}

