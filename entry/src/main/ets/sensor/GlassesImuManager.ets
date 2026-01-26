/**
 * GlassesImuManager - USB 眼镜 IMU 读取管理
 * 参考 alicedemo 的 USB IMU 流程实现
 */

import usbManager from '@ohos.usbManager';
import { Quaternion } from '../utils/MathUtils';

type USBDevice = usbManager.USBDevice;
type USBDevicePipe = usbManager.USBDevicePipe;
type USBInterface = usbManager.USBInterface;
type USBEndpoint = usbManager.USBEndpoint;

export interface GlassesDeviceInfo {
  vendorId: number;
  productId: number;
  name: string;
}

export interface GlassesConnectionState {
  connected: boolean;
  hasPermission: boolean;
  streaming: boolean;
  deviceInfo: GlassesDeviceInfo | null;
}

export interface GlassesImuListener {
  onConnectionChanged(state: GlassesConnectionState): void;
  onImuQuaternion(quaternion: Quaternion): void;
  onError(message: string, code?: number): void;
}

interface UsbInterfaces {
  imuInterface: USBInterface;
  cmdInterface: USBInterface;
}

class TargetDevice {
  vid: number;
  pid: number;

  constructor(vid: number, pid: number) {
    this.vid = vid;
    this.pid = pid;
  }
}

export class GlassesImuManager {
  private static instance: GlassesImuManager | null = null;

  private listeners: GlassesImuListener[] = [];

  private connectedDevice: USBDevice | null = null;
  private state: GlassesConnectionState = {
    connected: false,
    hasPermission: false,
    streaming: false,
    deviceInfo: null
  };

  private pipe: USBDevicePipe | null = null;
  private imuInterface: USBInterface | null = null;
  private cmdInterface: USBInterface | null = null;
  private imuEndpoint: USBEndpoint | null = null;
  private cmdInEndpoint: USBEndpoint | null = null;
  private cmdOutEndpoint: USBEndpoint | null = null;

  private wantStreaming: boolean = false;
  private isReading: boolean = false;
  private monitorTimerId: number = -1;
  private readTimerId: number = -1;

  private sequenceNumber: number = 0;

  private readonly timeoutMs: number = 3000;
  private readonly imuPacketSize: number = 26;
  private readonly cmdPacketSize: number = 24;
  private readonly scanIntervalMs: number = 1000;

  private readonly targetDevices: TargetDevice[] = [
    new TargetDevice(0x0483, 0x5741),
    new TargetDevice(0x4817, 0x4242),
    new TargetDevice(0x4817, 0x5742),
    new TargetDevice(0x17EF, 0xB816),
    new TargetDevice(0x17EF, 0x5743)
  ];

  private constructor() {}

  public static getInstance(): GlassesImuManager {
    if (!GlassesImuManager.instance) {
      GlassesImuManager.instance = new GlassesImuManager();
    }
    return GlassesImuManager.instance;
  }

  public async initialize(): Promise<void> {
    this.startMonitoring();
  }

