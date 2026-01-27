/**
 * Created by hzqiujiadi on 16/8/5.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MDVector3D } from './MDVector3D';

/**
 * 射线类
 */
export class MDRay {
  private mOrig: MDVector3D;
  private mDir: MDVector3D;

  constructor(mOrig: MDVector3D, mDir: MDVector3D) {
    this.mOrig = mOrig;
    this.mDir = mDir;
  }

  getOrig(): MDVector3D {
    return this.mOrig;
  }

  setOrig(mOrig: MDVector3D): void {
    this.mOrig = mOrig;
  }

  getDir(): MDVector3D {
    return this.mDir;
  }

  setDir(mDir: MDVector3D): void {
    this.mDir = mDir;
  }

  toString(): string {
    return `MDRay{mDir=${this.mDir}, mOrig=${this.mOrig}}`;
  }
}

