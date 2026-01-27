/**
 * Created by hzqiujiadi on 2017/5/13.
 * hzqiujiadi ashqalcn@gmail.com
 */

// TODO: 当相关类型迁移后，取消注释并删除类型占位符
// import { MDVRLibrary } from './MDVRLibrary';

export interface IDirectorFilter {
  onFilterPitch(input: number): number;
  onFilterYaw(input: number): number;
  onFilterRoll(input: number): number;
}

/**
 * 导演过滤器类
 */
export class MDDirectorFilter implements IDirectorFilter {
  private delegate: IDirectorFilter | null = null;

  onFilterPitch(input: number): number {
    if (this.delegate != null) {
      return this.delegate.onFilterPitch(input);
    }
    return input;
  }

  onFilterYaw(input: number): number {
    if (this.delegate != null) {
      return this.delegate.onFilterYaw(input);
    }
    return input;
  }

  onFilterRoll(input: number): number {
    if (this.delegate != null) {
      return this.delegate.onFilterRoll(input);
    }
    return input;
  }

  setDelegate(delegate: IDirectorFilter | null): void {
    this.delegate = delegate;
  }
}

