export enum MD360PlayerCmd {
  UNKNOWN = 0,
  INIT = 1,
  DESTROY = 2,
  RESUME = 3,
  PAUSE = 4,
  // VR相关命令（新增）
  SET_VR_MODE_ENABLED = 5,
  SET_IPD = 6,
  SET_BARREL_DISTORTION_ENABLED = 7,
  SET_BARREL_DISTORTION_PARAMS = 8
}

export declare class MD360Player {
  constructor()

  // 基础方法（已实现）
  setSurfaceId(surfaceId : string) : number;
  runCmd(cmd: MD360PlayerCmd): number;
  updateMVPMatrix(matrix: number[]): void;
  updateTouchDelta(deltaX: number, deltaY: number): void;
  getVideoSurfaceId(): string;
  setClearColor(r: number, g: number, b: number, a: number): void;
  setCullFaceEnabled(enabled: boolean): void;
  setDepthTestEnabled(enabled: boolean): void;

  // 多屏/分屏渲染方法（已实现）
  setViewport(x: number, y: number, width: number, height: number): void;
  setScissor(x: number, y: number, width: number, height: number): void;
  setScissorEnabled(enabled: boolean): void;
  
  // 混合模式方法（已实现）
  setBlendEnabled(enabled: boolean): void;
  setBlendFunc(src: number, dst: number): void;
  
  // 投影模式方法（已实现）
  setProjectionMode(mode: number): void;

  // VR模式相关接口（新增）
  setVRModeEnabled(enabled: boolean): number;
  setIPD(ipd: number): number;
  setBarrelDistortionEnabled(enabled: boolean): number;
  setBarrelDistortionParams(k1: number, k2: number, scale: number): number;

  // 陀螺仪方法
  turnOnGyro(): void;
  turnOffGyro(): void;
  turnOnInGL(): void;
  turnOffInGL(): void;
  handleDrag(distanceX: number, distanceY: number): boolean;
  updateGyroData(quatX: number, quatY: number, quatZ: number, quatW: number): void;
  getSensorMatrix(): number[];
  onResume(): void;
  onPause(): void;
  isSupport(): boolean;
}

