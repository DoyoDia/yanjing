/**
 * Created by hzqiujiadi on 16/8/10.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDHotspotPlugin } from './MDHotspotPlugin';
import { MDHitEvent } from '../model/MDHitEvent';
import { MDHotspotBuilder } from '../model/MDHotspotBuilder';

/**
 * 小部件插件类
 */
export class MDWidgetPlugin extends MDHotspotPlugin {
  private static readonly STATUS_NORMAL: number = 0;
  private static readonly STATUS_FOCUSED: number = 1;
  // private static readonly STATUS_PRESSED: number = 2;

  private mChecked: boolean = false;
  private mStatusList: number[] | null = null;
  private mCheckedStatusList: number[] | null = null;
  private mCurrentStatus: number = MDWidgetPlugin.STATUS_NORMAL;

  constructor(builder: MDHotspotBuilder) {
    super(builder);
    this.mStatusList = builder.statusList;
    this.mCheckedStatusList = builder.checkedStatusList;
    if (this.mStatusList == null) {
      this.mStatusList = [0, 0, 0];
    }
  }

  setChecked(checked: boolean): void {
    this.mChecked = checked;
    this.updateStatus();
  }

  getChecked(): boolean {
    return this.mChecked;
  }

  override onEyeHitIn(hitEvent: MDHitEvent): void {
    super.onEyeHitIn(hitEvent);
    this.mCurrentStatus = MDWidgetPlugin.STATUS_FOCUSED;
    this.updateStatus();
  }

  override onEyeHitOut(timestamp: number): void {
    super.onEyeHitOut(timestamp);
    this.mCurrentStatus = MDWidgetPlugin.STATUS_NORMAL;
    this.updateStatus();
  }

  private updateStatus(): void {
    let statusList = this.mChecked ? this.mCheckedStatusList : this.mStatusList;
    if (statusList == null) {
      statusList = this.mStatusList;
    }

    if (statusList != null && this.mCurrentStatus < statusList.length) {
      // useTexture(statusList[this.mCurrentStatus]);
    }
  }
}

