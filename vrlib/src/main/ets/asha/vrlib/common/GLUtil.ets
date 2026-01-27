/**
 * OpenGL工具类
 * 参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/opengles
 * 
 * 注意：在HarmonyOS中使用OpenGL ES需要：
 * 1. 在module.json5中声明opengles能力
 * 2. 使用@ohos.opengles模块提供的API
 * 3. 通过XComponent组件创建OpenGL上下文
 */
import { MatrixUtil } from './MatrixUtil';

// TODO: 根据HarmonyOS实际API导入OpenGL ES模块
// 在HarmonyOS中，OpenGL ES API可能通过以下方式提供：
// - @ohos.opengles 模块
// - 或者通过XComponent的Native API
// 当前版本中渲染主要通过 NAPI 在 C++ 层完成，这里的 gl 仅用于日志和占位，
// 因此提供一个“空实现”以避免运行时出现 "gl is not defined"。
interface GLInterface {
  getError(): number;

  createShader(type: number): number;

  shaderSource(shader: number, source: string): void;

  compileShader(shader: number): void;

  getShaderParameter(shader: number, pname: number): number;

  getShaderInfoLog(shader: number): string;

  deleteShader(shader: number): void;

  createProgram(): number;

  attachShader(program: number, shader: number): void;

  bindAttribLocation(program: number, index: number, name: string): void;

  linkProgram(program: number): void;

  getProgramParameter(program: number, pname: number): number;

  getProgramInfoLog(program: number): string;

  deleteProgram(program: number): void;
}

// 简单的空实现类，避免在未集成 OpenGL JS 接口时发生运行时错误。
// 将来如果接入 @ohos.opengles，可以在此处替换为真实 gl 对象。
class DummyGL implements GLInterface {
  getError(): number {
    return 0;
  }

  createShader(_type: number): number {
    return 1;
  }

  shaderSource(_shader: number, _source: string): void {
  }

  compileShader(_shader: number): void {
  }

  getShaderParameter(_shader: number, _pname: number): number {
    return 1;
  }

  getShaderInfoLog(_shader: number): string {
    return '';
  }

  deleteShader(_shader: number): void {
  }

  createProgram(): number {
    return 1;
  }

  attachShader(_program: number, _shader: number): void {
  }

  bindAttribLocation(_program: number, _index: number, _name: string): void {
  }

  linkProgram(_program: number): void {
  }

  getProgramParameter(_program: number, _pname: number): number {
    return 1;
  }

  getProgramInfoLog(_program: number): string {
    return '';
  }

  deleteProgram(_program: number): void {
  }
}

const gl: GLInterface = new DummyGL();

const TAG: string = 'GLUtil';

// OpenGL ES常量
const GL_NO_ERROR = 0;
const GL_VERTEX_SHADER = 0x8B31;
const GL_FRAGMENT_SHADER = 0x8B30;
const GL_COMPILE_STATUS = 0x8B81;
const GL_LINK_STATUS = 0x8B82;

export class GLUtil {
  private static readonly IDENTITY_MATRIX: number[] = [
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
  ];

  static {
    // 初始化单位矩阵
    MatrixUtil.setIdentityM(GLUtil.IDENTITY_MATRIX, 0);
  }

  /**
   * 对应 Java 中的 sIdentityMatrix。
   */
  static identityMatrix(): number[] {
    // 返回副本，避免外部修改内部静态数组
    return GLUtil.IDENTITY_MATRIX.slice();
  }

  /**
   * 检查系统是否支持 OpenGL ES 2.0
   * 在HarmonyOS中，OpenGL ES 2.0是标准支持，通常返回true
   * 
   * @param context 上下文（可选，在HarmonyOS中可能不需要）
   * @return true: 支持
   */
  static supportsEs2(context?: ESObject): boolean {
    // HarmonyOS默认支持OpenGL ES 2.0
    // 如果需要更精确的检测，可以使用设备能力查询API
    try {
      // 尝试创建一个测试上下文来验证支持
      // 在HarmonyOS中，可以通过尝试初始化OpenGL来检测
      return true;
    } catch (e) {
      console.error(TAG, 'Error checking OpenGL ES 2.0 support:', e);
      return false;
    }
  }

  /**
   * 检查OpenGL错误
   * 
   * @param op 操作名称
   */
  static glCheck(op: string): void {
    let error: number;
    while ((error = gl.getError()) !== GL_NO_ERROR) {
      const errorString = GLUtil.getErrorString(error);
      console.error(TAG, `${op}: glError ${errorString} (0x${error.toString(16)})`);
    }
  }

