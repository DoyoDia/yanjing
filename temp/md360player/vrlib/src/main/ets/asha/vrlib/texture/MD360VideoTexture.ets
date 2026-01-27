/**
 * Created by hzqiujiadi on 16/4/5.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MD360Texture } from './MD360Texture';
import { GLUtil } from '../common/GLUtil';
import { MD360Program, IOnSurfaceReadyCallback } from '../model/MDTypes';
import { Context, Surface, SurfaceTexture } from '../../../google/android/apps/muzei/render/ViewTypes';

/**
 * 视频纹理类
 */
export class MD360VideoTexture extends MD360Texture {
  private mSurface: Surface | null = null;
  private mSurfaceTexture: SurfaceTexture | null = null;
  private mOnSurfaceReadyListener: IOnSurfaceReadyCallback | null = null;
  private mTransformMatrix: number[] = new Array(16).fill(0);
  private static readonly sUseTransform: number[] = [1];

  constructor(onSurfaceReadyListener: IOnSurfaceReadyCallback) {
    super();
    this.mOnSurfaceReadyListener = onSurfaceReadyListener;
  }

  release(): void {
    this.mOnSurfaceReadyListener = null;
  }

  override create(): void {
    super.create();
    const glSurfaceTexture = this.getCurrentTextureId();
    if (this.isEmpty(glSurfaceTexture)) return;

    this.onCreateSurface(glSurfaceTexture);
  }

  isReady(): boolean {
    return true;
  }

  destroy(): void {
    if (this.mSurfaceTexture != null) {
      // mSurfaceTexture.release();
      // 在鸿蒙中，需要使用对应的SurfaceTexture API
      this.mSurfaceTexture = null;
    }

    if (this.mSurface != null) {
      // mSurface.release();
      // 在鸿蒙中，需要使用对应的Surface API
      this.mSurface = null;
    }
  }

  private onCreateSurface(glSurfaceTextureId: number): void {
    if (this.mSurfaceTexture == null) {
      // 将纹理附加到Surface
      // 这是将Android视图渲染到GL级别的关键类
      // mSurfaceTexture = new SurfaceTexture(glSurfaceTextureId);
      // mSurfaceTexture.setDefaultBufferSize(getWidth(), getHeight());
      // mSurface = new Surface(mSurfaceTexture);
      // 在鸿蒙中，需要使用对应的SurfaceTexture和Surface API
      // 占位实现
      this.mSurfaceTexture = {} as SurfaceTexture; // 占位
      this.mSurface = {} as Surface; // 占位

      if (this.mOnSurfaceReadyListener != null) {
        this.mOnSurfaceReadyListener.onSurfaceReady(this.mSurface);
      }
    }
  }

  protected createTextureId(): number {
    // const textures: number[] = new Array(1);

    // 生成Android视图将渲染到的纹理
    // GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
    // GLES20.glGenTextures(1, textures, 0);
    // GLUtil.glCheck("Texture generate");

    // GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textures[0]);
    // GLUtil.glCheck("Texture bind");

    // GLES20.glTexParameterf(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GL10.GL_TEXTURE_MIN_FILTER, GL10.GL_LINEAR);
    // GLES20.glTexParameterf(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GL10.GL_TEXTURE_MAG_FILTER, GL10.GL_LINEAR);
    // GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GL10.GL_TEXTURE_WRAP_S, GL10.GL_CLAMP_TO_EDGE);
    // GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GL10.GL_TEXTURE_WRAP_T, GL10.GL_CLAMP_TO_EDGE);
    // 在鸿蒙中，需要使用对应的OpenGL API
    // 占位实现
    return 1; // 占位值
  }

  texture(program: MD360Program): boolean {
    const glSurfaceTexture = this.getCurrentTextureId();
    if (this.isEmpty(glSurfaceTexture)) return false;
    if (this.mSurfaceTexture == null) return false;

    // mSurfaceTexture.updateTexImage();
    // 在鸿蒙中，需要使用对应的SurfaceTexture API

    // 获取surface变换矩阵
    // mSurfaceTexture.getTransformMatrix(this.mTransformMatrix);
    // GLES20.glUniform1iv(program.getUseTextureTransformHandle(), 1, MD360VideoTexture.sUseTransform, 0);
    // GLES20.glUniformMatrix4fv(program.getSTMatrixHandle(), 1, false, this.mTransformMatrix, 0);
    // 在鸿蒙中，需要使用对应的OpenGL API
    return true;
  }

  notifyChanged(): void {
    if (this.mSurface != null && this.mOnSurfaceReadyListener != null) {
      this.mOnSurfaceReadyListener.onSurfaceReady(this.mSurface);
    }
  }
}

