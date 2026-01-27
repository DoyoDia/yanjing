/**
 * Created by hzqiujiadi on 2017/5/10.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDMutablePosition } from './model/position/MDMutablePosition';

/**
 * 导演相机类
 */
export class MDDirectorCamera {
  private mPositionValidate: boolean = false;
  private mEyeX: number = 0.0;
  private mEyeY: number = 0.0;
  private mEyeZ: number = 0.0;
  private mLookX: number = 0.0;
  private mLookY: number = 0.0;

  private mProjectionValidate: boolean = false;
  private mNearScale: number = 1.0;
  private mRatio: number = 1.5;
  private mViewportWidth: number = 2;
  private mViewportHeight: number = 1;

  private mRotationValidate: boolean = false;
  private readonly mRotation: MDMutablePosition = MDMutablePosition.newInstance();

  setLookX(mLookX: number): MDDirectorCamera {
    this.mLookX = mLookX;
    this.mPositionValidate = true;
    return this;
  }

  setLookY(mLookY: number): MDDirectorCamera {
    this.mLookY = mLookY;
    this.mPositionValidate = true;
    return this;
  }

  setEyeX(mEyeX: number): MDDirectorCamera {
    this.mEyeX = mEyeX;
    this.mPositionValidate = true;
    return this;
  }

  setEyeY(mEyeY: number): MDDirectorCamera {
    this.mEyeY = mEyeY;
    this.mPositionValidate = true;
    return this;
  }

  setEyeZ(mEyeZ: number): MDDirectorCamera {
    this.mEyeZ = mEyeZ;
    this.mPositionValidate = true;
    return this;
  }

  getEyeX(): number {
    return this.mEyeX;
  }

  getEyeY(): number {
    return this.mEyeY;
  }

  getEyeZ(): number {
    return this.mEyeZ;
  }

  getLookX(): number {
    return this.mLookX;
  }

  getLookY(): number {
    return this.mLookY;
  }

  getNearScale(): number {
    return this.mNearScale;
  }

  setNearScale(scale: number): MDDirectorCamera {
    this.mNearScale = scale;
    this.mProjectionValidate = true;
    return this;
  }

  setRoll(roll: number): MDDirectorCamera {
    this.mRotation.setRoll(roll);
    this.mRotationValidate = true;
    return this;
  }

  setPitch(pitch: number): MDDirectorCamera {
    this.mRotation.setPitch(pitch);
    this.mRotationValidate = true;
    return this;
  }

  setYaw(yaw: number): MDDirectorCamera {
    this.mRotation.setYaw(yaw);
    this.mRotationValidate = true;
    return this;
  }

  getPitch(): number {
    return this.mRotation.getPitch();
  }

  getYaw(): number {
    return this.mRotation.getYaw();
  }

  getRoll(): number {
    return this.mRotation.getRoll();
  }

  updateViewport(width: number, height: number): MDDirectorCamera {
    this.mViewportWidth = width;
    this.mViewportHeight = height;
    this.mRatio = width * 1.0 / height;
    this.mProjectionValidate = true;
    return this;
  }

  getRatio(): number {
    return this.mRatio;
  }

  getViewportWidth(): number {
    return this.mViewportWidth;
  }

  getViewportHeight(): number {
    return this.mViewportHeight;
  }

  isRotationValidate(): boolean {
    return this.mRotationValidate;
  }

  isPositionValidate(): boolean {
    return this.mPositionValidate;
  }

  isProjectionValidate(): boolean {
    return this.mProjectionValidate;
  }

  consumePositionValidate(): void {
    this.mPositionValidate = false;
  }

  consumeProjectionValidate(): void {
    this.mProjectionValidate = false;
  }

  consumeRotationValidate(): void {
    this.mRotationValidate = false;
  }
}

