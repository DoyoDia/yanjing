/**
 * Created by hzqiujiadi on 16/8/20.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MD360Texture } from '../texture/MD360Texture';
import { ProjectionModeManager } from '../strategy/projection/ProjectionModeManager';
import { MDDirectorCamUpdate } from '../MDDirectorCamUpdate';
import { MDDirectorFilter } from '../MDDirectorFilter';

/**
 * 主插件构建器类
 */
export class MDMainPluginBuilder {
  private texture: MD360Texture | null = null;
  private contentType: number = 0; // MDVRLibrary.ContentType.DEFAULT
  private projectionModeManager: ProjectionModeManager | null = null;
  private cameraUpdate: MDDirectorCamUpdate | null = null;
  private filter: MDDirectorFilter | null = null;

  constructor() {
  }

  getTexture(): MD360Texture | null {
    return this.texture;
  }

  getContentType(): number {
    return this.contentType;
  }

  getProjectionModeManager(): ProjectionModeManager | null {
    return this.projectionModeManager;
  }

  setContentType(contentType: number): MDMainPluginBuilder {
    this.contentType = contentType;
    return this;
  }

  getCameraUpdate(): MDDirectorCamUpdate | null {
    return this.cameraUpdate;
  }

  getFilter(): MDDirectorFilter | null {
    return this.filter;
  }

  /**
   * 设置纹理
   * @param texture 纹理对象
   * @returns 构建器自身
   */
  setTexture(texture: MD360Texture): MDMainPluginBuilder {
    this.texture = texture;
    return this;
  }

  setProjectionModeManager(projectionModeManager: ProjectionModeManager): MDMainPluginBuilder {
    this.projectionModeManager = projectionModeManager;
    return this;
  }

  setCameraUpdate(cameraUpdate: MDDirectorCamUpdate): MDMainPluginBuilder {
    this.cameraUpdate = cameraUpdate;
    return this;
  }

  setFilter(filter: MDDirectorFilter): MDMainPluginBuilder {
    this.filter = filter;
    return this;
  }
}

