/**
 * Created by hzqiujiadi on 16/4/5.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MD360Texture } from './MD360Texture';
import { MDMainHandler } from '../common/MDMainHandler';
import { VRUtil } from '../common/VRUtil';
import { MD360Program, IBitmapProvider, Bitmap, IMD360BitmapTextureCallback } from '../model/MDTypes';

/**
 * 位图纹理类
 */
export class MD360BitmapTexture extends MD360Texture {
  private static readonly TAG_BITMAP: string = "MD360BitmapTexture";
  private mBitmapProvider: IBitmapProvider | null = null;
  private mIsReady: boolean = false;
  private mTmpAsyncCallback: AsyncCallback | null = null;
  private mTextureDirty: boolean = false;

  constructor(bitmapProvider: IBitmapProvider) {
    super();
    this.mBitmapProvider = bitmapProvider;
  }

  protected createTextureId(): number {
    // const textureHandle: number[] = new Array(1);
    // GLES20.glGenTextures(1, textureHandle, 0);
    // const textureId = textureHandle[0];
    // 在鸿蒙中，需要使用对应的OpenGL API
    // 占位实现
    const textureId = 1; // 占位值

    // 调用提供者加载位图
    this.loadTexture();
    return textureId;
  }

  /**
   * GL线程中调用
   */
  texture(program: MD360Program): boolean {
    if (this.mTextureDirty) {
      this.loadTexture();
      this.mTextureDirty = false;
    }

    const asyncCallback = this.mTmpAsyncCallback;
    const textureId = this.getCurrentTextureId();
    if (asyncCallback != null && asyncCallback.hasBitmap()) {
      const bitmap = asyncCallback.getBitmap();
      if (bitmap) {
        this.textureInThread(textureId, program, bitmap);
      }
      asyncCallback.releaseBitmap();
      this.mIsReady = true;
    }

    if (this.isReady() && textureId !== 0) {
      // GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
      // GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId);
      // GLES20.glUniform1i(program.getTextureUniformHandle(), 0);
      // 在鸿蒙中，需要使用对应的OpenGL API
    }
    return true;
  }

  notifyChanged(): void {
    this.mTextureDirty = true;
  }

  /**
   * 从GL线程调用
   */
  private loadTexture(): void {
    // 释放之前的引用
    if (this.mTmpAsyncCallback != null) {
      this.mTmpAsyncCallback.releaseBitmap();
      this.mTmpAsyncCallback = null;
    }

    // 获取纹理最大尺寸
    // const maxSize: number[] = new Array(1);
    // GLES20.glGetIntegerv(GLES20.GL_MAX_TEXTURE_SIZE, maxSize, 0);
    // 在鸿蒙中，需要使用对应的OpenGL API
    const maxSize: number = 4096; // 占位值

    const finalCallback = new AsyncCallback(maxSize);

    // 创建新的回调
    this.mTmpAsyncCallback = finalCallback;

    MDMainHandler.sharedHandler().post(() => {
      if (this.mBitmapProvider != null) {
        this.mBitmapProvider.onProvideBitmap(finalCallback);
      }
    });
  }

  isReady(): boolean {
    return this.mIsReady;
  }

  destroy(): void {
    // 释放之前的引用
    if (this.mTmpAsyncCallback != null) {
      this.mTmpAsyncCallback.releaseBitmap();
      this.mTmpAsyncCallback = null;
    }
  }

  release(): void {
    // 空实现
  }

  private textureInThread(textureId: number, program: MD360Program, bitmap: Bitmap): void {
    VRUtil.notNull(bitmap, "bitmap can't be null!");

    if (this.isEmpty(textureId)) return;

    // GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
    // GLUtil.glCheck("MD360BitmapTexture glActiveTexture");

    // 绑定纹理到OpenGL
    // GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId);
    // GLUtil.glCheck("MD360BitmapTexture glBindTexture");

    // 设置过滤
    // GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
    // GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_NEAREST);
    // GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
    // GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);

    // 将位图加载到绑定的纹理中
    // GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0);
    // GLUtil.glCheck("MD360BitmapTexture texImage2D");

    // GLES20.glUniform1i(program.getTextureUniformHandle(), 0);
    // GLUtil.glCheck("MD360BitmapTexture textureInThread");
    // 在鸿蒙中，需要使用对应的OpenGL API
  }
}

export namespace MD360BitmapTexture {
  export type Callback = IMD360BitmapTextureCallback;
}

/**
 * 异步回调类
 */
class AsyncCallback implements MD360BitmapTexture.Callback {
  private bitmapRef: Bitmap | null = null; // 在ETS中，不使用SoftReference，直接使用引用
  private maxSize: number;

  constructor(maxSize: number) {
    this.maxSize = maxSize;
  }

  texture(bitmap: Bitmap): void {
    this.releaseBitmap();
    this.bitmapRef = bitmap;
  }

  getMaxTextureSize(): number {
    return this.maxSize;
  }

  getBitmap(): Bitmap | null {
    return this.bitmapRef;
  }

  hasBitmap(): boolean {
    return this.bitmapRef != null;
  }

  releaseBitmap(): void {
    this.bitmapRef = null;
  }
}

