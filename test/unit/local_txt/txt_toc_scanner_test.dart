import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/local_txt/toc_entry.dart';
import 'package:xaocen_reader/sources/local_txt/txt_normalizer.dart';
import 'package:xaocen_reader/sources/local_txt/txt_toc_scanner.dart';

void main() {
  const scanner = TxtTocScanner();

  TxtScanHelper scan(String raw) {
    final normalized = TxtNormalizer.normalize(raw);
    final result = scanner.scan(normalized);
    return TxtScanHelper(
      result.entries,
      result.volumeCount,
      result.chapterCount,
    );
  }

  group('章节规则', () {
    test('第X章 识别', () {
      final r = scan('第1章 开始\n正文\n第2章 继续\n');
      expect(r.chapterCount, 2);
      expect(r.chapters[0].title, '第1章 开始');
      expect(r.chapters[0].displayTitle, '第1章 开始');
      expect(r.chapters[0].chapterNumber, '1');
    });

    test('中文数字章节', () {
      final r = scan('第一百零五章 测试\n正文\n');
      expect(r.chapterCount, 1);
      expect(r.chapters[0].title, '第一百零五章 测试');
    });

    test('楔子/序章/前言/后记/尾声/番外/终章', () {
      final r = scan('楔子\n序章\n前言\n正文\n后记\n尾声\n番外\n终章\n');
      expect(r.chapterCount, 7);
    });

    test('公告误匹配排除：第五十二章被审核了', () {
      final r = scan('第1章 正常\n正文。\n第五十二章被审核了，稍等～\n第2章 继续\n');
      expect(r.chapterCount, 2);
      expect(r.chapters.map((c) => c.title), ['第1章 正常', '第2章 继续']);
    });

    test('「章」后必须是空白/标点/行尾', () {
      // "第1章abc" 不匹配（章后是字母）
      final r = scan('第1章abc\n正文\n');
      expect(r.chapterCount, 0);
    });
  });

  group('相邻重复去重', () {
    test('行首 + 缩进重复 → 保留行首', () {
      final r = scan('第1章 同名\n\u3000\u3000第1章 同名\n正文\n');
      expect(r.chapterCount, 1);
      expect(r.chapters.single.title, '第1章 同名');
      expect(r.chapters.single.displayTitle, '第1章 同名');
    });

    test('行距 ≤3 才去重', () {
      // 行距 4 → 不去重
      final r = scan('第1章 同名\n\n\n\n\n\u3000\u3000第1章 同名\n');
      expect(r.chapterCount, 2);
    });

    test('两个行首同名 → 不去重', () {
      final r = scan('第1章 同名\n正文\n第1章 同名\n');
      expect(r.chapterCount, 2);
    });

    test('远距同名 → 保留', () {
      final r = scan('序章 缘起\n内容\n第1章 开始\n内容\n序章 回归\n内容\n');
      expect(r.chapterCount, 3);
    });
  });

  group('卷层级', () {
    test('第X卷 + 卷内章节', () {
      final r = scan(
        '第一卷 风起\n第1章 初见\n内容\n第2章 再见\n内容\n'
        '第二卷 云涌\n第1章 新篇\n内容\n',
      );
      expect(r.volumeCount, 2);
      expect(r.chapterCount, 3);
      // 卷内章节 order 重新编号
      final chapters = r.chapters;
      expect(chapters[0].order, 1); // 第一卷 第1章
      expect(chapters[1].order, 2); // 第一卷 第2章
      expect(chapters[2].order, 1); // 第二卷 第1章（重新编号）
      expect(chapters[2].parentId, r.volumes[1].id);
    });

    test('卷一 形式', () {
      final r = scan('卷一 起步\n第1章 第一章\n内容\n卷二 进阶\n第2章 第二章\n内容\n');
      expect(r.volumeCount, 2);
      expect(r.chapterCount, 2);
    });

    test('卷前章节 parentId 为空', () {
      final r = scan('楔子\n内容\n第一卷 风起\n第1章 初见\n内容\n');
      expect(r.chapters[0].parentId, isNull); // 楔子在卷前
      expect(r.chapters[1].parentId, r.volumes[0].id);
    });

    test('无卷时章节平铺', () {
      final r = scan('第1章 一\n第2章 二\n');
      expect(r.volumeCount, 0);
      expect(r.chapterCount, 2);
      expect(r.chapters.every((c) => c.parentId == null), isTrue);
    });

    test('卷不计入章节总数', () {
      final r = scan('第一卷 一\n第1章 二\n第2章 三\n');
      expect(r.volumeCount, 1);
      expect(r.chapterCount, 2);
    });
  });

  group('坐标', () {
    test('章节偏移为 UTF-16 码元坐标', () {
      final r = scan('前言\n第1章 开始\n正文ABC\n');
      // 规范化文本: 前言\n第1章 开始\n正文ABC\n
      // 偏移: 前(0) 言(1) \n(2) 第(3)
      expect(r.chapters[0].startCharacterOffset, 0); // 前言
      expect(r.chapters[1].startCharacterOffset, 3); // 第1章
    });

    test('多字节字符按码元计（UTF-16 单位）', () {
      final r = scan('𠀀𠀀\n第1章 开始\n'); // 两个 4 字节字符 = 4 个 UTF-16 码元 + \n
      expect(r.chapters[0].title, '第1章 开始');
      expect(r.chapters[0].startCharacterOffset, 5);
    });
  });

  group('M3.2 完整标题合同', () {
    test('1. 完整章节标题保留（含具体名称）', () {
      final r = scan('第31章 山雨欲来\n正文\n');
      expect(r.chapters.single.title, '第31章 山雨欲来');
      expect(r.chapters.single.displayTitle, '第31章 山雨欲来');
    });

    test('2. 标题编号与具体名称分离（chapterNumber）', () {
      final r = scan('第31章 山雨欲来\n正文\n第101章 归途\n');
      expect(r.chapters[0].chapterNumber, '31');
      expect(r.chapters[1].chapterNumber, '101');
      // 中文数字
      final r2 = scan('第一百零五章 测试\n正文\n');
      expect(r2.chapters.single.chapterNumber, '一百零五');
      // 卷一 形式
      final r3 = scan('卷一 起风\n正文\n');
      expect(r3.volumes.single.chapterNumber, '一');
    });

    test('3. 缩进标题 trim 后展示正确', () {
      final r = scan('\u3000\u3000第2章 缩进标题\n正文\n');
      expect(r.chapters.single.title, '第2章 缩进标题');
      expect(r.chapters.single.displayTitle, '第2章 缩进标题');
    });

    test('4. dedupeKey 不进入 UI（title 用完整标题）', () {
      final r = scan('第1章 开端\n正文\n');
      expect(r.chapters.single.title, '第1章 开端');
      expect(r.chapters.single.dedupeKey, isNot('第1章'));
    });

    test('5. 相邻重复只保留行首（完整标题去重）', () {
      final r = scan('第1章 同名标题\n\u3000\u3000第1章 同名标题\n正文\n');
      expect(r.chapterCount, 1);
      expect(r.chapters.single.title, '第1章 同名标题');
      expect(r.chapters.single.isVolume, isFalse);
    });

    test('6. 远距同名保留', () {
      final r = scan('第1章 重逢\n正文\n第2章 重逢\n');
      expect(r.chapterCount, 2);
    });

    test('7. 卷标题完整', () {
      final r = scan('第六卷 人间风雨\n第1章 开端\n正文\n');
      expect(r.volumeCount, 1);
      expect(r.volumes.single.title, '第六卷 人间风雨');
      expect(r.volumes.single.displayTitle, '第六卷 人间风雨');
    });

    test('8. 公告仍排除（含正文句的缩进行不误判为标题）', () {
      // 「第五十二章被审核了」章后是汉字 → 排除
      final r = scan('第1章 正常\n正文。\n第五十二章被审核了，稍等～\n第2章 继续\n');
      expect(r.chapterCount, 2);
      expect(r.chapters.map((c) => c.title), ['第1章 正常', '第2章 继续']);
    });
  });
}

class TxtScanHelper {
  TxtScanHelper(this.entries, this.volumeCount, this.chapterCount);

  final List<TocEntry> entries;
  final int volumeCount;
  final int chapterCount;

  List<TocEntry> get chapters => entries.where((e) => e.isChapter).toList();

  List<TocEntry> get volumes => entries.where((e) => e.isVolume).toList();
}