  public addListener(listener: GlassesImuListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  public removeListener(listener: GlassesImuListener): void {
    const index = this.listeners.indexOf(listener);
    if (index !== -1) {
      this.listeners.splice(index, 1);
    }
  }

  public getState(): GlassesConnectionState {
    return {
      connected: this.state.connected,
      hasPermission: this.state.hasPermission,
      streaming: this.state.streaming,
      deviceInfo: this.state.deviceInfo
    };
  }

  public startMonitoring(): void {
    if (this.monitorTimerId !== -1) {
      return;
    }
    this.refreshConnection();
    this.monitorTimerId = setInterval(() => {
      this.refreshConnection();
    }, this.scanIntervalMs);
  }

  public stopMonitoring(): void {
    if (this.monitorTimerId !== -1) {
      clearInterval(this.monitorTimerId);
      this.monitorTimerId = -1;
    }
  }

  public startImu(): void {
    this.wantStreaming = true;
    if (this.state.connected && this.state.hasPermission && !this.state.streaming) {
      void this.startStreaming();
    }
  }

  public stopImu(): void {
    this.wantStreaming = false;
    this.stopStreaming();
  }

  private refreshConnection(): void {
    const devices = this.getDeviceList();
    const match = this.findGlassesDevice(devices);

    if (match && !this.state.connected) {
      this.handleDeviceAttached(match);
      return;
    }

    if (match && this.state.connected && !this.state.hasPermission) {
      this.refreshPermission(match);
      return;
    }

    if (!match && this.state.connected) {
      this.handleDeviceDetached();
      return;
    }
  }

  private async handleDeviceAttached(device: USBDevice): Promise<void> {
    this.connectedDevice = device;
    const info = this.buildDeviceInfo(device);

    const hasPermission = await this.ensurePermission(device);
    this.state = {
      connected: true,
      hasPermission,
      streaming: false,
      deviceInfo: info
    };
    this.notifyConnectionChanged();

    if (this.wantStreaming && hasPermission) {
      void this.startStreaming();
    }
  }

  private handleDeviceDetached(): void {
    this.stopStreaming();
    this.connectedDevice = null;
    this.state = {
      connected: false,
      hasPermission: false,
      streaming: false,
      deviceInfo: null
    };
    this.notifyConnectionChanged();
  }

  private async refreshPermission(device: USBDevice): Promise<void> {
    const hasPermission = await this.ensurePermission(device);
    if (hasPermission && !this.state.hasPermission) {
      this.state.hasPermission = true;
      this.notifyConnectionChanged();
      if (this.wantStreaming) {
        void this.startStreaming();
      }
    }
  }

  private async startStreaming(): Promise<void> {
    if (this.state.streaming || !this.connectedDevice) {
      return;
    }

    this.pipe = this.openDevice(this.connectedDevice);
    if (!this.pipe) {
      this.reportError('Failed to open USB device');
      return;
    }

    const interfaces = this.resolveInterfaces(this.connectedDevice);
    if (!interfaces) {
      this.reportError('Failed to resolve USB interfaces');
      this.stopStreaming();
      return;
    }

    this.imuInterface = interfaces.imuInterface;
    this.cmdInterface = interfaces.cmdInterface;

    const claimImu = this.claimInterface(this.pipe, this.imuInterface);
    const claimCmd = this.claimInterface(this.pipe, this.cmdInterface);
    if (!claimImu || !claimCmd) {
      this.reportError('Failed to claim USB interfaces');
      this.stopStreaming();
      return;
    }

    this.imuEndpoint = this.getEndpoint(this.imuInterface, 0);
    this.cmdOutEndpoint = this.getEndpoint(this.cmdInterface, 1);
    this.cmdInEndpoint = this.getEndpoint(this.cmdInterface, 0);

    if (!this.imuEndpoint || !this.cmdOutEndpoint || !this.cmdInEndpoint) {
      this.reportError('Failed to resolve USB endpoints');
      this.stopStreaming();
      return;
    }

    const configured = await this.setImuReportDataType(0x02);
    if (!configured) {
      this.reportError('Failed to configure IMU data type');
      this.stopStreaming();
      return;
    }

    this.releaseInterface(this.pipe, this.cmdInterface);

    this.state.streaming = true;
    this.notifyConnectionChanged();
    this.startReadLoop();
  }

  private stopStreaming(): void {
    this.stopReadLoop();

    if (this.pipe && this.cmdInterface) {
      this.releaseInterface(this.pipe, this.cmdInterface);
    }
    if (this.pipe && this.imuInterface) {
      this.releaseInterface(this.pipe, this.imuInterface);
    }
    if (this.pipe) {
      this.closePipe(this.pipe);
    }

    this.pipe = null;
    this.imuInterface = null;
    this.cmdInterface = null;
    this.imuEndpoint = null;
    this.cmdInEndpoint = null;
    this.cmdOutEndpoint = null;
    this.sequenceNumber = 0;

    if (this.state.streaming) {
      this.state.streaming = false;
      this.notifyConnectionChanged();
    }
  }

  private startReadLoop(): void {
    if (this.isReading) {
      return;
    }
    this.isReading = true;
    void this.readLoop();
  }

  private stopReadLoop(): void {
    this.isReading = false;
    if (this.readTimerId !== -1) {
      clearTimeout(this.readTimerId);
      this.readTimerId = -1;
    }
  }

  private async readLoop(): Promise<void> {
    if (!this.isReading) {
      return;
    }

    if (!this.pipe || !this.imuEndpoint) {
      this.scheduleNextRead();
      return;
    }

    const buffer = new Uint8Array(this.imuPacketSize);
    try {
      const readCount = await this.bulkTransfer(this.pipe, this.imuEndpoint, buffer, this.timeoutMs);
      if (readCount > 0) {
        const quaternion = this.parseQuaternion(buffer);
        if (quaternion) {
          this.notifyImuQuaternion(quaternion);
        }
      }
    } finally {
      this.scheduleNextRead();
    }
  }

  private scheduleNextRead(): void {
    if (!this.isReading) {
      return;
    }
    if (this.readTimerId !== -1) {
      clearTimeout(this.readTimerId);
    }
    this.readTimerId = setTimeout(() => {
      void this.readLoop();
    }, 10);
  }

  private async setImuReportDataType(type: number): Promise<boolean> {
    if (!this.pipe || !this.cmdOutEndpoint || !this.cmdInEndpoint) {
      return false;
    }

    this.sequenceNumber = (this.sequenceNumber + 1) & 0xff;
    const packet = new Uint8Array(this.cmdPacketSize);
    packet.set([0x05, 0xAA, 0x01, 0x01, 0x17, this.sequenceNumber, type]);
    packet[23] = this.computeChecksum(packet, 23);

    const written = await this.bulkTransfer(this.pipe, this.cmdOutEndpoint, packet, this.timeoutMs);
    if (written < 0) {
      return false;
    }

    const readBuffer = new Uint8Array(this.cmdPacketSize);
    const readCount = await this.bulkTransfer(this.pipe, this.cmdInEndpoint, readBuffer, this.timeoutMs);
    if (readCount <= 0) {
      return false;
    }

    return readBuffer.length > 6 && readBuffer[6] === type;
  }

  private parseQuaternion(buffer: Uint8Array): Quaternion | null {
    if (buffer.length < 20) {
      return null;
    }

    const view = new DataView(buffer.buffer, buffer.byteOffset, buffer.byteLength);
    const qw = this.fixedToFloat(view.getInt32(4, false));
    const qx = this.fixedToFloat(view.getInt32(8, false));
    const qy = this.fixedToFloat(view.getInt32(12, false));
    const qz = this.fixedToFloat(view.getInt32(16, false));

    const quaternion = new Quaternion(qx, qy, qz, qw);
    quaternion.normalize();
    return quaternion;
  }

  private fixedToFloat(value: number): number {
    return value / (1 << 30);
  }

  private computeChecksum(buffer: Uint8Array, length: number): number {
    let sum = 0;
    for (let i = 0; i < length; i++) {
      sum += buffer[i] & 0xff;
    }
    return sum & 0xff;
  }

  private resolveInterfaces(device: USBDevice): UsbInterfaces | null {
    const pid = this.getProductId(device);
    let imuIndex = 0;
    let cmdIndex = 1;

    if (pid === 0xB816 || pid === 0x5743) {
      imuIndex = 3;
      cmdIndex = 4;
    } else if (pid === 0x5742) {
      imuIndex = 5;
      cmdIndex = 6;
    }

    const imuInterface = this.getInterface(device, imuIndex);
    const cmdInterface = this.getInterface(device, cmdIndex);
    if (!imuInterface || !cmdInterface) {
      return null;
    }

    return { imuInterface, cmdInterface };
  }

  private buildDeviceInfo(device: USBDevice): GlassesDeviceInfo {
    const vendorId = this.getVendorId(device);
    const productId = this.getProductId(device);
    const name = this.getDeviceDisplayName(device, vendorId, productId);
    return { vendorId, productId, name };
  }

  private getDeviceList(): USBDevice[] {
    try {
      const devices = usbManager.getDevices();
      if (Array.isArray(devices)) {
        return devices;
      }
    } catch (error) {
      this.reportError('Failed to get USB device list');
    }
    return [];
  }

  private findGlassesDevice(devices: USBDevice[]): USBDevice | null {
    for (const device of devices) {
      const vid = this.getVendorId(device);
      const pid = this.getProductId(device);
      if (this.isTargetDevice(vid, pid)) {
        return device;
      }
    }
    return null;
  }

  private isTargetDevice(vid: number, pid: number): boolean {
    return this.targetDevices.some((d) => d.vid === vid && d.pid === pid);
  }

  private getVendorId(device: USBDevice): number {
    return device.vendorId;
  }

  private getProductId(device: USBDevice): number {
    return device.productId;
  }

  private getDeviceDisplayName(device: USBDevice, vid: number, pid: number): string {
    const name = device.name ?? '';
    if (name && name.length > 0) {
      return name;
    }
    return `VID_${vid.toString(16)}_PID_${pid.toString(16)}`;
  }

  private getDeviceKey(device: USBDevice): string {
    return device.name ?? '';
  }

  private async ensurePermission(device: USBDevice): Promise<boolean> {
    const deviceName = this.getDeviceKey(device);
    if (!deviceName) {
      return false;
    }

    try {
      if (usbManager.hasRight(deviceName)) {
        return true;
      }
    } catch (error) {
      this.reportError('hasRight check failed');
    }

    try {
      return await usbManager.requestRight(deviceName);
    } catch (error) {
      this.reportError('USB permission denied');
      return false;
    }
  }

  private openDevice(device: USBDevice): USBDevicePipe | null {
    try {
      return usbManager.connectDevice(device);
    } catch (error) {
      this.reportError('connectDevice failed');
    }
    return null;
  }

  private closePipe(pipe: USBDevicePipe): void {
    try {
      usbManager.closePipe(pipe);
    } catch (error) {
      this.reportError('closePipe failed');
    }
  }

  private claimInterface(pipe: USBDevicePipe, usbInterface: USBInterface): boolean {
    try {
      const result = usbManager.claimInterface(pipe, usbInterface, true);
      return result === 0;
    } catch (error) {
      this.reportError('claimInterface failed');
    }
    return false;
  }

  private releaseInterface(pipe: USBDevicePipe, usbInterface: USBInterface): void {
    try {
      usbManager.releaseInterface(pipe, usbInterface);
    } catch (error) {
      this.reportError('releaseInterface failed');
    }
  }

  private getInterface(device: USBDevice, index: number): USBInterface | null {
    const config = device.configs && device.configs.length > 0 ? device.configs[0] : null;
    if (!config || !config.interfaces) {
      return null;
    }
    return config.interfaces[index] ?? null;
  }

  private getEndpoint(usbInterface: USBInterface, index: number): USBEndpoint | null {
    if (!usbInterface.endpoints) {
      return null;
    }
    return usbInterface.endpoints[index] ?? null;
  }

  private async bulkTransfer(
    pipe: USBDevicePipe,
    endpoint: USBEndpoint,
    buffer: Uint8Array,
    timeout: number
  ): Promise<number> {
    try {
      return await usbManager.bulkTransfer(pipe, endpoint, buffer, timeout);
    } catch (error) {
      this.reportError('bulkTransfer failed');
      return -1;
    }
  }

  private notifyConnectionChanged(): void {
    for (const listener of this.listeners) {
      listener.onConnectionChanged(this.state);
    }
  }

  private notifyImuQuaternion(quaternion: Quaternion): void {
    for (const listener of this.listeners) {
      listener.onImuQuaternion(quaternion);
    }
  }

  private reportError(message: string, code?: number): void {
    console.error(`GlassesImuManager: ${message}`, code ?? '');
    for (const listener of this.listeners) {
      listener.onError(message, code);
    }
  }
}

export function getGlassesImuManager(): GlassesImuManager {
  return GlassesImuManager.getInstance();
}
