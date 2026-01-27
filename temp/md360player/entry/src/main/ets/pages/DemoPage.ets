/**
 * Demo 主入口页面
 * 对应 Android 项目的 DemoActivity
 * 提供 URL 输入和选择功能，可以跳转到不同的播放页面
 */

import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import picker from '@ohos.file.picker';
import { fileIo as fs, fileUri } from '@kit.CoreFileKit';

// Select 选项接口
interface SelectOption {
  value: string;
  text: string;
}

@Entry
@Component
struct DemoPage {
  @State urlText: string = '';
  @State selectedUrlIndex: number = -1;
  
  // 预设的 URL 列表（对应 Android 项目的 data）
  // 注意：部分 URL 可能需要根据实际情况调整
  private urlList: string[] = [
    // 网络视频 URL
    'https://vd3.bdstatic.com/mda-pdc2kmwtd2vxhiy4/cae_h264/1681502407203843413/mda-pdc2kmwtd2vxhiy4.mp4'
    // 本地文件路径示例（需要用户自己放置文件）
    // 'file:///data/storage/el2/base/files/test360video.mp4',
    // 'file:///data/storage/el2/base/files/ch0_160701145544.ts',
    // 'file:///data/storage/el2/base/files/videos_s_4.mp4',
    // 'file:///data/storage/el2/base/files/28.mp4',
    // 'file:///data/storage/el2/base/files/haha.mp4',
    // 'file:///data/storage/el2/base/files/halfdome.mp4',
    // 'file:///data/storage/el2/base/files/dome.mp4',
    // 'file:///data/storage/el2/base/files/stereo.mp4',
    // 'file:///data/storage/el2/base/files/look25fps3M.mp4',
    // 图片 URL 示例（用于位图播放）
    // 'https://example.com/bitmap360.jpg',
    // 'https://example.com/texture.jpg',
    // 'https://example.com/dome_pic.jpg',
    // 'https://example.com/stereo.jpg',
    // 'https://example.com/multifisheye.png',
  ];

