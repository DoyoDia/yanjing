/**
 * 方向扩展卡尔曼滤波器类
 */
import { Matrix3x3d } from './Matrix3x3d';
import { So3Helper } from './So3Helper';
import { So3Util } from './So3Util';
import { Vector3d } from './Vector3d';

export class OrientationEKF {
  private static readonly NS2S: number = 1.0E-9;
  private static readonly MIN_ACCEL_NOISE_SIGMA: number = 0.75;
  private static readonly MAX_ACCEL_NOISE_SIGMA: number = 7.0;
  private rotationMatrix: number[] = new Array(16).fill(0);
  private so3SensorFromWorld: Matrix3x3d = new Matrix3x3d();
  private so3LastMotion: Matrix3x3d = new Matrix3x3d();
  private mP: Matrix3x3d = new Matrix3x3d();
  private mQ: Matrix3x3d = new Matrix3x3d();
  private mR: Matrix3x3d = new Matrix3x3d();
  private mRaccel: Matrix3x3d = new Matrix3x3d();
  private mS: Matrix3x3d = new Matrix3x3d();
  private mH: Matrix3x3d = new Matrix3x3d();
  private mK: Matrix3x3d = new Matrix3x3d();
  private mNu: Vector3d = new Vector3d();
  private mz: Vector3d = new Vector3d();
  private mh: Vector3d = new Vector3d();
  private mu: Vector3d = new Vector3d();
  private mx: Vector3d = new Vector3d();
  private down: Vector3d = new Vector3d();
  private north: Vector3d = new Vector3d();
  private sensorTimeStampGyro: number = 0;
  private readonly lastGyro: Vector3d = new Vector3d();
  private previousAccelNorm: number = 0.0;
  private movingAverageAccelNormChange: number = 0.0;
  private filteredGyroTimestep: number = 0;
  private timestepFilterInit: boolean = false;
  private numGyroTimestepSamples: number = 0;
  private gyroFilterValid: boolean = true;
  private getPredictedGLMatrixTempM1: Matrix3x3d = new Matrix3x3d();
  private getPredictedGLMatrixTempM2: Matrix3x3d = new Matrix3x3d();
  private getPredictedGLMatrixTempV1: Vector3d = new Vector3d();
  private setHeadingDegreesTempM1: Matrix3x3d = new Matrix3x3d();
  private processGyroTempM1: Matrix3x3d = new Matrix3x3d();
  private processGyroTempM2: Matrix3x3d = new Matrix3x3d();
  private processAccTempM1: Matrix3x3d = new Matrix3x3d();
  private processAccTempM2: Matrix3x3d = new Matrix3x3d();
  private processAccTempM3: Matrix3x3d = new Matrix3x3d();
  private processAccTempM4: Matrix3x3d = new Matrix3x3d();
  private processAccTempM5: Matrix3x3d = new Matrix3x3d();
  private processAccTempV1: Vector3d = new Vector3d();
  private processAccTempV2: Vector3d = new Vector3d();
  private processAccVDelta: Vector3d = new Vector3d();
  private processMagTempV1: Vector3d = new Vector3d();
  private processMagTempV2: Vector3d = new Vector3d();
  private processMagTempV3: Vector3d = new Vector3d();
  private processMagTempV4: Vector3d = new Vector3d();
  private processMagTempV5: Vector3d = new Vector3d();
  private processMagTempM1: Matrix3x3d = new Matrix3x3d();
  private processMagTempM2: Matrix3x3d = new Matrix3x3d();
  private processMagTempM4: Matrix3x3d = new Matrix3x3d();
  private processMagTempM5: Matrix3x3d = new Matrix3x3d();
  private processMagTempM6: Matrix3x3d = new Matrix3x3d();
  private updateCovariancesAfterMotionTempM1: Matrix3x3d = new Matrix3x3d();
  private updateCovariancesAfterMotionTempM2: Matrix3x3d = new Matrix3x3d();
  private accObservationFunctionForNumericalJacobianTempM: Matrix3x3d = new Matrix3x3d();
  private magObservationFunctionForNumericalJacobianTempM: Matrix3x3d = new Matrix3x3d();
  private alignedToGravity: boolean = false;
  private alignedToNorth: boolean = false;
  private so3Helper: So3Helper = new So3Helper();
  private readonly lock: object = new Object(); // 用于同步

  constructor() {
    this.reset();
  }

