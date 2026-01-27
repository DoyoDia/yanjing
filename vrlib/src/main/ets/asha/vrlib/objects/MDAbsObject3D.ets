/**
 * Created by hzqiujiadi on 16/1/22.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MD360Program } from '../MD360Program';
import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';

/**
 * FloatBuffer 类型定义
 * 在鸿蒙中可以使用 ArrayBuffer 或 Float32Array
 */
export type FloatBuffer = Float32Array;
export type ShortBuffer = Uint16Array;

/**
 * 3D对象抽象基类
 */
export abstract class MDAbsObject3D {
  private static readonly sPositionDataSize: number = 3;
  private static readonly sTextureCoordinateDataSize: number = 2;

  private mIndicesBuffer: ShortBuffer | null = null;
  private mNumIndices: number = 0;

  private mTexCoordinateBuffers: Map<number, FloatBuffer> = new Map();
  private mVerticesBuffers: Map<number, FloatBuffer> = new Map();

  constructor() {
  }

  /**
   * 上传顶点缓冲区到OpenGL（如果需要）
   * @param program 着色器程序
   * @param index 缓冲区索引
   */
  uploadVerticesBufferIfNeed(program: MD360Program, index: number): void {
    const vertexBuffer = this.getVerticesBuffer(index);
    if (vertexBuffer == null) return;

    // 在鸿蒙中，需要使用对应的OpenGL API
    // 这里保留接口，具体实现需要在OpenGL封装中完成
    const positionHandle = program.getPositionHandle();
    // GLES20.glVertexAttribPointer(positionHandle, MDAbsObject3D.sPositionDataSize, GLES20.GL_FLOAT, false, 0, vertexBuffer);
    // GLES20.glEnableVertexAttribArray(positionHandle);
  }

  /**
   * 上传纹理坐标缓冲区到OpenGL（如果需要）
   * @param program 着色器程序
   * @param index 缓冲区索引
   */
  uploadTexCoordinateBufferIfNeed(program: MD360Program, index: number): void {
    const textureBuffer = this.getTexCoordinateBuffer(index);
    if (textureBuffer == null) return;

    // 在鸿蒙中，需要使用对应的OpenGL API
    // 这里保留接口，具体实现需要在OpenGL封装中完成
    const textureCoordinateHandle = program.getTextureCoordinateHandle();
    // GLES20.glVertexAttribPointer(textureCoordinateHandle, MDAbsObject3D.sTextureCoordinateDataSize, GLES20.GL_FLOAT, false, 0, textureBuffer);
    // GLES20.glEnableVertexAttribArray(textureCoordinateHandle);
  }

  /**
   * 执行加载操作（子类实现）
   * @param context 上下文
   */
  abstract executeLoad(context: Context): void;

  getNumIndices(): number {
    return this.mNumIndices;
  }

  setNumIndices(mNumIndices: number): void {
    this.mNumIndices = mNumIndices;
  }

  getVerticesBuffer(index: number): FloatBuffer | null {
    return this.mVerticesBuffers.get(index) || null;
  }

  setVerticesBuffer(index: number, verticesBuffer: FloatBuffer): void {
    this.mVerticesBuffers.set(index, verticesBuffer);
  }

  getTexCoordinateBuffer(index: number): FloatBuffer | null {
    return this.mTexCoordinateBuffers.get(index) || null;
  }

  setTexCoordinateBuffer(index: number, texCoordinateBuffer: FloatBuffer): void {
    this.mTexCoordinateBuffers.set(index, texCoordinateBuffer);
  }

  getIndicesBuffer(): ShortBuffer | null {
    return this.mIndicesBuffer;
  }

  setIndicesBuffer(mIndicesBuffer: ShortBuffer | null): void {
    this.mIndicesBuffer = mIndicesBuffer;
  }

  /**
   * 绘制对象
   */
  draw(): void {
    // 在鸿蒙中，需要使用对应的OpenGL API
    // 这里保留接口，具体实现需要在OpenGL封装中完成
    if (this.getIndicesBuffer() != null) {
      // GLES20.glDrawElements(GLES20.GL_TRIANGLES, this.getNumIndices(), GLES20.GL_UNSIGNED_SHORT, this.getIndicesBuffer());
    } else {
      // GLES20.glDrawArrays(GLES20.GL_TRIANGLES, 0, this.getNumIndices());
    }
  }
}

