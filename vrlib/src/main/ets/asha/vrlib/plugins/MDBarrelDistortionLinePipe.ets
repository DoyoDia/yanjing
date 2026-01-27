/**
 * Created by hzqiujiadi on 16/7/27.
 * hzqiujiadi ashqalcn@gmail.com
 *
 * Barrel Distortion
 *
 * For more info,
 * http://stackoverflow.com/questions/12620025/barrel-distortion-correction-algorithm-to-correct-fisheye-lens-failing-to-impl
 */

import { MDAbsLinePipe } from './MDAbsLinePipe';
import { MDDrawingCache } from './MDDrawingCache';
import { BarrelDistortionConfig } from '../model/BarrelDistortionConfig';
import { MDPosition } from '../model/MDPosition';
import { MDObject3DHelper } from '../objects/MDObject3DHelper';
import { VRUtil, PointF } from '../common/VRUtil';
import { GLUtil } from '../common/GLUtil';
import { MDAbsObject3D, FloatBuffer, ShortBuffer } from '../objects/MDAbsObject3D';

import { MD360Program } from '../model/MDTypes';
import { MD360Director } from '../MD360Director';
import { MD360DirectorFactory } from '../MD360DirectorFactory';
import { MDVRLibrary } from '../MDVRLibrary';
import { DisplayModeManager } from '../strategy/display/DisplayModeManager';
import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';

// type MD360Program = any;
// type MD360Director = any;
// type MD360DirectorFactory = any;
// type DisplayModeManager = any;
// type Context = any;

/**
 * 桶形畸变管线类
 */
export class MDBarrelDistortionLinePipe extends MDAbsLinePipe {
  private mProgram: MD360Program | null = null;
  private mObject3D: MDBarrelDistortionMesh | null = null;
  private mDirector: MD360Director | null = null;
  private mEnabled: boolean = false;
  private mDrawingCache: MDDrawingCache | null = null;
  private mConfiguration: BarrelDistortionConfig | null = null;
  private mDisplayModeManager: DisplayModeManager | null = null;

  constructor(displayModeManager: DisplayModeManager) {
    super();
    this.mDisplayModeManager = displayModeManager;
    this.mConfiguration = displayModeManager.getBarrelDistortionConfig();
    // this.mProgram = new MD360Program(MDVRLibrary.ContentType.FBO);
    // this.mDirector = new MD360DirectorFactory.OrthogonalImpl().createDirector(0);
    this.mObject3D = new MDBarrelDistortionMesh(this.mConfiguration);
    this.mDrawingCache = new MDDrawingCache();
  }

  protected init(context: Context): void {
    // mProgram.build(context);
    if (this.mObject3D != null) {
      MDObject3DHelper.loadObj(context, this.mObject3D);
    }
  }

  takeOver(totalWidth: number, totalHeight: number, size: number): void {
    this.mEnabled = this.mDisplayModeManager?.isAntiDistortionEnabled() || false;
    if (!this.mEnabled) {
      return;
    }

    if (this.mDrawingCache != null) {
      this.mDrawingCache.bind(totalWidth, totalHeight);
    }

    if (this.mDirector != null) {
      this.mDirector.setViewport(totalWidth, totalHeight);
    }
    if (this.mObject3D != null) {
      this.mObject3D.setMode(size);
    }

    // GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT | GLES20.GL_DEPTH_BUFFER_BIT);
    GLUtil.glCheck("MDBarrelDistortionLinePipe glClear");
  }

  commit(totalWidth: number, totalHeight: number, size: number): void {
    if (!this.mEnabled) {
      return;
    }
    if (this.mDrawingCache != null) {
      this.mDrawingCache.unbind();
    }

    const width = Math.floor(totalWidth / size);
    for (let i = 0; i < size; i++) {
      // 设置视口和裁剪区域（用于分屏渲染）
      if (this.mNapi) {
        const viewportX = width * i;
        const viewportY = 0;
        this.mNapi.setViewport(viewportX, viewportY, width, totalHeight);
        this.mNapi.setScissor(viewportX, viewportY, width, totalHeight);
        this.mNapi.setScissorEnabled(true);
      }
      
      this.draw(i);
      
      // 禁用裁剪（如果启用）
      if (this.mNapi) {
        this.mNapi.setScissorEnabled(false);
      }
    }
  }

  private draw(index: number): void {
    // mProgram.use();
    GLUtil.glCheck("MDBarrelDistortionLinePipe mProgram use");

    if (this.mObject3D != null) {
      // mObject3D.uploadVerticesBufferIfNeed(mProgram, index);
      // mObject3D.uploadTexCoordinateBufferIfNeed(mProgram, index);
    }

    if (this.mDirector != null) {
      this.mDirector.beforeShot();
      // this.mDirector.shot(mProgram, MDPosition.getOriginalPosition());
    }

    // GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
    // GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, this.mDrawingCache.getTextureOutput());

    if (this.mObject3D != null) {
      // mObject3D.draw();
    }
  }
}

