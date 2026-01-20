/**
 * ExternalDisplayManager - 外部显示器管理模块
 * 负责检测和管理智能眼镜等外部显示设备
 */

import { display } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

/**
 * 显示器类型
 */
export enum DisplayType {
  /** 内置显示器（手机屏幕） */
  BUILT_IN = 'built_in',
  /** 外部显示器（智能眼镜等） */
  EXTERNAL = 'external'
}

/**
 * 显示器信息
 */
export interface DisplayInfo {
  /** 显示器 ID */
  id: number;
  /** 显示器名称 */
  name: string;
  /** 显示器类型 */
  type: DisplayType;
  /** 宽度（像素） */
  width: number;
  /** 高度（像素） */
  height: number;
  /** 刷新率（Hz） */
  refreshRate: number;
  /** 密度 DPI */
  densityDPI: number;
  /** 是否为主显示器 */
  isPrimary: boolean;
}

/**
 * 外部显示器事件监听器
 */
export interface ExternalDisplayListener {
  /**
   * 当外部显示器连接时调用
   */
  onExternalDisplayConnected(displayInfo: DisplayInfo): void;

  /**
   * 当外部显示器断开时调用
   */
  onExternalDisplayDisconnected(displayId: number): void;

  /**
   * 当显示器参数变化时调用
   */
  onDisplayChanged(displayInfo: DisplayInfo): void;
}

/**
 * 外部显示器管理器
 */
export class ExternalDisplayManager {
  private static instance: ExternalDisplayManager | null = null;

  // 监听器列表
  private listeners: ExternalDisplayListener[] = [];

  // 所有显示器列表
  private displays: Map<number, DisplayInfo> = new Map();

  // 外部显示器列表
  private externalDisplays: Map<number, DisplayInfo> = new Map();

  // 外部窗口
  private externalWindow: window.Window | null = null;

  // 上下文
  private context: common.UIAbilityContext | null = null;

