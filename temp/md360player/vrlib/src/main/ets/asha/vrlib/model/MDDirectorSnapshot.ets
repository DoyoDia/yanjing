/**
 * Created by hzqiujiadi on 2017/4/20.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MD360Director } from '../MD360Director';

// TODO: 当 MD360Director 迁移后，取消注释并删除类型占位符
// import { MD360Director } from '../MD360Director';

// type MD360Director = any;

/**
 * 导演快照类
 * 用于保存导演的视图矩阵、投影矩阵和视口信息
 */
export class MDDirectorSnapshot {
  private viewMatrix: number[] = new Array(16).fill(0);
  private projectionMatrix: number[] = new Array(16).fill(0);
  private viewportWidth: number = 0;
  private viewportHeight: number = 0;

  getViewMatrix(): number[] {
    return this.viewMatrix;
  }

  getProjectionMatrix(): number[] {
    return this.projectionMatrix;
  }

  getViewportWidth(): number {
    return this.viewportWidth;
  }

  getViewportHeight(): number {
    return this.viewportHeight;
  }

  /**
   * 从导演对象复制数据
   * @param director 导演对象
   */
  copy(director: MD360Director): void {
    this.viewportWidth = director.getViewportWidth();
    this.viewportHeight = director.getViewportHeight();

    const directorViewMatrix = director.getViewMatrix();
    const directorProjectionMatrix = director.getProjectionMatrix();

    for (let i = 0; i < 16; i++) {
      this.viewMatrix[i] = directorViewMatrix[i];
      this.projectionMatrix[i] = directorProjectionMatrix[i];
    }
  }
}

