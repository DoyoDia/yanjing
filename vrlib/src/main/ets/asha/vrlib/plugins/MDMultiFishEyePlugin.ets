/**
 * Created by hzqiujiadi on 16/8/20.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsPlugin } from './MDAbsPlugin';
import { MDMainPluginBuilder } from '../model/MDMainPluginBuilder';
import { MDDirection } from '../common/MDDirection';
import { MDPosition } from '../model/MDPosition';
import { MDObject3DHelper } from '../objects/MDObject3DHelper';
import { MDDrawingCache } from './MDDrawingCache';
import { GLUtil } from '../common/GLUtil';
import { MDAbsObject3D, FloatBuffer, ShortBuffer } from '../objects/MDAbsObject3D';
import { MD360Program } from '../MD360Program';
import { MD360Texture } from '../texture/MD360Texture';
import { MD360Director } from '../MD360Director';
import { MD360DirectorFactory, OrthogonalDirectorFactory } from '../MD360DirectorFactory';
import { MDVRLibrary } from '../MDVRLibrary';
import { ProjectionModeManager } from '../strategy/projection/ProjectionModeManager';
import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 多鱼眼插件类
 */
export class MDMultiFishEyePlugin extends MDAbsPlugin {
  private mProgram: MD360Program | null = null;
  private mBitmapProgram: MD360Program | null = null;
  private mTexture: MD360Texture | null = null;
  private mProjectionModeManager: ProjectionModeManager | null = null;
  private mConverterObject3D: MDMultiFishEyeMesh | null = null;
  private mFixedDirector: MD360Director | null = null;
  private mDrawingCache: MDDrawingCache | null = null;

  constructor(builder: MDMainPluginBuilder, radius: number, direction: MDDirection) {
    super();
    this.mTexture = builder.getTexture();
    // this.mProgram = new MD360Program(builder.getContentType());
    // this.mBitmapProgram = new MD360Program(MDVRLibrary.ContentType.FBO);
    this.mProjectionModeManager = builder.getProjectionModeManager();
    // this.mFixedDirector = new OrthogonalDirectorFactory().createDirector(0);
    this.mConverterObject3D = new MDMultiFishEyeMesh(radius, direction);
    this.mDrawingCache = new MDDrawingCache();
  }

  protected initInGL(context: Context): void {
    // mProgram.build(context);
    // mBitmapProgram.build(context);
    // mTexture.create();
    if (this.mConverterObject3D != null) {
      MDObject3DHelper.loadObj(context, this.mConverterObject3D);
    }
  }

  beforeRenderer(totalWidth: number, totalHeight: number): void {
    if (this.mFixedDirector != null && this.mDrawingCache != null) {
      this.mFixedDirector.setViewport(totalWidth, totalHeight);
      this.mDrawingCache.bind(totalWidth, totalHeight);
      this.drawConverter(totalWidth, totalHeight);
      this.mDrawingCache.unbind();
    }
  }

  renderer(index: number, width: number, height: number, director: MD360Director): void {
    const object3D = this.mProjectionModeManager?.getObject3D();
    if (object3D == null) {
      return;
    }

    director.setViewport(width, height);

    // mBitmapProgram.use();
    GLUtil.glCheck("MDPanoramaPlugin mProgram use");

    // GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
    // GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, this.mDrawingCache.getTextureOutput());

    // object3D.uploadVerticesBufferIfNeed(mBitmapProgram, index);
    // object3D.uploadTexCoordinateBufferIfNeed(mBitmapProgram, index);

    director.beforeShot();
    // director.shot(mBitmapProgram, this.getModelPosition());
    // object3D.draw();
  }

  destroyInGL(): void {
    this.mTexture = null;
  }

  protected getModelPosition(): MDPosition {
    return this.mProjectionModeManager?.getModelPosition() || MDPosition.getOriginalPosition();
  }

  public removable(): boolean {
    return false;
  }

