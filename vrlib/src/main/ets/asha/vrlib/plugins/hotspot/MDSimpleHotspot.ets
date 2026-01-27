/**
 * Created by hzqiujiadi on 2017/4/12.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsHotspot } from './MDAbsHotspot';
import { MDHotspotBuilder } from '../../model/MDHotspotBuilder';

// TODO: 当相关类型迁移后，取消注释并删除类型占位符
// import { MD360Texture } from '../../texture/MD360Texture';
// import { MD360BitmapTexture } from '../../texture/MD360BitmapTexture';
// import { MDVRLibrary } from '../../MDVRLibrary';

type MD360Texture = Object;
type MD360BitmapTexture = Object;
type IImageLoadProvider = Object;
type IBitmapProvider = Object;
type Context = Object;
type MD360Director = Object;

/**
 * 简单热点类
 */
export class MDSimpleHotspot extends MDAbsHotspot {
  private static readonly TAG: string = "MDSimplePlugin";

  private uriList: Map<number, string> = new Map();
  private mPendingTextureKey: number = 0;
  private mCurrentTextureKey: number = 0;

  // plugin
  private provider: IImageLoadProvider | null = null;
  private texture: MD360Texture | null = null;

  constructor(builder: MDHotspotBuilder) {
    super(builder.builderDelegate);
    this.provider = builder.imageLoadProvider;
    this.uriList = builder.uriList;
  }

  protected initInGL(context: Context): void {

    // texture = new MD360BitmapTexture(new MDVRLibrary.IBitmapProvider() {
    //   onProvideBitmap(callback: MD360BitmapTexture.Callback) {
    //     const uri = this.uriList.get(this.mCurrentTextureKey);
    //     if (uri != null) {
    //       this.provider.onProvideBitmap(uri, callback);
    //     }
    //   }
    // });
    // texture.create();
  }

  override renderer(index: number, width: number, height: number, director: MD360Director): void {
    if (this.texture == null) {
      return;
    }

    if (this.mPendingTextureKey !== this.mCurrentTextureKey) {
      this.mCurrentTextureKey = this.mPendingTextureKey;
      // texture.notifyChanged();
    }

    // texture.texture(this.program);

    // if (texture.isReady()) {
    //   super.renderer(index, width, height, director);
    // }
  }

  /**
   * 使用指定键的纹理
   * @param key 纹理键
   */
  useTexture(key: number): void {
    this.mPendingTextureKey = key;
  }
}

