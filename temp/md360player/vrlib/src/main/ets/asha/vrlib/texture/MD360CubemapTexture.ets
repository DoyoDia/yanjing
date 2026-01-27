/**
 * 立方体贴图纹理类
 */

import { MD360Texture } from './MD360Texture';
import { MDMainHandler } from '../common/MDMainHandler';
import { GLUtil } from '../common/GLUtil';
import { VRUtil } from '../common/VRUtil';
import { MD360Program, Bitmap } from '../model/MDTypes';

// TODO: 当相关类型迁移后，取消注释并删除类型占位符
// import { MD360Program } from '../MD360Program';
// import { MDVRLibrary } from '../MDVRLibrary';

export interface ICubemapProvider {
  onProvideCubemap(callback: MD360CubemapTextureCallback, face: number): void;
  onReady(): void;
}

/**
 * 立方体贴图纹理类
 */
export class MD360CubemapTexture extends MD360Texture {
  private static readonly TAG_CUBEMAP: string = "MD360CubemapTexture";

  public static readonly CUBE_FRONT: number = 0;
  public static readonly CUBE_BACK: number = 1;
  public static readonly CUBE_LEFT: number = 2;
  public static readonly CUBE_RIGHT: number = 3;
  public static readonly CUBE_TOP: number = 4;
  public static readonly CUBE_BOTTOM: number = 5;

  // private static readonly CUBE_TARGETS: number[] = [
  //   GLES20.GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
  //   GLES20.GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
  //   GLES20.GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
  //   GLES20.GL_TEXTURE_CUBE_MAP_POSITIVE_X,
  //   GLES20.GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
  //   GLES20.GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
  // ];
  // 在鸿蒙中，需要使用对应的OpenGL常量
  private static readonly CUBE_TARGETS: number[] = [0, 1, 2, 3, 4, 5]; // 占位值

  private mCubemapProvider: ICubemapProvider | null = null;
  private mIsReady: boolean = false;
  private mTmpAsyncCallback: AsyncCallback | null = null;
  private mTextureDirty: boolean = false;
  private static readonly sIsSkybox: number[] = [1];
  private currentFaceLoading: number = MD360CubemapTexture.CUBE_FRONT;

  constructor(cubemapProvider: ICubemapProvider) {
    super();
    this.mCubemapProvider = cubemapProvider;
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
      this.mTextureDirty = false;
      this.currentFaceLoading = MD360CubemapTexture.CUBE_FRONT;

      this.loadTexture();

      this.mIsReady = false;
    }

    const asyncCallback = this.mTmpAsyncCallback;
    const textureId = this.getCurrentTextureId();

    if (!this.mIsReady && asyncCallback != null) {
      if (asyncCallback.hasBitmap()) {
        const bitmap = asyncCallback.getBitmap();
        console.debug(MD360CubemapTexture.TAG_CUBEMAP, "Set texture " + this.currentFaceLoading);

        if (bitmap) {
          this.textureInThread(textureId, program, bitmap, this.currentFaceLoading);
        }
        asyncCallback.releaseBitmap();

        this.currentFaceLoading++;
        if (this.currentFaceLoading < 6) {
          this.requestBitmap();
        }
      }

      if (this.currentFaceLoading >= 6) {
        this.mIsReady = true;

        if (this.mCubemapProvider != null) {
          MDMainHandler.sharedHandler().post(() => {
            this.mCubemapProvider?.onReady();
          });
        }
      }
    }

    if (this.isReady() && textureId !== 0) {
      // 绑定纹理
      // 设置纹理0为活动纹理
      // GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
      // 将立方体贴图纹理绑定到活动的OpenGL纹理
      // GLES20.glBindTexture(GLES20.GL_TEXTURE_CUBE_MAP, textureId);
      // 设置着色器纹理变量为纹理0
      // GLES20.glUniform1i(program.getTextureUniformHandle(), 0);
      // 设置着色器isSkybox标志为true
      // GLES20.glUniform1iv(program.getIsSkyboxHandle(), 1, MD360CubemapTexture.sIsSkybox, 0);
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
    const maxSize = 4096; // 占位值

    // 创建新的回调
    this.mTmpAsyncCallback = new AsyncCallback(maxSize);

    this.requestBitmap();
  }

  private requestBitmap(): void {
    MDMainHandler.sharedHandler().post(() => {
      if (this.mCubemapProvider != null && this.mTmpAsyncCallback != null) {
        this.mCubemapProvider.onProvideCubemap(this.mTmpAsyncCallback, this.currentFaceLoading);
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

  private textureInThread(textureId: number, program: MD360Program, bitmap: Bitmap, face: number): void {
    VRUtil.notNull(bitmap, "bitmap can't be null!");

    if (this.isEmpty(textureId)) return;

    // GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
    // GLUtil.glCheck("MD360CubemapTexture glActiveTexture");

    // 绑定纹理到OpenGL
    // GLES20.glBindTexture(GLES20.GL_TEXTURE_CUBE_MAP, textureId);
    // GLUtil.glCheck("MD360CubemapTexture glBindTexture");

    // 设置过滤
    // GLES20.glTexParameteri(GLES20.GL_TEXTURE_CUBE_MAP, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
    // GLES20.glTexParameteri(GLES20.GL_TEXTURE_CUBE_MAP, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
    // GLES20.glTexParameteri(GLES20.GL_TEXTURE_CUBE_MAP, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
    // GLES20.glTexParameteri(GLES20.GL_TEXTURE_CUBE_MAP, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);

    // 将位图加载到绑定的纹理中
    // GLUtils.texImage2D(MD360CubemapTexture.CUBE_TARGETS[face], 0, bitmap, 0);
    // GLUtil.glCheck("MD360CubemapTexture texImage2D");

    // 设置着色器纹理变量为纹理0
    // GLES20.glUniform1i(program.getTextureUniformHandle(), 0);
    // GLUtil.glCheck("MD360CubemapTexture textureInThread");
    // 在鸿蒙中，需要使用对应的OpenGL API
  }
}

/**
 * 异步回调类
 * @todo 这个可以重构，因为它在@MD360BitmapTexture中重复了
 */
class AsyncCallback implements MD360CubemapTextureCallback {
  private bitmapRef: Bitmap | null = null; // 在ETS中，不使用SoftReference，直接使用引用
  private maxSize: number;

  constructor(maxSize: number) {
    this.maxSize = maxSize;
  }

  texture(bitmap: Bitmap): void {
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

/**
 * 回调接口
 */
export interface MD360CubemapTextureCallback {
  texture(bitmap: Bitmap): void;
  getMaxTextureSize(): number;
}

