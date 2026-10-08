import { common } from '@kit.AbilityKit';
import util from '@ohos.util';

PersistentStorage.persistProp('xaocen_r05_reading_position', 0);

@Entry
@Component
struct Index {
  @StorageLink('xaocen_r05_reading_position') readingPosition: number = 0;
  @State samplePages: string[] = [];
  @State loadMessage: string = '正在读取 TXT 样本…';

  aboutToAppear(): void {
    this.loadSampleText();
  }

  private async loadSampleText(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const bytes = await context.resourceManager.getRawFileContent('sample.txt');
      const decoded = util.TextDecoder.create('utf-8').decodeToString(bytes);
      this.samplePages = decoded.split('\n---PAGE---\n');
      if (this.readingPosition >= this.samplePages.length) {
        this.readingPosition = 0;
      }
      this.loadMessage = 'TXT 样本已从应用资源读取';
    } catch (error) {
      this.samplePages = ['TXT 样本载入失败，请检查 resources/rawfile/sample.txt。'];
      this.readingPosition = 0;
      this.loadMessage = 'TXT 样本读取失败';
      console.error(`R05 sample load failed: ${JSON.stringify(error)}`);
    }
  }

  private movePosition(delta: number): void {
    const lastPosition = Math.max(0, this.samplePages.length - 1);
    this.readingPosition = Math.min(lastPosition, Math.max(0, this.readingPosition + delta));
  }

  build() {
    Column({ space: 14 }) {
      Text('XAOCEN Reader · R05 HarmonyOS NEXT')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text(this.loadMessage)
        .fontSize(13)
        .fontColor('#59636E')
        .width('100%')

      Scroll() {
        Text(this.samplePages[this.readingPosition] ?? '等待 TXT 样本…')
          .fontSize(18)
          .lineHeight(30)
          .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)

      Image($r('app.media.r05_sample_image'))
        .width('100%')
        .height(180)
        .objectFit(ImageFit.Contain)
        .backgroundColor('#F0F2F4')
        .borderRadius(12)

      Text(`本地阅读位置：${this.readingPosition + 1} / ${Math.max(1, this.samplePages.length)}`)
        .fontSize(15)
        .width('100%')

      Row({ space: 12 }) {
        Button('上一页')
          .enabled(this.readingPosition > 0)
          .layoutWeight(1)
          .onClick(() => this.movePosition(-1))
        Button('下一页')
          .enabled(this.readingPosition < this.samplePages.length - 1)
          .layoutWeight(1)
          .onClick(() => this.movePosition(1))
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F3EE')
  }
}
