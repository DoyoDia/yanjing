/**
 * Created by hzqiujiadi on 16/3/19.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { ModeManager } from '../ModeManager';
import { AbsDisplayStrategy } from './AbsDisplayStrategy';
import { IDisplayMode } from './IDisplayMode';
import { MDGLHandler } from '../../common/MDGLHandler';
import { BarrelDistortionConfig } from '../../model/BarrelDistortionConfig';
import { NormalStrategy } from './NormalStrategy';
import { GlassStrategy } from './GlassStrategy';

/**
 * 显示模式常量
 * 为避免与 MDVRLibrary 的循环依赖，这里本地维护一份常量。
 * 数值必须与 MDVRLibrary 中的 DISPLAY_MODE_* 保持一致。
 */
const DISPLAY_MODE_NORMAL = 101;
const DISPLAY_MODE_GLASS = 102;

/**
 * 显示模式管理器
 */
export class DisplayModeManager extends ModeManager<AbsDisplayStrategy> implements IDisplayMode {
  public static sModes: number[] = [DISPLAY_MODE_NORMAL, DISPLAY_MODE_GLASS];

  private antiDistortionEnabled: boolean = false;
  private barrelDistortionConfig: BarrelDistortionConfig | null = null;

  constructor(mode: number, handler: MDGLHandler) {
    super(mode, handler);
  }

  protected getModes(): number[] {
    return DisplayModeManager.sModes;
  }

  protected createStrategy(mode: number): AbsDisplayStrategy {
    switch (mode) {
      case DISPLAY_MODE_GLASS:
        return new GlassStrategy();
      case DISPLAY_MODE_NORMAL:
      default:
        return new NormalStrategy();
    }
  }

  getVisibleSize(): number {
    const strategy = this.getStrategy();
    const size = strategy?.getVisibleSize() || 1;
    // 添加调试日志（仅在模式切换时输出，避免日志过多）
    if (Math.random() < 0.01) { // 约1%的概率输出，减少日志量
      console.log('DisplayModeManager.getVisibleSize: strategy=', strategy?.constructor?.name, 'size=', size);
    }
    return size;
  }

  setAntiDistortionEnabled(antiDistortionEnabled: boolean): void {
    this.antiDistortionEnabled = antiDistortionEnabled;
  }

  isAntiDistortionEnabled(): boolean {
    return this.antiDistortionEnabled;
  }

  setBarrelDistortionConfig(barrelDistortionConfig: BarrelDistortionConfig | null): void {
    this.barrelDistortionConfig = barrelDistortionConfig;
  }

  getBarrelDistortionConfig(): BarrelDistortionConfig | null {
    return this.barrelDistortionConfig;
  }

  /**
   * 销毁方法，清理所有引用防止内存泄漏
   */
  override destroy(): void {
    super.destroy();
    this.barrelDistortionConfig = null;
  }
}

