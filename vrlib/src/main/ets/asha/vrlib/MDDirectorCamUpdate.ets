/**
 * Created by hzqiujiadi on 2017/5/10.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDDirectorCamera } from './MDDirectorCamera';

/**
 * 导演相机更新类
 */
export class MDDirectorCamUpdate {
  private delegate: MDDirectorCamera = new MDDirectorCamera();

  constructor() {
    this.clear();
  }

  setLookX(mLookX: number): MDDirectorCamUpdate {
    this.delegate.setLookX(mLookX);
    return this;
  }

  setLookY(mLookY: number): MDDirectorCamUpdate {
    this.delegate.setLookY(mLookY);
    return this;
  }

  setEyeX(mEyeX: number): MDDirectorCamUpdate {
    this.delegate.setEyeX(mEyeX);
    return this;
  }

  setEyeY(mEyeY: number): MDDirectorCamUpdate {
    this.delegate.setEyeY(mEyeY);
    return this;
  }

  setEyeZ(mEyeZ: number): MDDirectorCamUpdate {
    this.delegate.setEyeZ(mEyeZ);
    return this;
  }

  getEyeX(): number {
    return this.delegate.getEyeX();
  }

  getEyeY(): number {
    return this.delegate.getEyeY();
  }

  getEyeZ(): number {
    return this.delegate.getEyeZ();
  }

  getLookX(): number {
    return this.delegate.getLookX();
  }

  getLookY(): number {
    return this.delegate.getLookY();
  }

  getNearScale(): number {
    return this.delegate.getNearScale();
  }

  setNearScale(scale: number): MDDirectorCamUpdate {
    this.delegate.setNearScale(scale);
    return this;
  }

  setRoll(roll: number): MDDirectorCamUpdate {
    this.delegate.setRoll(roll);
    return this;
  }

  setPitch(pitch: number): MDDirectorCamUpdate {
    this.delegate.setPitch(pitch);
    return this;
  }

  setYaw(yaw: number): MDDirectorCamUpdate {
    this.delegate.setYaw(yaw);
    return this;
  }

  getPitch(): number {
    return this.delegate.getPitch();
  }

  getYaw(): number {
    return this.delegate.getYaw();
  }

  getRoll(): number {
    return this.delegate.getRoll();
  }

  isRotationValidate(): boolean {
    return this.delegate.isRotationValidate();
  }

  isPositionValidate(): boolean {
    return this.delegate.isPositionValidate();
  }

  isProjectionValidate(): boolean {
    return this.delegate.isProjectionValidate();
  }

  consumePositionValidate(): void {
    this.delegate.consumePositionValidate();
  }

  consumeProjectionValidate(): void {
    this.delegate.consumeProjectionValidate();
  }

  consumeRotationValidate(): void {
    this.delegate.consumeRotationValidate();
  }

  clear(): void {
    this.setLookX(0);
    this.setLookY(0);
    this.setEyeX(0);
    this.setEyeY(0);
    this.setEyeZ(0);
    this.setNearScale(0);
    this.setPitch(0);
    this.setYaw(0);
    this.setRoll(0);
  }

  copy(cameraUpdate: MDDirectorCamUpdate): void {
    this.setLookX(cameraUpdate.getLookX());
    this.setLookY(cameraUpdate.getLookY());
    this.setEyeX(cameraUpdate.getEyeX());
    this.setEyeY(cameraUpdate.getEyeY());
    this.setEyeZ(cameraUpdate.getEyeZ());
    this.setNearScale(cameraUpdate.getNearScale());
    this.setPitch(cameraUpdate.getPitch());
    this.setYaw(cameraUpdate.getYaw());
    this.setRoll(cameraUpdate.getRoll());
  }

  isChanged(): boolean {
    return this.isPositionValidate() || this.isRotationValidate() || this.isProjectionValidate();
  }

  consumeChanged(): void {
    this.consumePositionValidate();
    this.consumeRotationValidate();
    this.consumeProjectionValidate();
  }
}

