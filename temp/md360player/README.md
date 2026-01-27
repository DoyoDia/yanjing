# md360player

#### 介绍

MD360Player 是一个轻量级的开源库，主要用于在移动平台上渲染 360 度全景视频，提供沉浸式的 VR 体验。核心功能主要有：360 度全景视频渲染：将普通视频转换为全景视图，支持通过移动设备（如手机、平板）观看全景内容、兼容 VR 设备，增强沉浸感、支持触摸控制、陀螺仪控制，用户可自由切换视角等

## 下载安装

```
ohpm install @ohos/md360player
```

OpenHarmony ohpm
环境配置等更多内容，请参考[如何安装 OpenHarmony ohpm 包](https://gitcode.com/openharmony-tpc/docs/blob/master/OpenHarmony_har_usage.md)。

#### 源码下载
  ```
  git clone https://gitee.com/openharmony-tpc-incubate/md360player.git
  ```


#### 安装教程

1.  下载源码后，使用DevEco Studio打开项目
2.  在菜单栏中找到Build ->Build Hap(s)/App(s) -> Build Hap(s) 编译生成hap包
3.  在默认目录：MD360Player\entry\build\default\outputs\default下找到生成的hap包，默认名为：entry-default-signed.hap

#### 使用说明

1.  打开cmd窗口，执行命令：hdc install MD360Player\entry\build\default\outputs\default\entry-default-signed.hap 安装该包
2.  安装完成后直接启动该应用即可
3.  启动应用后，在URL中输入视频链接地址后，选择播放视频
4.  通过顶部按钮：播放控制、高级控制，选择普通模式/VR模式验证功能即可

#### 流程

1.  页面启动 & 获取视频路径

从路由参数获取视频 URL；若未提供，则使用内置资源 test360video.mp4。
  ```
const params = router.getParams();
if (params['videoUrl']) {
    this.videoUrl = params['videoUrl'];
} else if (params['useLocalFile']) {
    this.videoUrl = ''; // 标记用本地文件
}
  ```
2.  XComponent 加载，触发初始化

XComponent 加载后，调用 initVR(surfaceId)。
  ```
XComponent({ ... })
  .onLoad(async () => {
    const surfaceId = this.xComponentController.getXComponentSurfaceId();
    await this.initVR(surfaceId);
  })
  ```
3.  准备视频文件（如为本地）

若 videoUrl 为空，从 rawfile/test360video.mp4 复制到沙箱。
  ```
const rawFile = await resourceManager.getRawFileContent('test360video.mp4');
fs.writeSync(writeFile.fd, rawFile.buffer);
videoFilePath = `${filesDir}/test360video.mp4`;
  ```
4.  创建回调对象 & 初始化 VR 库

创建 VideoSurfaceCallback 和 MDVRLibrary，绑定上下文与交互模式。
  ```
this.videoCallback = new VideoSurfaceCallback(videoFilePath);
this.vrContext = new Context();
this.vrLibrary = MDVRLibrary.with(this.vrContext)
  .displayMode(MDVRLibrary.DISPLAY_MODE_NORMAL)
  .interactiveMode(MDVRLibrary.INTERACTIVE_MODE_TOUCH)
  .asVideo(this.videoCallback)
  .build(this.xComponentController);
this.vrLibrary.onSurfaceReady(surfaceId);
  ```
5.  轮询获取 C++ 侧的 Video Surface ID

C++ 渲染层会创建一个 NativeImage，其 Surface ID 需通过 getVideoSurfaceId() 获取。
  ```
const videoSurfaceId = this.vrLibrary.getVideoSurfaceId();
if (videoSurfaceId !== null && videoSurfaceId !== '0') {
    await this.videoCallback.setSurfaceIdAndCreatePlayer(videoSurfaceId);
}
  ```
6.  创建 AVPlayer 并绑定 Surface

在 setSurfaceIdAndCreatePlayer 中创建 AVPlayer，并在 initialized 状态设置 surfaceId。
  ```
this.avPlayer = await media.createAVPlayer();
this.avPlayer.on('stateChange', (state) => {
  if (state === 'initialized') {
    this.avPlayer.surfaceId = this.surfaceId;
    this.avPlayer.prepare();
  }
});
this.avPlayer.url = videoUrl;
  ```
7.  播放状态同步

通过 PlaybackStateCallbackImpl 将 AVPlayer 状态同步到 UI（播放/暂停、进度、时长）。
  ```
class PlaybackStateCallbackImpl implements IPlaybackStateCallback {
    onStateChanged(isPlaying) { this.page.isPlaying = isPlaying; }
    onProgressChanged(current, duration) { this.page.currentTime = current; }
}
this.videoCallback.setStateCallback(new PlaybackStateCallbackImpl(this));
  ```
8.  用户交互控制（视角、模式等）

所有控制按钮调用 vrLibrary 的 API。

切换显示模式（普通 / VR）：
  ```
this.vrLibrary.switchDisplayMode(this.vrContext, mode);
const isVRMode = mode === MDVRLibrary.DISPLAY_MODE_GLASS;
this.vrLibrary.setVRModeEnabled(isVRMode);
  ```
切换交互模式（触摸 / 陀螺仪）：
  ```
this.vrLibrary.switchInteractiveMode(this.vrContext, mode);
this.updateGyroStateByInteractiveMode(mode);
  ```
9.  OpenGL 功能控制（Viewport）

通过 MDVRLibrary 的封装方法调用 OpenGL 设置。
  ```
// Viewport
this.vrLibrary.setViewport(x, y, w, h);
  ```
10.   页面销毁，释放资源

退出时释放 AVPlayer 和 C++ 渲染资源。

  ```
XComponent().onDestroy(() => {
  this.videoCallback?.release();   // avPlayer.release()
  this.vrLibrary?.onDestroy();     // C++ cleanup
})
  ```
#### 最终端到端流程
  ```
[路由传参]

    → [XComponent onLoad → initVR]

        → [准备视频路径（本地 or 网络）]

            → [创建 VideoSurfaceCallback + MDVRLibrary]

                → [轮询 getVideoSurfaceId()]

                    → [createAVPlayer + 绑定 surfaceId（initialized 状态）]

                        → [prepare → play → 渲染 360° 视频]

                            → [用户操作：播放控制 / 视角 / 模式 / OpenGL]

                                → [页面退出 → release AVPlayer + onDestroy VR]
  ```
### 接口说明

| 接口                                                                                            | 输入                                                                 | 输出                  | 说明与使用位置                                                                |
|-----------------------------------------------------------------------------------------------|--------------------------------------------------------------------|---------------------|------------------------------------------------------------------------|
| MDVRLibrary.with(context).displayMode().interactiveMode().asVideo(callback).build(controller) | Context、显示/交互模式、IOnSurfaceReadyCallback、XComponentController       | boolean             | 初始化 VR 播放实例，在initVR中创建vrLibrary。                                       |
| vrLibrary.onSurfaceReady(surfaceId)                                                           | string surfaceId                                                   | void                | 将 XComponent 的 surface 传给 VR 底层，在initVR。                               |
| vrLibrary.onDestroy()                                                                         | 无                                                                  | void                | 页面销毁时释放资源，XComponent.onDestroy中调用。                                     |
| vrLibrary.onDrag(distanceX, distanceY)                                                        | number,number                                                      | void                | 触摸拖拽时更新视角，在PanGestureonActionUpdate中。                                  |
| vrLibrary.getVideoSurfaceId()                                                                 | 无                                                                  | string              | 从 NAPI取视频渲染surfaceId，在initVR的重试逻辑中。                                    |
| vrLibrary.switchDisplayMode(context, mode)                                                    | Context,number mode                                                | void                | 切换普通/VR显示模式，在switchDisplayMode。                                        |
| vrLibrary.switchInteractiveMode(context, mode)                                                | Context,number mode                                                | void                | 切换交互模式，在switchInteractiveMode。                                         |
| vrLibrary.switchProjectionMode(context, mode)                                                 | Context,number mode                                                | void                | 切换投影模式，在switchProjectionMode。                                          |
| vrLibrary.setViewport(x, y, width, height)                                                    | number, number, number, number                                     | void                | 设置视口：initViewport、toggleViewport中调用。                                  |
| vrLibrary.setVRModeEnabled(enabled)                                                           | boolean                                                            | number              | 切换VR模式：switchDisplayMode中调用。                                           |
| vrLibrary.isGyroSupported()                                                                   | 无                                                                  | boolean             | 检测设备陀螺仪支持：switchInteractiveMode中调用。                                 |
| vrLibrary.turnOnGyro()                                                                        | 无                                                                  | void                | 开启陀螺仪（包含 turnOnGyro、turnOnInGL、onResume）：updateGyroStateByInteractiveMode。 |
| vrLibrary.turnOffGyro()                                                                       | 无                                                                  | void                | 关闭陀螺仪（包含 turnOffGyro、turnOffInGL、onPause）：updateGyroStateByInteractiveMode。 |
| vrLibrary.updateGyroData(x, y, z, w)                                                          | number, number, number, number                                     | void                | 更新陀螺仪数据（四元数）：startGyroSensor回调中调用。                                |
| vrLibrary.onSurfaceReady(surface)                                                             | Object surface                                                     | void                | VideoSurfaceCallback实现，供asVideo(...)传入，Surface就绪时回调。                   |
| new Context()                                                                                 | 无                                                                  | Context             | 在initVR中创建并传入MDVRLibrary.with(...)。                                    |

### 约束与限制
在下述版本验证通过：
DevEco Studio 版本：DevEco Studio 5.0.0 Release, SDK:API12。

## 目录结构

````
|---- md360player 
|     |---- entry  # 示例代码文件夹
|     |---- vrlib  # md360player 库文件夹
|			|---- src/main/cpp  # native模块
|                  |----- napi # napi实现代码目录
|                  |----- types     # 对外接口函数目录
|     |---- README.md  # 使用方法说明
````

## 贡献代码

使用过程中发现任何问题都可以提 [Issue](https://gitee.com/openharmony-tpc-incubate/md360player/issues) 给组件，当然，也非常欢迎给发 [PR](https://gitee.com/openharmony-tpc-incubate/md360player/pulls)

## 开源协议

本项目基于 [Apache License 2.0](https://gitee.com/openharmony-tpc-incubate/md360player/blob/master/LICENSE) ，请自由地享受和参与开源。