  reset(): void {
    // 在ETS中，可以使用锁或其他同步机制
    this.sensorTimeStampGyro = 0;
    this.so3SensorFromWorld.setIdentity();
    this.so3LastMotion.setIdentity();
    const initialSigmaP = 5.0;
    this.mP.setZero();
    this.mP.setSameDiagonal(25.0);
    const initialSigmaQ = 1.0;
    this.mQ.setZero();
    this.mQ.setSameDiagonal(1.0);
    const initialSigmaR = 0.25;
    this.mR.setZero();
    this.mR.setSameDiagonal(0.0625);
    this.mRaccel.setZero();
    this.mRaccel.setSameDiagonal(0.5625);
    this.mS.setZero();
    this.mH.setZero();
    this.mK.setZero();
    this.mNu.setZero();
    this.mz.setZero();
    this.mh.setZero();
    this.mu.setZero();
    this.mx.setZero();
    this.down.set(0.0, 0.0, 9.81);
    this.north.set(0.0, 1.0, 0.0);
    this.alignedToGravity = false;
    this.alignedToNorth = false;
  }

  isReady(): boolean {
    return this.alignedToGravity;
  }

  getHeadingDegrees(): number {
    const x = this.so3SensorFromWorld.get(2, 0);
    const y = this.so3SensorFromWorld.get(2, 1);
    const mag = Math.sqrt(x * x + y * y);
    if (mag < 0.1) {
      return 0.0;
    } else {
      let heading = -90.0 - Math.atan2(y, x) / 3.141592653589793 * 180.0;
      if (heading < 0.0) {
        heading += 360.0;
      }
      if (heading >= 360.0) {
        heading -= 360.0;
      }
      return heading;
    }
  }

  setHeadingDegrees(heading: number): void {
    // 在ETS中，可以使用锁或其他同步机制
    const currentHeading = this.getHeadingDegrees();
    const deltaHeading = heading - currentHeading;
    const s = Math.sin(deltaHeading / 180.0 * 3.141592653589793);
    const c = Math.cos(deltaHeading / 180.0 * 3.141592653589793);
    const deltaHeadingRotationVals: number[][] = [
      [c, -s, 0.0],
      [s, c, 0.0],
      [0.0, 0.0, 1.0]
    ];
    OrientationEKF.arrayAssign(deltaHeadingRotationVals, this.setHeadingDegreesTempM1);
    Matrix3x3d.mult(this.so3SensorFromWorld, this.setHeadingDegreesTempM1, this.so3SensorFromWorld);
  }

  getGLMatrix(): number[] {
    return this.glMatrixFromSo3(this.so3SensorFromWorld);
  }

  getPredictedGLMatrix(secondsAfterLastGyroEvent: number): number[] {
    const pmu = this.getPredictedGLMatrixTempV1;
    pmu.set(this.lastGyro);
    pmu.scale(-secondsAfterLastGyroEvent);
    const so3PredictedMotion = this.getPredictedGLMatrixTempM1;
    So3Util.sO3FromMu(pmu, so3PredictedMotion);
    const so3PredictedState = this.getPredictedGLMatrixTempM2;
    Matrix3x3d.mult(so3PredictedMotion, this.so3SensorFromWorld, so3PredictedState);
    return this.glMatrixFromSo3(so3PredictedState);
  }

  getRotationMatrix(): Matrix3x3d {
    return this.so3SensorFromWorld;
  }

  static arrayAssign(data: number[][], m: Matrix3x3d): void {
    // assert 3 == data.length;
    // assert 3 == data[0].length;
    // assert 3 == data[1].length;
    // assert 3 == data[2].length;
    m.set(
      data[0][0], data[0][1], data[0][2],
      data[1][0], data[1][1], data[1][2],
      data[2][0], data[2][1], data[2][2]
    );
  }

  isAlignedToGravity(): boolean {
    return this.alignedToGravity;
  }

  isAlignedToNorth(): boolean {
    return this.alignedToNorth;
  }

  processGyro(gyro: Vector3d, sensorTimeStamp: number): void {
    // 在ETS中，可以使用锁或其他同步机制
    const kTimeThreshold = 0.04;
    const kdTdefault = 0.01;
    if (this.sensorTimeStampGyro !== 0) {
      let dT = (sensorTimeStamp - this.sensorTimeStampGyro) * OrientationEKF.NS2S;
      if (dT > kTimeThreshold) {
        dT = this.gyroFilterValid ? this.filteredGyroTimestep : kdTdefault;
      } else {
        this.filterGyroTimestep(dT);
      }

      this.mu.set(gyro);
      this.mu.scale(-dT);
      So3Util.sO3FromMu(this.mu, this.so3LastMotion);
      this.processGyroTempM1.set(this.so3SensorFromWorld);
      Matrix3x3d.mult(this.so3LastMotion, this.so3SensorFromWorld, this.processGyroTempM1);
      this.so3SensorFromWorld.set(this.processGyroTempM1);
      this.updateCovariancesAfterMotion();
      this.processGyroTempM2.set(this.mQ);
      this.processGyroTempM2.scale(dT * dT);
      this.mP.plusEquals(this.processGyroTempM2);
    }

    this.sensorTimeStampGyro = sensorTimeStamp;
    this.lastGyro.set(gyro);
  }

