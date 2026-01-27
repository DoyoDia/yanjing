import { Surface } from '../../../google/android/apps/muzei/render/ViewTypes';
import { IMDHotspot } from '../plugins/hotspot/IMDHotspot';
import { MDRay } from './MDRay';
import { MDHitEvent } from './MDHitEvent';
import { MotionEvent } from '../AndroidTypes';

export interface MD360Program {
    getUseTextureTransformHandle(): number;
    getSTMatrixHandle(): number;
}

export interface IOnSurfaceReadyCallback {
    onSurfaceReady(surface: Surface): void;
}

export interface MDLayoutParams {
    width: number;
    height: number;
}

export type Bitmap = Object;

export interface IMD360BitmapTextureCallback {
    texture(bitmap: Bitmap): void;
    getMaxTextureSize(): number;
}

export interface IBitmapProvider {
    onProvideBitmap(callback: IMD360BitmapTextureCallback): void;
}

export interface IEyePickListener {
  onHotspotHit(hitHotspot: IMDHotspot, hitTimestamp: number): void;
}

export interface IEyePickListener2 {
  onHotspotHit(hitEvent: MDHitEvent): void;
}

export interface ITouchPickListener {
  onHotspotHit(hitHotspot: IMDHotspot, ray: MDRay): void;
}

export interface ITouchPickListener2 {
  onHotspotHit(hitEvent: MDHitEvent): void;
}

export interface IGestureListener {
  onClick(e: MotionEvent): void;
}
