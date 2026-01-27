/**
 * 日志写入器
 */
interface Writer {
  close(): void;
  flush(): void;
  write(buf: string | string[], offset?: number, count?: number): void;
}

export class LogWriter implements Writer {
  private mBuilder: string = '';

  close(): void {
    this.flushBuilder();
  }

  flush(): void {
    this.flushBuilder();
  }

  write(buf: string | string[], offset?: number, count?: number): void {
    if (typeof buf === 'string') {
      // 字符串写入
      for (let i = 0; i < buf.length; i++) {
        const c = buf[i];
        if (c === '\n') {
          this.flushBuilder();
        } else {
          this.mBuilder += c;
        }
      }
    } else if (Array.isArray(buf)) {
      // 字符数组写入
      const start = offset ?? 0;
      const end = count != null ? start + count : buf.length;
      for (let i = start; i < end; i++) {
        const c = buf[i];
        if (c === '\n') {
          this.flushBuilder();
        } else {
          this.mBuilder += c;
        }
      }
    }
  }

  private flushBuilder(): void {
    if (this.mBuilder.length > 0) {
      console.log('GLSurfaceView', this.mBuilder);
      this.mBuilder = '';
    }
  }
}