  private updateAccelCovariance(currentAccelNorm: number): void {
    const currentAccelNormChange = Math.abs(currentAccelNorm - this.previousAccelNorm);
    this.previousAccelNorm = currentAccelNorm;
    const kSmoothingFactor = 0.5;
    this.movingAverageAccelNormChange = kSmoothingFactor * currentAccelNormChange + kSmoothingFactor * this.movingAverageAccelNormChange;
    const kMaxAccelNormChange = 0.15;
    const normChangeRatio = this.movingAverageAccelNormChange / kMaxAccelNormChange;
    const accelNoiseSigma = Math.min(OrientationEKF.MAX_ACCEL_NOISE_SIGMA, OrientationEKF.MIN_ACCEL_NOISE_SIGMA + normChangeRatio * 6.25);
    this.mRaccel.setSameDiagonal(accelNoiseSigma * accelNoiseSigma);
  }

  processAcc(acc: Vector3d, sensorTimeStamp: number): void {
    // 在ETS中，可以使用锁或其他同步机制
    this.mz.set(acc);
    this.updateAccelCovariance(this.mz.length());
    if (this.alignedToGravity) {
      this.accObservationFunctionForNumericalJacobian(this.so3SensorFromWorld, this.mNu);
      const eps = 1.0E-7;

      for (let dof = 0; dof < 3; dof++) {
        const delta = this.processAccVDelta;
        delta.setZero();
        delta.setComponent(dof, eps);
        So3Util.sO3FromMu(delta, this.processAccTempM1);
        Matrix3x3d.mult(this.processAccTempM1, this.so3SensorFromWorld, this.processAccTempM2);
        this.accObservationFunctionForNumericalJacobian(this.processAccTempM2, this.processAccTempV1);
        const withDelta = this.processAccTempV1;
        Vector3d.sub(this.mNu, withDelta, this.processAccTempV2);
        this.processAccTempV2.scale(1.0 / eps);
        this.mH.setColumn(dof, this.processAccTempV2);
      }

      this.mH.transpose(this.processAccTempM3);
      Matrix3x3d.mult(this.mP, this.processAccTempM3, this.processAccTempM4);
      Matrix3x3d.mult(this.mH, this.processAccTempM4, this.processAccTempM5);
      Matrix3x3d.add(this.processAccTempM5, this.mRaccel, this.mS);
      this.mS.invert(this.processAccTempM3);
      this.mH.transpose(this.processAccTempM4);
      Matrix3x3d.mult(this.processAccTempM4, this.processAccTempM3, this.processAccTempM5);
      Matrix3x3d.mult(this.mP, this.processAccTempM5, this.mK);
      Matrix3x3d.mult(this.mK, this.mNu, this.mx);
      Matrix3x3d.mult(this.mK, this.mH, this.processAccTempM3);
      this.processAccTempM4.setIdentity();
      this.processAccTempM4.minusEquals(this.processAccTempM3);
      Matrix3x3d.mult(this.processAccTempM4, this.mP, this.processAccTempM3);
      this.mP.set(this.processAccTempM3);
      So3Util.sO3FromMu(this.mx, this.so3LastMotion);
      Matrix3x3d.mult(this.so3LastMotion, this.so3SensorFromWorld, this.so3SensorFromWorld);
      this.updateCovariancesAfterMotion();
    } else {
      this.so3Helper.sO3FromTwoVec(this.down, this.mz, this.so3SensorFromWorld);
      this.alignedToGravity = true;
    }
  }

