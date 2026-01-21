/**
 * libpanorama_renderer.so 类型声明
 */

/**
 * 渲染一帧
 */
export const render: () => void;

/**
 * 设置视图矩阵
 * @param matrix 4x4 视图矩阵，Float32Array 格式，16个元素
 */
export const setViewMatrix: (matrix: Float32Array) => void;

/**
 * 设置是否启用分屏模式（双眼立体视图）
 * @param enabled 是否启用
 */
export const setStereoMode: (enabled: boolean) => void;

/**
 * 设置瞳距（IPD）
 * @param ipd 瞳距，单位：米
 */
export const setIPD: (ipd: number) => void;

/**
 * 设置视场角（FOV）
 * @param fov 视场角，单位：度
 */
export const setFOV: (fov: number) => void;

// setTexture removed

/**
 * 检查渲染器是否已初始化
 */
export const isInitialized: () => boolean;

/**
 * 获取视频纹理的 Surface ID
 * @return Surface ID 字符串
 */
export const getSurfaceId: () => string;