  build() {
    Scroll() {
      Column() {
      // 标题
      Text('MD360Player Demo')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      // URL 标签
      Text('URL')
        .fontSize(16)
        .margin({ top: 12, bottom: 8 })
        .alignSelf(ItemAlign.Start)
        .margin({ left: 16 })

      // URL 下拉选择器
      Select(this.urlList.map((url, index): SelectOption => {
        return { value: url, text: this.getUrlDisplayText(url) };
      }))
        .value(this.selectedUrlIndex >= 0 ? this.urlList[this.selectedUrlIndex] : '')
        .onSelect((index: number) => {
          this.selectedUrlIndex = index;
          this.urlText = this.urlList[index];
        })
        .margin({ left: 16, right: 16, bottom: 8 })
        .width('90%')

      // URL 输入框
      TextInput({ placeholder: '输入视频 URL' })
        .onChange((value: string) => {
          this.urlText = value;
          this.selectedUrlIndex = -1; // 清除选择
        })
        .margin({ left: 16, right: 16, bottom: 16 })
        .width('90%')
        .height(40)
        .border({ width: 1, color: '#CCCCCC', radius: 4 })

      // 操作按钮标签
      Text('Action')
        .fontSize(16)
        .margin({ top: 12, bottom: 8 })
        .alignSelf(ItemAlign.Start)
        .margin({ left: 16 })

      // 按钮行 1: 视频播放
      Row() {
        Button('播放视频')
          .onClick(() => {
            this.startVideo();
          })
          .layoutWeight(1)
          .margin({ right: 8 })

        Button('使用本地文件')
          .onClick(() => {
            this.startVideoWithLocalFile();
          })
          .layoutWeight(1)
          .margin({ left: 8 })
      }
      .width('90%')
      .margin({ left: 16, right: 16, bottom: 8 })

      // 按钮行 2: 从图库选择视频
      Button('从图库选择视频')
        .onClick(() => {
          this.selectVideoFromGallery();
        })
        .width('90%')
        .margin({ left: 16, right: 16, bottom: 8 })
        .backgroundColor('#4CAF50')
        .fontColor('#FFFFFF')

      // 说明文本
      Text('说明：\n' +
           '1. 可以从下拉列表选择预设 URL\n' +
           '2. 也可以手动输入网络 URL\n' +
           '3. 也可以直接点击使用本地文件\n' +
           '4. 当前仅支持视频播放功能')
        .fontSize(12)
        .fontColor('#666666')
        .margin({ top: 20, left: 16, right: 16 })
        .textAlign(TextAlign.Start)
        .width('90%')

        Blank()
      }
      .width('100%')
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .scrollBarColor('#80000000')
    .scrollBarWidth(4)
  }

  /**
   * 获取 URL 的显示文本（截取前50个字符）
   */
  private getUrlDisplayText(url: string): string {
    if (url.length > 50) {
      return url.substring(0, 50) + '...';
    }
    return url;
  }

  /**
   * 开始播放视频
   */
  private startVideo(): void {
    const url = this.urlText.trim();
    if (!url) {
      this.showToast('请输入视频 URL');
      return;
    }

    // 跳转到视频播放页面
    router.pushUrl({
      url: 'pages/VideoPlayerPage',
      params: {
        videoUrl: url
      }
    }).catch((error: Error) => {
      console.error('Failed to navigate to VideoPlayerPage:', error);
      this.showToast('跳转失败: ' + error.message);
    });
  }

  /**
   * 使用本地文件播放视频
   */
  private startVideoWithLocalFile(): void {
    // 跳转到视频播放页面，使用本地文件
    router.pushUrl({
      url: 'pages/VideoPlayerPage',
      params: {
        useLocalFile: true
      }
    }).catch((error: Error) => {
      console.error('Failed to navigate to VideoPlayerPage:', error);
      this.showToast('跳转失败: ' + error.message);
    });
  }

  /**
   * 从图库选择视频
   */
  private async selectVideoFromGallery(): Promise<void> {
    try {
      // 1. 创建PhotoViewPicker实例
      const photoPicker = new picker.PhotoViewPicker();
      
      // 2. 配置选择参数
      const options: picker.PhotoSelectOptions = {
        maxSelectNumber: 1, // 选择数量（视频场景通常为1）
        MIMEType: picker.PhotoViewMIMETypes.VIDEO_TYPE, // 指定视频类型
      };
      
      // 3. 拉起相册并获取结果
      const uris = await photoPicker.select(options);
      
      if (uris && uris.photoUris && uris.photoUris.length > 0) {
        const selectedVideoUri = uris.photoUris[0];
        console.log('DemoPage: Selected video URI:', selectedVideoUri);
        
        try {
          // 显示加载提示
          this.showToast('正在复制视频文件...');
          
          // 将视频复制到沙箱目录
          const context = getContext() as common.UIAbilityContext;
          const filesDir = context.filesDir;
          
          // 生成目标文件名（使用时间戳确保唯一性）
          const timestamp = Date.now();
          const targetFileName = `selected_video_${timestamp}.mp4`;
          const targetPath = `${filesDir}/${targetFileName}`;
          
          console.log('DemoPage: Copying video from:', selectedVideoUri, 'to:', targetPath);
          
          // 打开源文件
          const sourceFile = await fs.open(selectedVideoUri, fs.OpenMode.READ_ONLY);
          
          // 创建目标文件
          const targetFile = fs.openSync(targetPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
          
          // 读取并写入文件（分块读取，避免内存问题）
          const bufferSize = 1024 * 1024; // 1MB 缓冲区
          let totalBytesRead = 0;
          let bytesRead = 0;
          
          do {
            const buffer = new ArrayBuffer(bufferSize);
            bytesRead = fs.readSync(sourceFile.fd, buffer);
            
            if (bytesRead > 0) {
              // 只写入实际读取的字节
              const writeBuffer = buffer.slice(0, bytesRead);
              fs.writeSync(targetFile.fd, writeBuffer);
              totalBytesRead += bytesRead;
            }
          } while (bytesRead === bufferSize);
          
          // 关闭文件
          await fs.close(sourceFile);
          fs.closeSync(targetFile);
          
          console.log('DemoPage: Video copied successfully, total bytes:', totalBytesRead);
          console.log('DemoPage: Target path:', targetPath);
          
          // 跳转到视频播放页面，传递沙箱目录中的文件路径
          router.pushUrl({
            url: 'pages/VideoPlayerPage',
            params: {
              videoUrl: targetPath // 使用沙箱目录中的文件路径
            }
          }).catch((error: Error) => {
            console.error('Failed to navigate to VideoPlayerPage:', error);
            this.showToast('跳转失败: ' + error.message);
          });
        } catch (error) {
          console.error('DemoPage: Failed to copy video file:', error);
          this.showToast('复制视频文件失败');
        }
      } else {
        console.log('DemoPage: No video selected');
      }
    } catch (err) {
      console.error('DemoPage: 选择失败: ' + JSON.stringify(err));
      this.showToast('选择视频失败');
    }
  }

  /**
   * 显示 Toast 提示
   */
  private showToast(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    } catch (error) {
      console.error('Failed to show toast:', error);
    }
  }
}

