export interface EGLDisplay {}
export interface EGLConfig {}
export interface GL {}
export interface GL10 extends GL {
    glGetString(name: number): string;
}
export interface EGLContext {
    getGL(): GL;
}
export interface EGLSurface {}
export interface GLDebugHelper {}

export interface EGL10 {
    eglCreateContext(display: EGLDisplay, config: EGLConfig, share_context: EGLContext | null, attrib_list: number[] | null): EGLContext;
    eglDestroyContext(display: EGLDisplay, context: EGLContext): boolean;
    eglGetError(): number;
    eglGetDisplay(display_id: Object): EGLDisplay;
    eglInitialize(display: EGLDisplay, version: number[]): boolean;
    eglMakeCurrent(display: EGLDisplay, draw: EGLSurface | null, read: EGLSurface | null, context: EGLContext | null): boolean;
    eglSwapBuffers(display: EGLDisplay, surface: EGLSurface): boolean;
    eglTerminate(display: EGLDisplay): boolean;
    eglChooseConfig(display: EGLDisplay, attrib_list: number[], configs: EGLConfig[] | null, config_size: number, num_config: number[]): boolean;
    eglGetConfigAttrib(display: EGLDisplay, config: EGLConfig, attribute: number, value: number[]): boolean;
    eglCreateWindowSurface(display: EGLDisplay, config: EGLConfig, native_window: Object, attrib_list: number[] | null): EGLSurface;
    eglDestroySurface(display: EGLDisplay, surface: EGLSurface): boolean;
}

export interface EGL11 extends EGL10 {}
