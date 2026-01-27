export class Fps {
  private static readonly TAG: string = 'fps';
  private frameCount: number = 0;
  private lastTimestamp: number = 0;

  step(): void {
    if (this.frameCount % 120 === 0) {
      const current: number = Date.now();
      if (this.lastTimestamp !== 0) {
        const fps: number = (this.frameCount * 1000.0) / (current - this.lastTimestamp);
        console.warn(`${Fps.TAG} fps: ${fps}`);
      }
      this.frameCount = 0;
      this.lastTimestamp = current;
    }
    this.frameCount++;
  }
}


