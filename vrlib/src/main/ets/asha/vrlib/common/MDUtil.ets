export class MDUtil {
  /**
   * Android 中是通过 Context + resId 组装出资源 Uri。
   * 在 HarmonyOS 中资源访问方式不同，这里仅保留一个占位实现，
   * 方便后续按实际业务改造。
   */
  static getDrawableUri(resource: string): string {
    // TODO: 根据实际需要返回鸿蒙资源路径，例如 'resource:///xxx'
    return resource;
  }
}