  private drawConverter(width: number, height: number): void {
    // GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT | GLES20.GL_DEPTH_BUFFER_BIT);
    GLUtil.glCheck("MDMultiFisheyeConvertLinePipe glClear");

    const itemWidth = Math.floor(width / 2);
    for (let index = 0; index < 2; index++) {
      // 设置视口和裁剪区域（用于分屏渲染）
      if (this.mNapi) {
        const viewportX = itemWidth * index;
        const viewportY = 0;
        this.mNapi.setViewport(viewportX, viewportY, itemWidth, height);
        this.mNapi.setScissor(viewportX, viewportY, itemWidth, height);
        this.mNapi.setScissorEnabled(true);
      }

      // mProgram.use();
      // mTexture.texture(mProgram);

      if (this.mFixedDirector != null) {
        this.mFixedDirector.setViewport(itemWidth, height);
        // this.mConverterObject3D.uploadVerticesBufferIfNeed(mProgram, index);
        // this.mConverterObject3D.uploadTexCoordinateBufferIfNeed(mProgram, index);

        this.mFixedDirector.beforeShot();
        // this.mFixedDirector.shot(mProgram, MDPosition.getOriginalPosition());
      }

      // this.mConverterObject3D.draw();
      
      // 禁用裁剪（如果启用）
      if (this.mNapi) {
        this.mNapi.setScissorEnabled(false);
      }
    }
  }
}

/**
 * 多鱼眼网格类（用于多鱼眼插件）
 */
class MDMultiFishEyeMesh extends MDAbsObject3D {
  private static readonly TAG: string = "MDMesh";
  private readonly direction: MDDirection;
  private readonly radius: number;

  constructor(radius: number, direction: MDDirection) {
    super();
    this.radius = radius;
    this.direction = direction;
  }

  public executeLoad(context: Context): void {
    this.generateMesh(this);
  }

  private generateMesh(object3D: MDAbsObject3D): void {
    const PI = Math.PI;
    const rows = 16;
    const columns = 16;
    const numPoint = (rows + 1) * (columns + 1);
    let r: number, s: number;
    const z = -8;
    const R = 1.0 / rows;
    const S = 1.0 / columns;

    const vertexs: number[] = new Array(numPoint * 3);
    const texcoords: number[] = new Array(numPoint * 2);
    const texcoords2: number[] = new Array(numPoint * 2);
    const indices: number[] = new Array(numPoint * 6);

    let t = 0;
    let v = 0;
    for (r = 0; r < rows + 1; r++) {
      for (s = 0; s < columns + 1; s++) {
        vertexs[v++] = (s * S * 2 - 1);
        vertexs[v++] = (r * R * 2 - 1);
        vertexs[v++] = z;

        const FOV = Math.PI; // FOV of the fisheye, eg: 180 degrees
        const width = 1;
        const height = 1;

        let theta = PI * (s * S - 0.5); // -pi to pi
        let phi = PI * (r * R - 0.5); // -pi/2 to pi/2

        let psphx = Math.cos(phi) * Math.sin(theta);
        let psphy = Math.cos(phi) * Math.cos(theta);
        let psphz = Math.sin(phi);

        theta = Math.atan2(psphz, psphx);
        phi = Math.atan2(Math.sqrt(psphx * psphx + psphz * psphz), psphy);
        const rr = this.radius * phi / FOV;

        const a = 0.5 * width + rr * Math.cos(theta);
        const b = 0.5 * height + rr * Math.sin(theta);

        if (this.direction === MDDirection.HORIZONTAL) {
          texcoords[t * 2] = a * 0.5;
          texcoords[t * 2 + 1] = b;
          texcoords2[t * 2] = a * 0.5 + 0.5;
          texcoords2[t * 2 + 1] = b;
        } else {
          texcoords[t * 2] = a;
          texcoords[t * 2 + 1] = b * 0.5;
          texcoords2[t * 2] = a;
          texcoords2[t * 2 + 1] = b * 0.5 + 0.5;
        }

        t++;
      }
    }

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
    const vertexBuffer = new Float32Array(vertexs);
    const texBuffer = new Float32Array(texcoords);
    const texBuffer2 = new Float32Array(texcoords2);
    const indexBuffer = new Uint16Array(indices);

    object3D.setIndicesBuffer(indexBuffer);
    object3D.setTexCoordinateBuffer(0, texBuffer);
    object3D.setTexCoordinateBuffer(1, texBuffer2);
    object3D.setVerticesBuffer(0, vertexBuffer);
    object3D.setVerticesBuffer(1, vertexBuffer);
    object3D.setNumIndices(indices.length);
  }
}

