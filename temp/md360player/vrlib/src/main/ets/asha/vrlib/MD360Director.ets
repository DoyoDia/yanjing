/**
 * Created by hzqiujiadi on 16/1/22.
 * hzqiujiadi ashqalcn@gmail.com
 *
 * response for model * view * projection
 */

import { VRUtil } from './common/VRUtil';
import { MatrixUtil } from './common/MatrixUtil';
import { MDPosition } from './model/MDPosition';
import { MDQuaternion } from './model/MDQuaternion';
import { MDMutablePosition } from './model/position/MDMutablePosition';
import { MDDirectorCamera } from './MDDirectorCamera';
import { MDDirectorCamUpdate } from './MDDirectorCamUpdate';
import { MDDirectorFilter } from './MDDirectorFilter';
import { MD360Program } from './MD360Program';

/**
 * 360度导演类
 * 负责模型 * 视图 * 投影矩阵的计算
 */
export class MD360Director {
  private static readonly TAG: string = "MD360Director";
  private static readonly sNear: number = 0.7;

  private mViewMatrix: number[] = new Array(16).fill(0);
  private mProjectionMatrix: number[] = new Array(16).fill(0);
  private mMVMatrix: number[] = new Array(16).fill(0);
  private mMVPMatrix: number[] = new Array(16).fill(0);
  private mWorldRotationMatrix: number[] = new Array(16).fill(0);
  private mWorldRotationInvertMatrix: number[] = new Array(16).fill(0);
  private mCurrentRotationPost: number[] = new Array(16).fill(0);
  private mSensorMatrix: number[] = new Array(16).fill(0);
  private mTempMatrix: number[] = new Array(16).fill(0);
  private mCameraMatrix: number[] = new Array(16).fill(0);

  private readonly mCamera: MDDirectorCamera;
  private readonly mCameraUpdate: MDDirectorCamUpdate = new MDDirectorCamUpdate();
  private readonly mCameraRotation: MDMutablePosition = MDMutablePosition.newInstance();
  private readonly mViewQuaternion: MDQuaternion = new MDQuaternion();
  private mDirectorFilter: MDDirectorFilter | null = null;

  private mDeltaX: number = 0;
  private mDeltaY: number = 0;
  private mWorldRotationMatrixInvalidate: boolean = true;

  public constructor(builder: Builder) {
    this.mCamera = builder.mCamera;
    this.initModel();
  }

  getDeltaY(): number {
    return this.mDeltaY;
  }

  setDeltaY(mDeltaY: number): void {
    this.mDeltaY = mDeltaY;
    this.mWorldRotationMatrixInvalidate = true;
  }

  getDeltaX(): number {
    return this.mDeltaX;
  }

  setDeltaX(mDeltaX: number): void {
    this.mDeltaX = mDeltaX;
    this.mWorldRotationMatrixInvalidate = true;
  }

  private initModel(): void {
    MatrixUtil.setIdentityM(this.mViewMatrix, 0);
    MatrixUtil.setIdentityM(this.mSensorMatrix, 0);
    this.mViewQuaternion.fromMatrix(this.mViewMatrix);
  }

  beforeShot(): void {
    this.updateProjectionIfNeed();
    this.updateViewMatrixIfNeed();
  }

  shot(program: MD360Program, modelPosition: MDPosition): void {
    // 将视图矩阵乘以模型矩阵，结果存储在MVP矩阵中（当前包含 model * view）
    MatrixUtil.multiplyMM(this.mMVMatrix, 0, this.mViewMatrix, 0, modelPosition.getMatrix(), 0);

    // 将模型视图矩阵乘以投影矩阵，结果存储在MVP矩阵中（现在包含 model * view * projection）
    MatrixUtil.multiplyMM(this.mMVPMatrix, 0, this.mMVMatrix, 0, this.mProjectionMatrix, 0);
    
    // 添加调试日志：确认 shot() 被调用，并输出 deltaX/deltaY 的值

    // 传入模型视图矩阵
    // GLES20.glUniformMatrix4fv(program.getMVMatrixHandle(), 1, false, this.mMVMatrix, 0);
    // 传入组合矩阵
    // GLES20.glUniformMatrix4fv(program.getMVPMatrixHandle(), 1, false, this.mMVPMatrix, 0);
    // 在鸿蒙中，需要使用对应的OpenGL API
  }

