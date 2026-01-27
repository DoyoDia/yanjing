/**
 * Created by hzqiujiadi on 16/6/26.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsObject3D, FloatBuffer, ShortBuffer } from './MDAbsObject3D';
import { MD360Program } from '../MD360Program';
import { PlaneProjection } from '../strategy/projection/PlaneProjection';
import { Context, RectF } from '../../../google/android/apps/muzei/render/ViewTypes';

export interface PlaneScaleCalculator {
  calculate(): void;
  getTextureRatio(): number;
  getTextureWidth(): number;
  getTextureHeight(): number;
}

class RectFImpl extends RectF {
  private l: number = 0;
  private t: number = 0;
  private r: number = 0;
  private b: number = 0;

  constructor() {
    super();
  }

  set(left: number, top: number, right: number, bottom: number): void {
    this.l = left;
    this.t = top;
    this.r = right;
    this.b = bottom;
  }
  width(): number {
    return this.r - this.l;
  }
  height(): number {
    return this.b - this.t;
  }
}

/**
 * 平面3D对象类
 */
export class MDPlane extends MDAbsObject3D {
  private static readonly TAG: string = "MDPlane";

  private mPrevRatio: number = 0;
  private mSize: RectF;
  private mCalculator: PlaneScaleCalculator;

  constructor(calculator: PlaneScaleCalculator, size?: RectF) {
    super();
    this.mCalculator = calculator;
    this.mSize = size || new RectFImpl();
    if (!size) {
       this.mSize.set(0, 0, 1, 1);
    }
  }

  public executeLoad(context: Context): void {
    MDPlane.generateMesh(this);
  }

  override uploadVerticesBufferIfNeed(program: MD360Program, index: number): void {
    if (super.getVerticesBuffer(index) == null) {
      return;
    }

    // 仅在 index == 0 时更新纹理
    if (index === 0) {
      const ratio = this.mCalculator.getTextureRatio();
      if (ratio !== this.mPrevRatio) {
        const vertexs = this.generateVertex();

        // 创建新的顶点缓冲区
        const buffer = new Float32Array(vertexs);

        this.setVerticesBuffer(0, buffer);
        this.setVerticesBuffer(1, buffer);

        this.mPrevRatio = ratio;
      }
    }

    super.uploadVerticesBufferIfNeed(program, index);
  }

  private generateVertex(): number[] {
    const z = 0;
    this.mCalculator.calculate();
    this.mPrevRatio = this.mCalculator.getTextureRatio();
    const width = this.mCalculator.getTextureWidth() * this.mSize.width();
    const height = this.mCalculator.getTextureHeight() * this.mSize.height();

    const vertexs: number[] = new Array(this.getNumPoint() * 3);
    const rows = this.getNumRow();
    const columns = this.getNumColumn();
    const R = 1.0 / rows;
    const S = 1.0 / columns;
    let r: number, s: number;

    let v = 0;
    for (r = 0; r < rows + 1; r++) {
      for (s = 0; s < columns + 1; s++) {
        vertexs[v++] = (s * S - 0.5) * width;
        vertexs[v++] = (r * R - 0.5) * height;
        vertexs[v++] = z;
      }
    }

    return vertexs;
  }

  private generateTexcoords(): number[] {
    const texcoords: number[] = new Array(this.getNumPoint() * 2);

    const rows = this.getNumRow();
    const columns = this.getNumColumn();
    const R = 1.0 / rows;
    const S = 1.0 / columns;
    let r: number, s: number;

    let t = 0;
    for (r = 0; r < rows + 1; r++) {
      for (s = 0; s < columns + 1; s++) {
        texcoords[t++] = s * S;
        texcoords[t++] = r * R;
      }
    }

    return texcoords;
  }

  private static generateMesh(object3D: MDPlane): void {
    const rows = object3D.getNumRow();
    const columns = object3D.getNumColumn();
    let r: number, s: number;

    const vertexs = object3D.generateVertex();
    const texcoords = object3D.generateTexcoords();
    const indices: number[] = new Array(object3D.getNumPoint() * 6);

    let counter = 0;
    const sectorsPlusOne = columns + 1;
    for (r = 0; r < rows; r++) {
      for (s = 0; s < columns; s++) {
        const k0 = r * sectorsPlusOne + (s + 1);  // (c)
        const k1 = (r + 1) * sectorsPlusOne + s;    // (b)
        const k2 = r * sectorsPlusOne + s;       // (a)
        const k3 = r * sectorsPlusOne + (s + 1);  // (c)
        const k4 = (r + 1) * sectorsPlusOne + (s + 1);  // (d)
        const k5 = (r + 1) * sectorsPlusOne + s;    // (b)

        indices[counter++] = k0;
        indices[counter++] = k1;
        indices[counter++] = k2;
        indices[counter++] = k3;
        indices[counter++] = k4;
        indices[counter++] = k5;
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

  private getNumPoint(): number {
    return (this.getNumRow() + 1) * (this.getNumColumn() + 1);
  }

  private getNumRow(): number {
    return 1;
  }

  private getNumColumn(): number {
    return 1;
  }
}