  processMag(mag: number[], sensorTimeStamp: number): void {
    // 在ETS中，可以使用锁或其他同步机制
    if (this.alignedToGravity) {
      this.mz.set(mag[0], mag[1], mag[2]);
      this.mz.normalize();
      const downInSensorFrame = new Vector3d();
      this.so3SensorFromWorld.getColumn(2, downInSensorFrame);
      Vector3d.cross(this.mz, downInSensorFrame, this.processMagTempV1);
      const perpToDownAndMag = this.processMagTempV1;
      perpToDownAndMag.normalize();
      Vector3d.cross(downInSensorFrame, perpToDownAndMag, this.processMagTempV2);
      const magHorizontal = this.processMagTempV2;
      magHorizontal.normalize();
      this.mz.set(magHorizontal);
      if (this.alignedToNorth) {
        this.magObservationFunctionForNumericalJacobian(this.so3SensorFromWorld, this.mNu);
        const eps = 1.0E-7;

        for (let dof = 0; dof < 3; dof++) {
          const delta = this.processMagTempV3;
          delta.setZero();
          delta.setComponent(dof, eps);
          So3Util.sO3FromMu(delta, this.processMagTempM1);
          Matrix3x3d.mult(this.processMagTempM1, this.so3SensorFromWorld, this.processMagTempM2);
          this.magObservationFunctionForNumericalJacobian(this.processMagTempM2, this.processMagTempV4);
          const withDelta = this.processMagTempV4;
          Vector3d.sub(this.mNu, withDelta, this.processMagTempV5);
          this.processMagTempV5.scale(1.0 / eps);
          this.mH.setColumn(dof, this.processMagTempV5);
        }

        this.mH.transpose(this.processMagTempM4);
        Matrix3x3d.mult(this.mP, this.processMagTempM4, this.processMagTempM5);
        Matrix3x3d.mult(this.mH, this.processMagTempM5, this.processMagTempM6);
        Matrix3x3d.add(this.processMagTempM6, this.mR, this.mS);
        this.mS.invert(this.processMagTempM4);
        this.mH.transpose(this.processMagTempM5);
        Matrix3x3d.mult(this.processMagTempM5, this.processMagTempM4, this.processMagTempM6);
        Matrix3x3d.mult(this.mP, this.processMagTempM6, this.mK);
        Matrix3x3d.mult(this.mK, this.mNu, this.mx);
        Matrix3x3d.mult(this.mK, this.mH, this.processMagTempM4);
        this.processMagTempM5.setIdentity();
        this.processMagTempM5.minusEquals(this.processMagTempM4);
        Matrix3x3d.mult(this.processMagTempM5, this.mP, this.processMagTempM4);
        this.mP.set(this.processMagTempM4);
        So3Util.sO3FromMu(this.mx, this.so3LastMotion);
        Matrix3x3d.mult(this.so3LastMotion, this.so3SensorFromWorld, this.processMagTempM4);
        this.so3SensorFromWorld.set(this.processMagTempM4);
        this.updateCovariancesAfterMotion();
      } else {
        this.magObservationFunctionForNumericalJacobian(this.so3SensorFromWorld, this.mNu);
        So3Util.sO3FromMu(this.mNu, this.so3LastMotion);
        Matrix3x3d.mult(this.so3LastMotion, this.so3SensorFromWorld, this.processMagTempM4);
        this.so3SensorFromWorld.set(this.processMagTempM4);
        this.updateCovariancesAfterMotion();
        this.alignedToNorth = true;
      }
    }
  }

  private glMatrixFromSo3(so3: Matrix3x3d): number[] {
    for (let r = 0; r < 3; r++) {
      for (let c = 0; c < 3; c++) {
        this.rotationMatrix[4 * c + r] = so3.get(r, c);
      }
    }

    this.rotationMatrix[3] = 0.0;
    this.rotationMatrix[7] = 0.0;
    this.rotationMatrix[11] = 0.0;
    this.rotationMatrix[12] = 0.0;
    this.rotationMatrix[13] = 0.0;
    this.rotationMatrix[14] = 0.0;
    this.rotationMatrix[15] = 1.0;
    return this.rotationMatrix;
  }

  private filterGyroTimestep(timeStep: number): void {
    const kFilterCoeff = 0.95;
    const kMinSamples = 10.0;
    if (!this.timestepFilterInit) {
      this.filteredGyroTimestep = timeStep;
      this.numGyroTimestepSamples = 1;
      this.timestepFilterInit = true;
    } else {
      this.filteredGyroTimestep = kFilterCoeff * this.filteredGyroTimestep + 0.050000012 * timeStep;
      if (++this.numGyroTimestepSamples > kMinSamples) {
        this.gyroFilterValid = true;
      }
    }
  }

  private updateCovariancesAfterMotion(): void {
    this.so3LastMotion.transpose(this.updateCovariancesAfterMotionTempM1);
    Matrix3x3d.mult(this.mP, this.updateCovariancesAfterMotionTempM1, this.updateCovariancesAfterMotionTempM2);
    Matrix3x3d.mult(this.so3LastMotion, this.updateCovariancesAfterMotionTempM2, this.mP);
    this.so3LastMotion.setIdentity();
  }

  private accObservationFunctionForNumericalJacobian(so3SensorFromWorldPred: Matrix3x3d, result: Vector3d): void {
    Matrix3x3d.mult(so3SensorFromWorldPred, this.down, this.mh);
    this.so3Helper.sO3FromTwoVec(this.mh, this.mz, this.accObservationFunctionForNumericalJacobianTempM);
    this.so3Helper.muFromSO3(this.accObservationFunctionForNumericalJacobianTempM, result);
  }

  private magObservationFunctionForNumericalJacobian(so3SensorFromWorldPred: Matrix3x3d, result: Vector3d): void {
    Matrix3x3d.mult(so3SensorFromWorldPred, this.north, this.mh);
    this.so3Helper.sO3FromTwoVec(this.mh, this.mz, this.magObservationFunctionForNumericalJacobianTempM);
    this.so3Helper.muFromSO3(this.magObservationFunctionForNumericalJacobianTempM, result);
  }
}