/**
 * 桶形畸变网格类
 */
class MDBarrelDistortionMesh extends MDAbsObject3D {
  private static readonly TAG: string = "MDBarrelDistortionMesh";
  private mode: number = 0;
  private singleTexCoordinateBuffer: Float32Array | null = null;
  private mConfiguration: BarrelDistortionConfig | null = null;

  constructor(configuration: BarrelDistortionConfig | null) {
    super();
    this.mConfiguration = configuration;
  }

  override getTexCoordinateBuffer(index: number): Float32Array | null {
    if (this.mode === 1) {
      return this.singleTexCoordinateBuffer;
    } else if (this.mode === 2) {
      return super.getTexCoordinateBuffer(index);
    } else {
      return null;
    }
  }

  executeLoad(context: Context): void {
    this.generateMesh(this);
  }

  private generateMesh(object3D: MDAbsObject3D): void {
    const rows = 10;
    const columns = 10;
    const numPoint = (rows + 1) * (columns + 1);
    let r: number, s: number;
    const z = -8;
    const R = 1.0 / rows;
    const S = 1.0 / columns;

    const vertexs: number[] = new Array(numPoint * 3);
    const texcoords: number[] = new Array(numPoint * 2);
    const texcoords1: number[] = new Array(numPoint * 2);
    const texcoords2: number[] = new Array(numPoint * 2);
    const indices: number[] = new Array(numPoint * 6);

    let t = 0;
    let v = 0;
    for (r = 0; r < rows + 1; r++) {
      for (s = 0; s < columns + 1; s++) {
        const tu = t++;
        const tv = t++;

        texcoords[tu] = s * S;
        texcoords[tv] = r * R;

        texcoords1[tu] = s * S * 0.5;
        texcoords1[tv] = r * R;

        texcoords2[tu] = s * S * 0.5 + 0.5;
        texcoords2[tv] = r * R;

        vertexs[v++] = (s * S * 2 - 1);
        vertexs[v++] = (r * R * 2 - 1);
        vertexs[v++] = z;
      }
    }

    this.applyBarrelDistortion(numPoint, vertexs);

    let counter = 0;
    const sectorsPlusOne = columns + 1;
    for (r = 0; r < rows; r++) {
      for (s = 0; s < columns; s++) {
        const k0 = r * sectorsPlusOne + (s + 1); // (c)
        const k1 = (r + 1) * sectorsPlusOne + s; // (b)
        const k2 = r * sectorsPlusOne + s; // (a)
        const k3 = r * sectorsPlusOne + (s + 1); // (c)
        const k4 = (r + 1) * sectorsPlusOne + (s + 1); // (d)
        const k5 = (r + 1) * sectorsPlusOne + s; // (b)

        indices[counter++] = k0;
        indices[counter++] = k1;
        indices[counter++] = k2;
        indices[counter++] = k3;
        indices[counter++] = k4;
        indices[counter++] = k5;
      }
    }

    // 创建FloatBuffer和ShortBuffer
    const vertexBuffer: Float32Array = new Float32Array(vertexs);
    const texBuffer: Float32Array = new Float32Array(texcoords);
    const texBuffer1: Float32Array = new Float32Array(texcoords1);
    const texBuffer2: Float32Array = new Float32Array(texcoords2);
    const indexBuffer: Uint16Array = new Uint16Array(indices);

    object3D.setIndicesBuffer(indexBuffer);
    object3D.setTexCoordinateBuffer(0, texBuffer1);
    object3D.setTexCoordinateBuffer(1, texBuffer2);
    object3D.setVerticesBuffer(0, vertexBuffer);
    object3D.setVerticesBuffer(1, vertexBuffer);
    object3D.setNumIndices(indices.length);

    this.singleTexCoordinateBuffer = texBuffer;
  }

  private applyBarrelDistortion(numPoint: number, vertexs: number[]): void {
    if (this.mConfiguration == null) {
      return;
    }

    const pointF: PointF = new PointF();

    for (let i = 0; i < numPoint; i++) {
      const xIndex = i * 3;
      const yIndex = i * 3 + 1;
      const xValue = vertexs[xIndex];
      const yValue = vertexs[yIndex];

      pointF.x = xValue;
      pointF.y = yValue;
      VRUtil.barrelDistortion(
        this.mConfiguration.getParamA(),
        this.mConfiguration.getParamB(),
        this.mConfiguration.getParamC(),
        pointF
      );

      vertexs[xIndex] = pointF.x * this.mConfiguration.getScale();
      vertexs[yIndex] = pointF.y * this.mConfiguration.getScale();
    }
  }

  setMode(mode: number): void {
    this.mode = mode;
  }
}