  protected updateViewMatrixIfNeed(): void {
    const camera = this.mCamera.isPositionValidate() || this.mCameraUpdate.isPositionValidate();
    const world = this.mWorldRotationMatrixInvalidate || this.mCamera.isRotationValidate() || this.mCameraUpdate.isRotationValidate();

    if (camera) {
      this.updateCameraMatrix();
      this.mCamera.consumePositionValidate();
      this.mCameraUpdate.consumePositionValidate();
    }

    if (world) {
      this.mCameraRotation.setPitch(this.mCamera.getPitch() + this.mCameraUpdate.getPitch());
      this.mCameraRotation.setRoll(this.mCamera.getRoll() + this.mCameraUpdate.getRoll());
      this.mCameraRotation.setYaw(this.mCamera.getYaw() + this.mCameraUpdate.getYaw());

      // mCamera changed will be consumed after updateWorldRotationMatrix
      this.updateWorldRotationMatrix();
      this.mWorldRotationMatrixInvalidate = false;
      this.mCamera.consumeRotationValidate();
      this.mCameraUpdate.consumeRotationValidate();
    }

    if (camera || world) {
      MatrixUtil.multiplyMM(this.mViewMatrix, 0, this.mCameraMatrix, 0, this.mWorldRotationMatrix, 0);
      this.filterViewMatrix();
    }
  }

  private filterViewMatrix(): void {
    if (this.mDirectorFilter == null) {
      return;
    }

    this.mViewQuaternion.fromMatrix(this.mViewMatrix);
    const pitch = this.mViewQuaternion.getPitch();
    const yaw = this.mViewQuaternion.getYaw();
    const roll = this.mViewQuaternion.getRoll();

    const filterPitch = this.mDirectorFilter.onFilterPitch(pitch);
    const filterYaw = this.mDirectorFilter.onFilterYaw(yaw);
    const filterRoll = this.mDirectorFilter.onFilterRoll(roll);

    if (pitch !== filterPitch || yaw !== filterYaw || roll !== filterRoll) {
      this.mViewQuaternion.setEulerAngles(filterPitch, filterYaw, filterRoll);
      this.mViewQuaternion.toMatrix(this.mViewMatrix);
    }
  }

  setViewport(width: number, height: number): void {
    // Projection Matrix
    this.mCamera.updateViewport(width, height);
  }

  setNearScale(scale: number): void {
    this.mCamera.setNearScale(scale);
  }

  private updateProjectionIfNeed(): void {
    if (this.mCamera.isProjectionValidate() || this.mCameraUpdate.isProjectionValidate()) {
      this.updateProjection();
      this.mCamera.consumeProjectionValidate();
      this.mCameraUpdate.consumeProjectionValidate();
    }
  }

  protected updateProjection(): void {
    const left = -this.mCamera.getRatio() / 2;
    const right = this.mCamera.getRatio() / 2;
    const bottom = -0.5;
    const top = 0.5;
    const far = 500;
    MatrixUtil.frustumM(this.getProjectionMatrix(), 0, left, right, bottom, top, this.getNear(), far);
  }

  protected getNear(): number {
    return (this.mCamera.getNearScale() + this.mCameraUpdate.getNearScale()) * MD360Director.sNear;
  }

  protected getRatio(): number {
    return this.mCamera.getRatio();
  }

  getProjectionMatrix(): number[] {
    return this.mProjectionMatrix;
  }

  getViewportWidth(): number {
    return this.mCamera.getViewportWidth();
  }

  getViewportHeight(): number {
    return this.mCamera.getViewportHeight();
  }

  getViewMatrix(): number[] {
    return this.mViewMatrix;
  }

  getViewQuaternion(): MDQuaternion {
    return this.mViewQuaternion;
  }

  getMVPMatrix(): number[] {
    return this.mMVPMatrix;
  }

  private updateCameraMatrix(): void {
    const eyeX = this.mCamera.getEyeX() + this.mCameraUpdate.getEyeX();
    const eyeY = this.mCamera.getEyeY() + this.mCameraUpdate.getEyeY();
    const eyeZ = this.mCamera.getEyeZ() + this.mCameraUpdate.getEyeZ();
    const lookX = this.mCamera.getLookX() + this.mCameraUpdate.getLookX();
    const lookY = this.mCamera.getLookY() + this.mCameraUpdate.getLookY();
    const lookZ = -1.0;
    const upX = 0.0;
    const upY = 1.0;
    const upZ = 0.0;
    MatrixUtil.setIdentityM(this.mCameraMatrix, 0);
    MatrixUtil.setLookAtM(this.mCameraMatrix, 0, eyeX, eyeY, eyeZ, lookX, lookY, lookZ, upX, upY, upZ);
  }

