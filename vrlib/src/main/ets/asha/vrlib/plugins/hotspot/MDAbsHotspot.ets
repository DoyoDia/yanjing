/**
 * Created by hzqiujiadi on 2017/4/12.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsPlugin } from '../MDAbsPlugin';
import { IMDHotspot } from './IMDHotspot';
import { MDPluginBuilder } from '../../model/MDPluginBuilder';
import { MDHitPoint } from '../../model/MDHitPoint';
import { MDRay } from '../../model/MDRay';
import { MDHitEvent } from '../../model/MDHitEvent';
import { MDPosition } from '../../model/MDPosition';
import { MDVector3D } from '../../model/MDVector3D';
import { VRUtil } from '../../common/VRUtil';
import { GLUtil } from '../../common/GLUtil';
import { Context, RectF } from '../../../../google/android/apps/muzei/render/ViewTypes';

import { MD360Program } from '../../MD360Program';
import { MD360Director } from '../../MD360Director';
import { ITouchPickListener } from '../../model/MDTypes';
import { MDAbsObject3D, FloatBuffer } from '../../objects/MDAbsObject3D';
import { MDPlane } from '../../objects/MDPlane';
import { MDObject3DHelper } from '../../objects/MDObject3DHelper';

// type MD360Program = any;
// type MD360Director = any;
// type ITouchPickListener = any;
// type MDAbsObject3D = any;
// type FloatBuffer = any;
// type Context = any;
// type RectF = {
//   width: number;
//   height: number;
// };

class HitPoint1 extends MDHitPoint {
  override getV(): number {
    return 1 - super.getV();
  }
}

class HitPoint2 extends MDHitPoint {
  override getU(): number {
    return 1 - super.getU();
  }
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
 * 抽象热点类
 */
export abstract class MDAbsHotspot extends MDAbsPlugin implements IMDHotspot {
  private size: RectF;
  private object3D: MDAbsObject3D | null = null;
  protected program: MD360Program | null = null;

  // hotspot
  private title: string | null = null;
  private tag: string | null = null;
  private clickListener: ITouchPickListener | null = null;

  private hitPoint1: MDHitPoint = new HitPoint1();

  private hitPoint2: MDHitPoint = new HitPoint2();

  private mPendingRotateToCamera: boolean = false;

  constructor(builder: MDPluginBuilder) {
    super();
    this.setTag(builder.mTag);
    this.setTitle(builder.mTitle);
    this.clickListener = builder.mClickListener;
    this.size = new RectFImpl();
    this.size.set(0, 0, builder.mWidth, builder.mHeight);
    this.setModelPosition(builder.mPosition == null ? MDPosition.getOriginalPosition() : builder.mPosition);
  }

  protected initInGL(context: Context): void {
    // program = new MD360Program(MDVRLibrary.ContentType.BITMAP);
    // program.build(context);

    // 加载obj
    // object3D = new MDPlane(this.size);
    // MDObject3DHelper.loadObj(context, this.object3D);
  }

  destroyInGL(): void {
    // 空实现
  }

  beforeRenderer(totalWidth: number, totalHeight: number): void {
    // 空实现
  }

  renderer(index: number, width: number, height: number, director: MD360Director): void {
    // 更新投影
    director.setViewport(width, height);

    // 使用着色器程序
    // program.use();
    GLUtil.glCheck("MDSimplePlugin mProgram use");

    // object3D.uploadVerticesBufferIfNeed(program, index);
    // object3D.uploadTexCoordinateBufferIfNeed(program, index);

    // 传入组合矩阵
    director.beforeShot();
    this.consumePendingRotateToCamera(director);
    // director.shot(program, this.getModelPosition());

    // 启用混合模式（用于透明渲染）
    // GL_SRC_ALPHA = 0x0302, GL_ONE_MINUS_SRC_ALPHA = 0x0303
    if (this.mNapi) {
      this.mNapi.setBlendEnabled(true);
      this.mNapi.setBlendFunc(0x0302, 0x0303); // GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
    }

    // object3D.draw();
    
    // 禁用混合模式
    if (this.mNapi) {
      this.mNapi.setBlendEnabled(false);
    }
  }

  removable(): boolean {
    return true;
  }

  getTitle(): string | null {
    return this.title;
  }

  setTitle(title: string | null): void {
    this.title = title;
  }

  getTag(): string | null {
    return this.tag;
  }

  setTag(tag: string | null): void {
    this.tag = tag;
  }

  hit(ray: MDRay): MDHitPoint {
    if (this.object3D == null || this.object3D.getVerticesBuffer(0) == null) {
      return MDHitPoint.notHit();
    }

    const position = this.getModelPosition();
    const model = position.getMatrix();

    const points: MDVector3D[] = [];

    const buffer: FloatBuffer | null = this.object3D.getVerticesBuffer(0);
    if (buffer == null) {
      return MDHitPoint.notHit();
    }
    const numPoints = buffer.length / 3;

    for (let i = 0; i < numPoints; i++) {
      const v = new MDVector3D();
      v.setX(buffer[i * 3]).setY(buffer[i * 3 + 1]).setZ(buffer[i * 3 + 2]);
      v.multiplyMV(model);
      points.push(v);
    }

    const hit1 = this.hitPoint1;
    const hit2 = this.hitPoint2;
    if (points.length === 4) {
      VRUtil.intersectTriangle(ray, points[0], points[1], points[2], this.hitPoint1);
      VRUtil.intersectTriangle(ray, points[3], points[2], points[1], this.hitPoint2);
    }

    return MDHitPoint.min(hit1, hit2);
  }

  onEyeHitIn(hitEvent: MDHitEvent): void {
    // 空实现，子类可重写
  }

  onEyeHitOut(timestamp: number): void {
    // 空实现，子类可重写
  }

  onTouchHit(ray: MDRay): void {
    if (this.clickListener != null) {
      // clickListener.onHotspotHit(this, ray);
    }
  }

  rotateToCamera(): void {
    this.mPendingRotateToCamera = true;
  }

  private consumePendingRotateToCamera(director: MD360Director): void {
    if (this.mPendingRotateToCamera) {
      const position = this.getModelPosition();
      const rotation = director.getWorldRotationInvert();
      position.setRotationMatrix(rotation);
      this.mPendingRotateToCamera = false;
    }
  }
}

