/**
 * Created by hzqiujiadi on 2017/4/12.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsHotspot } from './MDAbsHotspot';
import { MDViewBuilder } from '../../model/MDViewBuilder';
import { MDHitEvent } from '../../model/MDHitEvent';
import { VRUtil } from '../../common/VRUtil';
import { Context, View } from '../../../../google/android/apps/muzei/render/ViewTypes';

import { MD360Texture } from '../../texture/MD360Texture';
import { MD360BitmapTexture } from '../../texture/MD360BitmapTexture';
import { Bitmap, MDLayoutParams } from '../../model/MDTypes';
import { MDVRLibrary, IBitmapProvider } from '../../MDVRLibrary';
import { MD360Director } from '../../MD360Director';

// type View = any;
// type MD360Texture = any;
// type MD360BitmapTexture = any;
// type IBitmapProvider = any;
// type Context = any;
// type MD360Director = any;
// type Bitmap = any;
type Canvas = Object;

enum TouchStatus {
  NOP,
  DOWN
}

/**
 * 抽象视图类
 */
export abstract class MDAbsView extends MDAbsHotspot {
  private mInvalidate: boolean = false;
  private mTexture: MD360Texture | null = null;
  private mAttachedView: View | null = null;
  private mLayoutParams: MDLayoutParams | null = null;
  private mCanvas: Canvas | null = null;
  private mBitmap: Bitmap | null = null;
  private mTouchStatus: TouchStatus = TouchStatus.NOP;

  constructor(builder: MDViewBuilder) {
    super(builder.builderDelegate);
    this.mAttachedView = builder.attachedView;
    this.mLayoutParams = builder.layoutParams;
    // this.mAttachedView.setLayoutParams(this.mLayoutParams);

    try {
      // this.mBitmap = Bitmap.createBitmap(mLayoutParams.width, mLayoutParams.height, Bitmap.Config.ARGB_8888);
      // this.mCanvas = new Canvas(mBitmap);
    } catch (e) {
      console.error(e);
    }

    this.requestLayout();
  }

  /**
   * 使视图无效，触发重绘
   */
  invalidate(): void {
    if (this.mBitmap == null) {
      return;
    }

    VRUtil.checkMainThread("invalidate must called in main thread.");
    VRUtil.notNull(this.mLayoutParams, "layout params can't be null");
    VRUtil.notNull(this.mAttachedView, "attached view can't be null");

    // mCanvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
    // mAttachedView.draw(mCanvas);
    this.mInvalidate = true;
  }

  /**
   * 请求布局
   */
  requestLayout(): void {
    if (this.mBitmap == null) {
      return;
    }

    VRUtil.checkMainThread("requestLayout must called in main thread.");
    VRUtil.notNull(this.mLayoutParams, "layout params can't be null");
    VRUtil.notNull(this.mAttachedView, "attached view can't be null");

    // mAttachedView.measure(...);
    // mAttachedView.layout(0, 0, ...);

    this.invalidate();
  }

  protected initInGL(context: Context): void {
    super.initInGL(context);

    // mTexture = new MD360BitmapTexture(new MDVRLibrary.IBitmapProvider() {
    //   onProvideBitmap(callback: MD360BitmapTexture.Callback) {
    //     if (mBitmap != null) {
    //       callback.texture(mBitmap);
    //     }
    //   }
    // });
    // mTexture.create();
  }

  override renderer(index: number, width: number, height: number, director: MD360Director): void {
    if (this.mTexture == null || this.mBitmap == null) {
      return;
    }

    if (this.mInvalidate) {
      this.mInvalidate = false;
      // mTexture.notifyChanged();
    }

    // mTexture.texture(this.program);

    // if (mTexture.isReady()) {
    //   super.renderer(index, width, height, director);
    // }
  }

  override onEyeHitIn(hitEvent: MDHitEvent): void {
    super.onEyeHitIn(hitEvent);

    const point = hitEvent.getHitPoint();
    if (point == null || this.mAttachedView == null) {
      return;
    }

    // 在鸿蒙中，需要使用对应的事件系统
    // 这里保留接口，具体实现需要根据鸿蒙的事件系统完成

    // const action = this.mTouchStatus == TouchStatus.NOP ? MotionEvent.ACTION_HOVER_ENTER : MotionEvent.ACTION_HOVER_MOVE;
    // const x = this.mAttachedView.getLeft() + this.mAttachedView.getWidth() * point.getU();
    // const y = this.mAttachedView.getTop() + this.mAttachedView.getHeight() * point.getV();
    // ...

    this.mTouchStatus = TouchStatus.DOWN;
    this.invalidate();
  }

  override onEyeHitOut(timestamp: number): void {
    super.onEyeHitOut(timestamp);
    if (this.mTouchStatus == TouchStatus.DOWN) {
      // 在鸿蒙中，需要使用对应的事件系统
      // ...
    }
    this.mTouchStatus = TouchStatus.NOP;
    this.invalidate();
  }

  /**
   * 转换附加视图类型
   */
  castAttachedView<T extends View>(clazz: ESObject): T | null {
    VRUtil.notNull(clazz, "param clz can't be null.");
    return this.mAttachedView as T;
  }

  getAttachedView(): View | null {
    return this.mAttachedView;
  }
}