  // 是否正在监听
  private isListening: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): ExternalDisplayManager {
    if (!ExternalDisplayManager.instance) {
      ExternalDisplayManager.instance = new ExternalDisplayManager();
    }
    return ExternalDisplayManager.instance;
  }

  /**
   * 设置上下文
   */
  public setContext(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * 初始化并开始监听显示器变化
   */
  public async initialize(): Promise<void> {
    try {
      // 获取当前所有显示器
      await this.refreshDisplayList();

      // 注册显示器变化监听
      this.startListening();

      console.info('ExternalDisplayManager: Initialized');
    } catch (error) {
      console.error('ExternalDisplayManager: Failed to initialize', JSON.stringify(error));
    }
  }

  /**
   * 刷新显示器列表
   */
  public async refreshDisplayList(): Promise<void> {
    try {
      const allDisplays: display.Display[] = await display.getAllDisplays();
      this.displays.clear();
      this.externalDisplays.clear();

      for (let i = 0; i < allDisplays.length; i++) {
        const d = allDisplays[i];
        const info = this.convertToDisplayInfo(d);
        this.displays.set(info.id, info);

        if (info.type === DisplayType.EXTERNAL) {
          this.externalDisplays.set(info.id, info);
        }
      }

      console.info(`ExternalDisplayManager: Found ${this.displays.size} displays, ${this.externalDisplays.size} external`);
    } catch (error) {
      console.error('ExternalDisplayManager: Failed to refresh display list', JSON.stringify(error));
    }
  }

  /**
   * 将系统 Display 对象转换为 DisplayInfo
   */
  private convertToDisplayInfo(d: display.Display): DisplayInfo {
    // 判断是否为外部显示器
    // 通常 ID 为 0 的是主屏，其他的可能是外部显示器
    // 也可以通过其他属性判断，如 name 中是否包含 "external" 等
    const isExternal = d.id !== 0;

    return {
      id: d.id,
      name: d.name || `Display ${d.id}`,
      type: isExternal ? DisplayType.EXTERNAL : DisplayType.BUILT_IN,
      width: d.width,
      height: d.height,
      refreshRate: d.refreshRate || 60,
      densityDPI: d.densityDPI || 320,
      isPrimary: d.id === 0
    };
  }

  /**
   * 开始监听显示器变化
   */
  private startListening(): void {
    if (this.isListening) return;

    try {
      // 监听显示器添加
      display.on('add', (displayId: number) => {
        console.info(`ExternalDisplayManager: Display added - ID: ${displayId}`);
        this.onDisplayAdded(displayId);
      });

      // 监听显示器移除
      display.on('remove', (displayId: number) => {
        console.info(`ExternalDisplayManager: Display removed - ID: ${displayId}`);
        this.onDisplayRemoved(displayId);
      });

      // 监听显示器变化
      display.on('change', (displayId: number) => {
        console.info(`ExternalDisplayManager: Display changed - ID: ${displayId}`);
        this.onDisplayChanged(displayId);
      });

      this.isListening = true;
      console.info('ExternalDisplayManager: Started listening for display changes');
    } catch (error) {
      console.error('ExternalDisplayManager: Failed to start listening', JSON.stringify(error));
    }
  }

  /**
   * 停止监听显示器变化
   */
  public stopListening(): void {
    if (!this.isListening) return;

    try {
      display.off('add');
      display.off('remove');
      display.off('change');

      this.isListening = false;
      console.info('ExternalDisplayManager: Stopped listening');
    } catch (error) {
      console.error('ExternalDisplayManager: Failed to stop listening', JSON.stringify(error));
    }
  }

  /**
   * 处理显示器添加事件
   */
  private async onDisplayAdded(displayId: number): Promise<void> {
    try {
      const d = display.getDisplayByIdSync(displayId);
      if (d) {
        const info = this.convertToDisplayInfo(d);
        this.displays.set(info.id, info);

        if (info.type === DisplayType.EXTERNAL) {
          this.externalDisplays.set(info.id, info);
          this.notifyExternalDisplayConnected(info);
        }
      }
    } catch (error) {
      console.error('ExternalDisplayManager: Failed to handle display added', JSON.stringify(error));
    }
  }

  /**
   * 处理显示器移除事件
   */
  private onDisplayRemoved(displayId: number): void {
    const info = this.displays.get(displayId);
    this.displays.delete(displayId);

    if (this.externalDisplays.has(displayId)) {
      this.externalDisplays.delete(displayId);
      this.notifyExternalDisplayDisconnected(displayId);
    }
  }

  /**
   * 处理显示器变化事件
   */
  private async onDisplayChanged(displayId: number): Promise<void> {
    try {
      const d = display.getDisplayByIdSync(displayId);
      if (d) {
        const info = this.convertToDisplayInfo(d);
        this.displays.set(info.id, info);

        if (info.type === DisplayType.EXTERNAL) {
          this.externalDisplays.set(info.id, info);
        }

        this.notifyDisplayChanged(info);
      }
    } catch (error) {
      console.error('ExternalDisplayManager: Failed to handle display changed', JSON.stringify(error));
    }
  }

  /**
   * 在外部显示器上创建窗口
   * @param displayId 目标显示器 ID
   * @param pageName 要显示的页面名称
   */
  public async createWindowOnExternalDisplay(displayId: number, pageName: string): Promise<window.Window | null> {
    if (!this.context) {
      console.error('ExternalDisplayManager: Context not set');
      return null;
    }

    const displayInfo = this.externalDisplays.get(displayId);
    if (!displayInfo) {
      console.error(`ExternalDisplayManager: External display ${displayId} not found`);
      return null;
    }

    try {
      // 创建窗口配置
      const config: window.Configuration = {
        name: `external_window_${displayId}`,
        windowType: window.WindowType.TYPE_FLOAT,
        displayId: displayId,
        ctx: this.context
      };

      // 创建窗口
      this.externalWindow = await window.createWindow(config);

      // 设置窗口大小为全屏
      await this.externalWindow.resize(displayInfo.width, displayInfo.height);
      await this.externalWindow.moveWindowTo(0, 0);

      // 加载页面内容
      await this.externalWindow.setUIContent(pageName);

      // 显示窗口
      await this.externalWindow.showWindow();

      console.info(`ExternalDisplayManager: Window created on display ${displayId}`);
      return this.externalWindow;
    } catch (error) {
      console.error('ExternalDisplayManager: Failed to create window on external display', JSON.stringify(error));
      return null;
    }
  }

  /**
   * 关闭外部显示器窗口
   */
  public async closeExternalWindow(): Promise<void> {
    if (!this.externalWindow) return;

    try {
      await this.externalWindow.destroyWindow();
      this.externalWindow = null;
      console.info('ExternalDisplayManager: External window closed');
    } catch (error) {
      console.error('ExternalDisplayManager: Failed to close external window', JSON.stringify(error));
    }
  }

  /**
   * 获取外部窗口实例
   */
  public getExternalWindow(): window.Window | null {
    return this.externalWindow;
  }

  /**
   * 添加监听器
   */
  public addListener(listener: ExternalDisplayListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  /**
   * 移除监听器
   */
  public removeListener(listener: ExternalDisplayListener): void {
    const index = this.listeners.indexOf(listener);
    if (index !== -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 获取所有显示器列表
   */
  public getAllDisplays(): DisplayInfo[] {
    return Array.from(this.displays.values());
  }

  /**
   * 获取外部显示器列表
   */
  public getExternalDisplays(): DisplayInfo[] {
    return Array.from(this.externalDisplays.values());
  }

  /**
   * 检查是否有外部显示器连接
   */
  public hasExternalDisplay(): boolean {
    return this.externalDisplays.size > 0;
  }

  /**
   * 获取第一个外部显示器
   */
  public getFirstExternalDisplay(): DisplayInfo | null {
    const displays = this.getExternalDisplays();
    return displays.length > 0 ? displays[0] : null;
  }

  /**
   * 获取主显示器
   */
  public getPrimaryDisplay(): DisplayInfo | null {
    for (const info of this.displays.values()) {
      if (info.isPrimary) {
        return info;
      }
    }
    return null;
  }

  /**
   * 通知外部显示器连接
   */
  private notifyExternalDisplayConnected(displayInfo: DisplayInfo): void {
    for (const listener of this.listeners) {
      listener.onExternalDisplayConnected(displayInfo);
    }
  }

  /**
   * 通知外部显示器断开
   */
  private notifyExternalDisplayDisconnected(displayId: number): void {
    for (const listener of this.listeners) {
      listener.onExternalDisplayDisconnected(displayId);
    }
  }

  /**
   * 通知显示器变化
   */
  private notifyDisplayChanged(displayInfo: DisplayInfo): void {
    for (const listener of this.listeners) {
      listener.onDisplayChanged(displayInfo);
    }
  }
}

/**
 * 便捷获取实例函数
 */
export function getExternalDisplayManager(): ExternalDisplayManager {
  return ExternalDisplayManager.getInstance();
}