  /**
   * 获取OpenGL错误字符串
   */
  private static getErrorString(error: number): string {
    switch (error) {
      case 0x0500: return 'GL_INVALID_ENUM';
      case 0x0501: return 'GL_INVALID_VALUE';
      case 0x0502: return 'GL_INVALID_OPERATION';
      case 0x0503: return 'GL_STACK_OVERFLOW';
      case 0x0504: return 'GL_STACK_UNDERFLOW';
      case 0x0505: return 'GL_OUT_OF_MEMORY';
      case 0x0506: return 'GL_INVALID_FRAMEBUFFER_OPERATION';
      default: return `UNKNOWN_ERROR(${error})`;
    }
  }

  /**
   * 从资源文件读取文本
   * 
   * @param context 上下文
   * @param resourceId 资源ID
   * @return 文本内容，失败返回null
   */
  static readTextFileFromRaw(context: ESObject, resourceId: number): string | null {
    // TODO: 在HarmonyOS中，需要使用ResourceManager API读取资源文件
    // 示例：
    // try {
    //   const resourceManager = context.resourceManager;
    //   const rawFile = await resourceManager.getRawFileContent(resourceId);
    //   return rawFile.toString();
    // } catch (e) {
    //   console.error(TAG, 'Error reading raw file:', e);
    //   return null;
    // }
    console.warn(TAG, 'readTextFileFromRaw not implemented for HarmonyOS');
    return null;
  }

  /**
   * 编译着色器
   * 
   * @param shaderType 着色器类型（GL_VERTEX_SHADER 或 GL_FRAGMENT_SHADER）
   * @param shaderSource 着色器源代码
   * @return OpenGL着色器句柄
   */
  static compileShader(shaderType: number, shaderSource: string): number {
    // 创建着色器
    const shaderHandle = gl.createShader(shaderType);

    if (shaderHandle === 0) {
      throw new Error('Error creating shader.');
    }

    // 设置着色器源代码
    gl.shaderSource(shaderHandle, shaderSource);

    // 编译着色器
    gl.compileShader(shaderHandle);

    // 获取编译状态
    const compileStatus = gl.getShaderParameter(shaderHandle, GL_COMPILE_STATUS);

    // 如果编译失败，删除着色器
    if (compileStatus === 0) {
      const infoLog = gl.getShaderInfoLog(shaderHandle);
      console.error(TAG, `Error compiling shader: ${infoLog}`);
      gl.deleteShader(shaderHandle);
      throw new Error(`Error compiling shader: ${infoLog}`);
    }

    return shaderHandle;
  }

  /**
   * 创建并链接程序
   * 
   * @param vertexShaderHandle 顶点着色器句柄
   * @param fragmentShaderHandle 片段着色器句柄
   * @param attributes 需要绑定到程序的属性数组
   * @return OpenGL程序句柄
   */
  static createAndLinkProgram(
    vertexShaderHandle: number,
    fragmentShaderHandle: number,
    attributes?: string[]
  ): number {
    // 创建程序
    const programHandle = gl.createProgram();

    if (programHandle === 0) {
      throw new Error('Error creating program.');
    }

    // 绑定顶点着色器到程序
    gl.attachShader(programHandle, vertexShaderHandle);

    // 绑定片段着色器到程序
    gl.attachShader(programHandle, fragmentShaderHandle);

    // 绑定属性
    if (attributes != null) {
      const size = attributes.length;
      for (let i = 0; i < size; i++) {
        gl.bindAttribLocation(programHandle, i, attributes[i]);
      }
    }

    // 链接两个着色器到程序
    gl.linkProgram(programHandle);

    // 获取链接状态
    const linkStatus = gl.getProgramParameter(programHandle, GL_LINK_STATUS);

    // 如果链接失败，删除程序
    if (linkStatus === 0) {
      const infoLog = gl.getProgramInfoLog(programHandle);
      console.error(TAG, `Error linking program: ${infoLog}`);
      gl.deleteProgram(programHandle);
      throw new Error(`Error linking program: ${infoLog}`);
    }

    return programHandle;
  }

  /**
   * 加载3D对象
   * 注意：此方法在HarmonyOS中需要适配资源加载方式
   * 
   * @param context 上下文
   * @param resourceId 资源ID
   * @param output 输出对象
   */
  static loadObject3D(context: ESObject, resourceId: number, output: ESObject): void {
    // TODO: 在HarmonyOS中，需要使用ResourceManager API加载.obj文件
    // 然后解析顶点、纹理坐标和面数据
    // 最后使用Float32Array和Uint16Array设置到output对象
    console.warn(TAG, 'loadObject3D not fully implemented for HarmonyOS');
    
    // 示例实现框架：
    // 1. 使用ResourceManager读取.obj文件
    // 2. 解析顶点(v)、纹理坐标(vt)、面(f)数据
    // 3. 构建vertexBuffer、textureBuffer、indexBuffer
    // 4. 使用Float32Array和Uint16Array创建缓冲区
    // 5. 调用output的setVerticesBuffer、setTexCoordinateBuffer、setNumIndices方法
  }
}


