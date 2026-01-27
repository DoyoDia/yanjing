/**
 * Created by hzqiujiadi on 16/7/22.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDAbsPlugin } from './MDAbsPlugin';
import { MDMainPluginBuilder } from '../model/MDMainPluginBuilder';
import { MDPosition } from '../model/MDPosition';
import { GLUtil } from '../common/GLUtil';
import { MD360Program } from '../MD360Program';
import { MD360Texture } from '../texture/MD360Texture';
import { MD360Director } from '../MD360Director';
import { ProjectionModeManager } from '../strategy/projection/ProjectionModeManager';
import { MDDirectorCamUpdate } from '../MDDirectorCamUpdate';
import { MDDirectorFilter } from '../MDDirectorFilter';
import { MDAbsObject3D } from '../objects/MDAbsObject3D';
import { Context } from '../../../google/android/apps/muzei/render/ViewTypes';

export class MDPanoramaPlugin extends MDAbsPlugin {
  private mProgram: MD360Program | null = null;
  private mTexture: MD360Texture | null = null;
  private mProjectionModeManager: ProjectionModeManager | null = null;
  private mDirectorCameraUpdate: MDDirectorCamUpdate | null = null;
  private mDirectorFilter: MDDirectorFilter | null = null;

  constructor(builder: MDMainPluginBuilder) {
    super();
    this.mTexture = builder.getTexture();
    // 使用真实的 MD360Program，但其内部 OpenGL 调用目前是占位实现，不会触发 GLES 调用。
    this.mProgram = new MD360Program(builder.getContentType());
    this.mProjectionModeManager = builder.getProjectionModeManager();
    this.mDirectorCameraUpdate = builder.getCameraUpdate();
    this.mDirectorFilter = builder.getFilter();
  }

  protected initInGL(context: Context): void {
    // 如果后续接入 HarmonyOS OpenGL，可在此处真正构建着色器和纹理。
    // this.mProgram?.build(context);
    // this.mTexture?.create();
  }

  beforeRenderer(totalWidth: number, totalHeight: number): void {
    const directors = this.mProjectionModeManager?.getDirectors();
    if (directors != null) {
      // 应用更新
      for (const director of directors) {
        if (this.mDirectorCameraUpdate?.isChanged()) {
          director.applyUpdate(this.mDirectorCameraUpdate);
        }
        director.applyFilter(this.mDirectorFilter);
      }
      this.mDirectorCameraUpdate?.consumeChanged();
    }
  }

  renderer(index: number, width: number, height: number, director: MD360Director): void {
    const object3D = this.mProjectionModeManager?.getObject3D();
    // 检查obj3d
    if (object3D == null) return;

    // 更新投影
    director.setViewport(width, height);

    // 使用着色器程序（当前 GLSL 逻辑在鸿蒙上暂未启用）
    // mProgram.use();
    GLUtil.glCheck("MDPanoramaPlugin mProgram use");
    if (this.mTexture != null) {
      // mTexture.texture(mProgram);
    }

    // object3D.uploadVerticesBufferIfNeed(mProgram, index);
    // object3D.uploadTexCoordinateBufferIfNeed(mProgram, index);

    // 传入组合矩阵：这里虽然暂未真正绘制，但仍需更新导演中的 MVP 矩阵，
    // 供 NAPI 层的 libmd360player.so 使用（updateMVPMatrix）。
    director.beforeShot();
    if (this.mProgram != null) {
      director.shot(this.mProgram, this.getModelPosition());
      // 添加调试日志：确认 shot() 后 MVP 矩阵已更新
      const mvpMatrix = director.getMVPMatrix();
      if (mvpMatrix && mvpMatrix.length >= 16) {
      }
    }
    // object3D.draw();
  }

  destroyInGL(): void {
    this.mTexture = null;
  }

  protected getModelPosition(): MDPosition {
    return this.mProjectionModeManager?.getModelPosition() || MDPosition.getOriginalPosition();
  }

  removable(): boolean {
    return false;
  }
}

