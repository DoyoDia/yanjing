/**
 * Created by hzqiujiadi on 16/7/11.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MD360Renderer } from './MD360Renderer';
import { Context, View } from '../../google/android/apps/muzei/render/ViewTypes';

// type View = any;
// type Context = any;

/**
 * GL屏幕包装抽象类
 */
export abstract class MDGLScreenWrapper {
  abstract getView(): View;
  abstract setRenderer(renderer: MD360Renderer): void;
  abstract init(context: Context): void;
  abstract onResume(): void;
  abstract onPause(): void;
  abstract setSurfaceId(surfaceId: string): void;
  abstract getSurfaceId(): string;
  abstract destroy(): void;
 
  static wrap(controller: XComponentController): MDGLScreenWrapper {
    return new MDXComponentImpl(controller);
  }
}

/**
 * XComponent实现
 */
class MDXComponentImpl extends MDGLScreenWrapper {
  private controller: XComponentController | null;
  private surfaceId: string = "";
  private renderer: MD360Renderer | null = null;

  constructor(controller: XComponentController) {
    super();
    this.controller = controller;
  }

  override getView(): View {
    return this.controller!;
  }

  override setRenderer(renderer: MD360Renderer): void {
    this.renderer = renderer;
  }

  override init(context: Context): void {
    // XComponent init is handled by the component itself
  }

  override onResume(): void {
    // 
  }

  override onPause(): void {
    // 
  }

  override setSurfaceId(surfaceId: string): void {
    this.surfaceId = surfaceId;
  }

  override getSurfaceId(): string {
    return this.surfaceId;
  }

  override destroy(): void {
    this.renderer = null;
    this.controller = null;
    this.surfaceId = "";
  }
}