  private updateWorldRotationMatrix(): void {
    MatrixUtil.setIdentityM(this.mWorldRotationMatrix, 0);
    MatrixUtil.rotateM(this.mWorldRotationMatrix, 0, -this.mDeltaY, 1.0, 0.0, 0.0);
    MatrixUtil.setIdentityM(this.mCurrentRotationPost, 0);
    MatrixUtil.rotateM(this.mCurrentRotationPost, 0, -this.mDeltaX, 0.0, 1.0, 0.0);

    MatrixUtil.setIdentityM(this.mTempMatrix, 0);
    MatrixUtil.multiplyMM(this.mTempMatrix, 0, this.mCurrentRotationPost, 0, this.mCameraRotation.getMatrix(), 0);

    // 关键步骤：把传感器矩阵乘进来
    MatrixUtil.multiplyMM(this.mCurrentRotationPost, 0, this.mSensorMatrix, 0, this.mTempMatrix, 0);
    MatrixUtil.multiplyMM(this.mTempMatrix, 0, this.mWorldRotationMatrix, 0, this.mCurrentRotationPost, 0);
    
    // System.arraycopy(mTempMatrix, 0, mWorldRotationMatrix, 0, 16);
    for (let i = 0; i < 16; i++) {
      this.mWorldRotationMatrix[i] = this.mTempMatrix[i];
    }

    const success = VRUtil.invertM(this.mWorldRotationInvertMatrix, this.mWorldRotationMatrix);
    if (!success) {
      MatrixUtil.setIdentityM(this.mWorldRotationInvertMatrix, 0);
    }
  }

  /**
   * 在GL线程中调用
   */
  updateSensorMatrix(sensorMatrix: number[]): void {
    if (sensorMatrix == null
      || sensorMatrix.length !== 16
      || Number.isNaN(sensorMatrix[0])
      || Number.isNaN(sensorMatrix[1])) {
      return;
    }

    // System.arraycopy(sensorMatrix, 0, mSensorMatrix, 0, 16);
    for (let i = 0; i < 16; i++) {
      this.mSensorMatrix[i] = sensorMatrix[i];
    }
    this.mWorldRotationMatrixInvalidate = true;
  }

  /**
   * 在GL线程中调用
   */
  reset(): void {
    this.mDeltaX = this.mDeltaY = 0;
    MatrixUtil.setIdentityM(this.mSensorMatrix, 0);
    this.mWorldRotationMatrixInvalidate = true;
  }

  static builder(): Builder {
    return new Builder();
  }

  getWorldRotationInvert(): number[] {
    return this.mWorldRotationInvertMatrix;
  }

  applyUpdate(cameraUpdate: MDDirectorCamUpdate): void {
    this.mCameraUpdate.copy(cameraUpdate);
  }

  applyFilter(directorFilter: MDDirectorFilter | null): void {
    this.mDirectorFilter = directorFilter;
  }
}

/**
 * 构建器类
 */
export class Builder {
  public mCamera: MDDirectorCamera = new MDDirectorCamera();

  private camera(): MDDirectorCamera {
    return this.mCamera;
  }

  setLookX(mLookX: number): Builder {
    this.camera().setLookX(mLookX);
    return this;
  }

  setLookY(mLookY: number): Builder {
    this.camera().setLookY(mLookY);
    return this;
  }

  setEyeX(mEyeX: number): Builder {
    this.camera().setEyeX(mEyeX);
    return this;
  }

  setEyeY(mEyeY: number): Builder {
    this.camera().setEyeY(mEyeY);
    return this;
  }

  setEyeZ(mEyeZ: number): Builder {
    this.camera().setEyeZ(mEyeZ);
    return this;
  }

  setNearScale(scale: number): Builder {
    this.camera().setNearScale(scale);
    return this;
  }

  setRoll(roll: number): Builder {
    this.camera().setRoll(roll);
    return this;
  }

  setPitch(pitch: number): Builder {
    this.camera().setPitch(pitch);
    return this;
  }

  setYaw(yaw: number): Builder {
    this.camera().setYaw(yaw);
    return this;
  }

  build(): MD360Director {
    return new MD360Director(this);
  }
}

