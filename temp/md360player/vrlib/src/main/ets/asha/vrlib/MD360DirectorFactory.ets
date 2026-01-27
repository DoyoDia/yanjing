/**
 * Created by hzqiujiadi on 16/3/13.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { MD360Director, Builder } from './MD360Director';
import { MatrixUtil } from './common/MatrixUtil';

/**
 * 360度导演工厂抽象类
 */
export abstract class MD360DirectorFactory {
  abstract createDirector(index: number): MD360Director;
}

/**
 * 默认实现
 */
export class DefaultDirectorFactory extends MD360DirectorFactory {
  override createDirector(index: number): MD360Director {
    // switch (index) {
    //   case 1:
    //     return MD360Director.builder().setEyeX(-2.0).setLookX(-2.0).build();
    //   default:
    //     return MD360Director.builder().build();
    // }
    return MD360Director.builder().build();
  }
}

/**
 * 正交实现
 */
export class OrthogonalDirectorFactory extends MD360DirectorFactory {
  override createDirector(index: number): MD360Director {
    // switch (index) {
    //   default:
    //     return new OrthogonalDirector(new MD360Director.Builder());
    // }
    return new OrthogonalDirector(MD360Director.builder());
  }
}

/**
 * 正交导演类
 */
class OrthogonalDirector extends MD360Director {
  public constructor(builder: Builder) {
    super(builder);
  }

  override setDeltaX(mDeltaX: number): void {
    // nop
  }

  override setDeltaY(mDeltaY: number): void {
    // nop
  }

  override updateSensorMatrix(sensorMatrix: number[]): void {
    // nop
  }

  protected override updateProjection(): void {
    const left = -1.0;
    const right = 1.0;
    const bottom = -1.0;
    const top = 1.0;
    const far = 500;
    MatrixUtil.orthoM(this.getProjectionMatrix(), 0, left, right, bottom, top, this.getNear(), far);
  }
}

