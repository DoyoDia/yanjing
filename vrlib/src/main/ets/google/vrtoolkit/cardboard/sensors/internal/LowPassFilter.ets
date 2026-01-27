/**
 * 低通滤波器类
 */
import { Vector3d } from './Vector3d';

export class LowPassFilter {
  private static readonly NANOS_TO_SECONDS: number = 1.0 / 1000000000.0;
  private readonly timeConstantSecs: number;
  private readonly filteredData: Vector3d = new Vector3d();
  private lastTimestampNs: number = 0;
  private numSamples: number = 0;
  private readonly temp: Vector3d = new Vector3d();

  constructor(cutoffFrequency: number) {
    this.timeConstantSecs = 1.0 / (6.283185307179586 * cutoffFrequency);
  }

  getNumSamples(): number {
    return this.numSamples;
  }

  addSample(sampleData: Vector3d, timestampNs: number): void {
    this.addWeightedSample(sampleData, timestampNs, 1.0);
  }

  addWeightedSample(sampleData: Vector3d, timestampNs: number, weight: number): void {
    this.numSamples++;
    if (this.numSamples === 1) {
      this.filteredData.set(sampleData);
      this.lastTimestampNs = timestampNs;
    } else {
      const weightedDeltaSecs = weight * (timestampNs - this.lastTimestampNs) * LowPassFilter.NANOS_TO_SECONDS;
      const alpha = weightedDeltaSecs / (this.timeConstantSecs + weightedDeltaSecs);
      this.filteredData.scale(1.0 - alpha);
      this.temp.set(sampleData);
      this.temp.scale(alpha);
      Vector3d.add(this.temp, this.filteredData, this.filteredData);
      this.lastTimestampNs = timestampNs;
    }
  }

  getFilteredData(): Vector3d {
    return this.filteredData;
  }
}

