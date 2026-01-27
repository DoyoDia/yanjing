/**
 * Created by hzqiujiadi on 2017/4/20.
 * hzqiujiadi ashqalcn@gmail.com
 */

/**
 * 命中点类
 */
export class MDHitPoint {
  private static readonly sNotHit: number = Number.MAX_VALUE;
  // 延迟创建 NotHit，避免“在声明前使用”问题
  private static sPointNotHit: MDHitPoint | null = null;

  private distance: number = MDHitPoint.sNotHit;
  private u: number = 0;
  private v: number = 0;

  constructor() {
    this.asNotHit();
  }

  asNotHit(): void {
    this.distance = MDHitPoint.sNotHit;
  }

  isNotHit(): boolean {
    return this.distance === MDHitPoint.sNotHit;
  }

  nearThen(other: MDHitPoint): boolean {
    return this.distance <= other.distance;
  }

  getU(): number {
    return this.u;
  }

  getV(): number {
    return this.v;
  }

  set(t: number, u: number, v: number): void {
    this.distance = t;
    this.u = u;
    this.v = v;
  }

  static min(a: MDHitPoint, b: MDHitPoint): MDHitPoint {
    return a.distance < b.distance ? a : b;
  }

  static notHit(): MDHitPoint {
    if (MDHitPoint.sPointNotHit == null) {
      MDHitPoint.sPointNotHit = new NotHit();
    }
    return MDHitPoint.sPointNotHit;
  }
}

/**
 * 未命中的实现类（不可修改）
 */
class NotHit extends MDHitPoint {
  override set(t: number, u: number, v: number): void {
    throw new Error("NotHit can't be set.");
  }
}

