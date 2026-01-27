/**
 * Created by hzqiujiadi on 16/8/20.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { GLUtil } from '../common/GLUtil';
import { Rect } from '../../../google/android/apps/muzei/render/ViewTypes';

class RectImpl implements Rect {
  private l: number = 0;
  private t: number = 0;
  private r: number = 0;
  private b: number = 0;

  width(): number {
    return this.r - this.l;
  }
  height(): number {
    return this.b - this.t;
  }
  set(left: number, top: number, right: number, bottom: number): void {
    this.l = left;
    this.t = top;
    this.r = right;
    this.b = bottom;
  }
}

/**
 * 绘制缓存类
 * 用于管理帧缓冲区和纹理
 */
export class MDDrawingCache {
  private mTextureIdOutput: number = 0;
  private mFrameBufferId: number = 0;
  private mRenderBufferId: number = 0;
  private mViewport: Rect = new RectImpl();
  private originalFramebufferId: number[] = [0];

  private setup(totalWidth: number, totalHeight: number): void {
    if (this.mViewport.width() !== totalWidth || this.mViewport.height() !== totalHeight) {
      this.createFrameBuffer(totalWidth, totalHeight);
      this.mViewport.set(0, 0, totalWidth, totalHeight);
    }
  }

  private createFrameBuffer(width: number, height: number): void {
    // 在鸿蒙中，需要使用对应的OpenGL API
    // 这里保留接口，具体实现需要在OpenGL封装中完成

    if (this.mTextureIdOutput !== 0) {
      // GLES20.glDeleteTextures(1, [this.mTextureIdOutput], 0);
    }
    if (this.mRenderBufferId !== 0) {
      // GLES20.glDeleteRenderbuffers(1, [this.mRenderBufferId], 0);
    }
    if (this.mFrameBufferId !== 0) {
      // GLES20.glDeleteFramebuffers(1, [this.mFrameBufferId], 0);
    }

    // GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, this.originalFramebufferId, 0);

    // 创建帧缓冲区、渲染缓冲区和纹理
    // 具体实现需要在OpenGL封装中完成

    // GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, this.originalFramebufferId[0]);
    GLUtil.glCheck("Multi Fish Eye attach");
  }

  /**
   * 绑定帧缓冲区
   * @param totalWidth 总宽度
   * @param totalHeight 总高度
   */
  bind(totalWidth: number, totalHeight: number): void {
    this.setup(totalWidth, totalHeight);
    // GLES20.glGetIntegerv(GLES20.GL_FRAMEBUFFER_BINDING, this.originalFramebufferId, 0);
    // GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, this.mFrameBufferId);
  }

  /**
   * 获取输出纹理ID
   */
  getTextureOutput(): number {
    return this.mTextureIdOutput;
  }

  /**
   * 解绑帧缓冲区
   */
  unbind(): void {
    // GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, this.originalFramebufferId[0]);
  }
}

