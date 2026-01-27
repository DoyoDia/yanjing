/**
 * Created by hzqiujiadi on 16/8/2.
 * hzqiujiadi ashqalcn@gmail.com
 *
 * @deprecated MDHotspotPlugin
 *
 * Please use {@link MDSimpleHotspot} instead.
 */

import { MDHotspotBuilder } from '../model/MDHotspotBuilder';
import { MDSimpleHotspot } from './hotspot/MDSimpleHotspot';

/**
 * 热点插件类（已废弃）
 * 请使用 MDSimpleHotspot 代替
 */
export class MDHotspotPlugin extends MDSimpleHotspot {
  constructor(builder: MDHotspotBuilder) {
    super(builder);
  }
}

