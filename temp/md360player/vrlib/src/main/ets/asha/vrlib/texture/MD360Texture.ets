/**
 * Created by hzqiujiadi on 16/1/25.
 * hzqiujiadi ashqalcn@gmail.com
 *
 * copied from surfaceTexture
 * Created by nitro888 on 15. 4. 5..
 * https://github.com/Nitro888/NitroAction360
 */

import { MD360Program } from '../model/MDTypes';

/**
 * 抽象纹理类
 */
export abstract class MD360Texture {
  private static readonly TEXTURE_EMPTY: number = 0;
  private static readonly TAG: string = "MD360Texture";
  private mTextureId: number = MD360Texture.TEXTURE_EMPTY;

  constructor() {
  }

  /**
   * 可能从多线程调用
   */
  create(): void {
    const glTexture = this.createTextureId();

    if (glTexture !== MD360Texture.TEXTURE_EMPTY) {
      this.mTextureId = glTexture;
    }
  }

  /**
   * 是否准备就绪
   */
  abstract isReady(): boolean;

  /**
   * 销毁纹理
   */
  abstract destroy(): void;

  /**
   * 释放资源
   */
  abstract release(): void;

  /**
   * 获取当前纹理ID
   */
  getCurrentTextureId(): number {
    return this.mTextureId;
  }

  /**
   * 检查纹理ID是否为空
   */
  protected isEmpty(textureId: number): boolean {
    return textureId === MD360Texture.TEXTURE_EMPTY;
  }

  /**
   * 创建纹理ID（子类实现）
   */
  protected abstract createTextureId(): number;

  /**
   * 应用纹理到程序（子类实现）
   * @param program 着色器程序
   */
  abstract texture(program: MD360Program): boolean;

  /**
   * 通知纹理已改变
   */
  abstract notifyChanged(): void;
}

