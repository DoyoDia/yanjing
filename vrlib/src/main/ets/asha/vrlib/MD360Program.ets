/**
 * Created by hzqiujiadi on 16/1/22.
 * hzqiujiadi ashqalcn@gmail.com
 */

import { Context } from '../../google/android/apps/muzei/render/ViewTypes';
import { GLUtil } from './common/GLUtil';
import { ContentType } from './MDVRLibrary';

/**
 * 360度着色器程序类
 */
export class MD360Program {
  private mMVPMatrixHandle: number = 0;
  private mMVMatrixHandle: number = 0;
  private mTextureUniformHandle: number = 0;
  private mPositionHandle: number = 0;
  private mTextureCoordinateHandle: number = 0;
  private mProgramHandle: number = 0;
  private mSTMatrixHandle: number = 0;
  private mUseTextureTransformHandle: number = 0;
  private mIsSkyboxHandle: number = 0;
  private mContentType: number;

  constructor(type: number) {
    this.mContentType = type;
  }

  /**
   * 构建程序
   * 1. 创建程序句柄
   * 2. 编译着色器
   * 3. 链接程序
   * 4. 获取属性句柄和uniform句柄
   * @param context 上下文
   */
  build(context: Context): void {
    const vertexShader = this.getVertexShader(context);
    const fragmentShader = this.getFragmentShader(context);

    // const vertexShaderHandle = GLUtil.compileShader(GLES20.GL_VERTEX_SHADER, vertexShader);
    // const fragmentShaderHandle = GLUtil.compileShader(GLES20.GL_FRAGMENT_SHADER, fragmentShader);
    // 在鸿蒙中，需要使用对应的OpenGL API
    const vertexShaderHandle = 0; // 占位
    const fragmentShaderHandle = 0; // 占位

    // this.mProgramHandle = GLUtil.createAndLinkProgram(vertexShaderHandle, fragmentShaderHandle,
    //   ["a_Position", "a_TexCoordinate"]);
    // 在鸿蒙中，需要使用对应的OpenGL API
    this.mProgramHandle = 0; // 占位

    // 设置立方体绘制的程序句柄
    // this.mMVPMatrixHandle = GLES20.glGetUniformLocation(this.mProgramHandle, "u_MVPMatrix");
    // this.mMVMatrixHandle = GLES20.glGetUniformLocation(this.mProgramHandle, "u_MVMatrix");
    // this.mTextureUniformHandle = GLES20.glGetUniformLocation(this.mProgramHandle, "u_Texture");
    // this.mPositionHandle = GLES20.glGetAttribLocation(this.mProgramHandle, "a_Position");
    // this.mTextureCoordinateHandle = GLES20.glGetAttribLocation(this.mProgramHandle, "a_TexCoordinate");
    // this.mSTMatrixHandle = GLES20.glGetUniformLocation(this.mProgramHandle, "u_STMatrix");
    // this.mUseTextureTransformHandle = GLES20.glGetUniformLocation(this.mProgramHandle, "u_UseSTM");
    // this.mIsSkyboxHandle = GLES20.glGetUniformLocation(this.mProgramHandle, "u_IsSkybox");
    // 在鸿蒙中，需要使用对应的OpenGL API
  }

  protected getVertexShader(context: Context): string {
    // return GLUtil.readTextFileFromRaw(context, R.raw.per_pixel_vertex_shader);
    // 在鸿蒙中，需要从资源文件读取着色器代码
    return ""; // 占位
  }

  protected getFragmentShader(context: Context): string {
    return FragmentShaderFactory.fs(context, this.mContentType);
  }

  use(): void {
    // GLES20.glUseProgram(this.mProgramHandle);
    // 在鸿蒙中，需要使用对应的OpenGL API
  }

  getMVPMatrixHandle(): number {
    return this.mMVPMatrixHandle;
  }

  getMVMatrixHandle(): number {
    return this.mMVMatrixHandle;
  }

  getTextureUniformHandle(): number {
    return this.mTextureUniformHandle;
  }

  getPositionHandle(): number {
    return this.mPositionHandle;
  }

  getSTMatrixHandle(): number {
    return this.mSTMatrixHandle;
  }

  getUseTextureTransformHandle(): number {
    return this.mUseTextureTransformHandle;
  }

  getIsSkyboxHandle(): number {
    return this.mIsSkyboxHandle;
  }

  getTextureCoordinateHandle(): number {
    return this.mTextureCoordinateHandle;
  }
}

/**
 * 片段着色器工厂类
 */
class FragmentShaderFactory {
  static fs(context: Context, type: number): string {
    // let resId: number;
    // switch (type) {
    //   case MDVRLibrary.ContentType.BITMAP:
    //     resId = R.raw.per_pixel_fragment_shader_bitmap;
    //     break;
    //   case MDVRLibrary.ContentType.FBO:
    //     resId = R.raw.per_pixel_fragment_shader_bitmap_fbo;
    //     break;
    //   case MDVRLibrary.ContentType.CUBEMAP:
    //     resId = R.raw.per_pixel_fragment_shader_cubemap;
    //     break;
    //   case MDVRLibrary.ContentType.VIDEO:
    //   default:
    //     resId = R.raw.per_pixel_fragment_shader;
    //     break;
    // }
    // return GLUtil.readTextFileFromRaw(context, resId);
    // 在鸿蒙中，需要从资源文件读取着色器代码
    return ""; // 占位
  }
}

