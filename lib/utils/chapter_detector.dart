import '../models/book_info.dart';

class ChapterDetector {
  static List<String> splitChapters(
    String content,
    ChapterDetectionMode mode, {
    String customSeparator = '\n\n\n',
  }) {
    List<String> chapters = [];

    switch (mode) {
      case ChapterDetectionMode.auto:
        chapters = _autoDetectChapters(content);
        break;
      case ChapterDetectionMode.chinese:
        chapters = _detectChineseChapters(content);
        break;
      case ChapterDetectionMode.numbered:
        chapters = _detectNumberedChapters(content);
        break;
      case ChapterDetectionMode.english:
        chapters = _detectEnglishChapters(content);
        break;
      case ChapterDetectionMode.customSeparator:
        chapters = content.split(customSeparator);
        break;
    }

    // 清理空章节
    chapters = chapters
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    // 如果没有检测到章节，返回整个内容作为单章节
    if (chapters.isEmpty) {
      chapters = [content.trim()];
    }

    return chapters;
  }

  static List<String> _autoDetectChapters(String content) {
    final allPatterns = <RegExp>[
      // 中文章节模式
      RegExp(r'^[ \t]*第[一二三四五六七八九十零百千0-9]+[章回卷篇节].*', multiLine: true),
      RegExp(r'^[ \t]*[一二三四五六七八九十零百千]+、.*', multiLine: true),
      // 英文章节模式
      RegExp(r'^[ \t]*Chapter\s+[0-9]+.*', multiLine: true, caseSensitive: false),
      RegExp(r'^[ \t]*Vol(?:ume)?\.?\s*[0-9]+.*', multiLine: true, caseSensitive: false),
      RegExp(r'^[ \t]*Book\s+[0-9]+.*', multiLine: true, caseSensitive: false),
      // 数字编号模式
      RegExp(r'^[ \t]*[0-9]+(\.|\s|、).*', multiLine: true),
      RegExp(r'^[ \t]*§\s*[0-9]+.*', multiLine: true),
    ];

    return _splitByPatterns(content, allPatterns);
  }

  static List<String> _detectChineseChapters(String content) {
    final patterns = <RegExp>[
      RegExp(r'^[ \t]*第[一二三四五六七八九十零百千0-9]+[章回卷篇节].*', multiLine: true),
      RegExp(r'^[ \t]*[一二三四五六七八九十零百千]+、.*', multiLine: true),
      RegExp(r'^[ \t]*(?:序|前言|后记|附录|楔子).*', multiLine: true),
    ];

    return _splitByPatterns(content, patterns);
  }

  static List<String> _detectNumberedChapters(String content) {
    final patterns = <RegExp>[
      RegExp(r'^[ \t]*[0-9]+(\.|\s|、).*', multiLine: true),
      RegExp(r'^[ \t]*§\s*[0-9]+.*', multiLine: true),
    ];

    return _splitByPatterns(content, patterns);
  }

  static List<String> _detectEnglishChapters(String content) {
    final patterns = <RegExp>[
      RegExp(r'^[ \t]*Chapter\s+[0-9]+.*', multiLine: true, caseSensitive: false),
      RegExp(r'^[ \t]*Vol(?:ume)?\.?\s*[0-9]+.*', multiLine: true, caseSensitive: false),
      RegExp(r'^[ \t]*Book\s+[0-9]+.*', multiLine: true, caseSensitive: false),
      RegExp(r'^[ \t]*Part\s+[0-9]+.*', multiLine: true, caseSensitive: false),
    ];

    return _splitByPatterns(content, patterns);
  }

  static List<String> _splitByPatterns(String content, List<RegExp> patterns) {
    final chapterStarts = <int>[];

    // 查找所有章节起始位置
    for (final pattern in patterns) {
      final matches = pattern.allMatches(content);
      for (final match in matches) {
        if (match.start >= 0) {
          chapterStarts.add(match.start);
        }
      }
    }

    // 如果没有找到章节标记，返回整个内容
    if (chapterStarts.isEmpty) {
      return [content];
    }

    // 排序并去重
    chapterStarts.sort();
    final uniqueStarts = <int>[];
    int? last;
    for (final pos in chapterStarts) {
      // 避免太接近的章节（间隔小于50字符）
      if (last == null || pos - last > 50) {
        uniqueStarts.add(pos);
        last = pos;
      }
    }

    // 分割内容
    final chapters = <String>[];
    int lastPos = 0;
    for (final pos in uniqueStarts) {
      if (pos > lastPos) {
        chapters.add(content.substring(lastPos, pos));
      }
      lastPos = pos;
    }
    if (lastPos < content.length) {
      chapters.add(content.substring(lastPos));
    }

    return chapters;
  }

  static Future<String> detectEncoding(File file) async {
    // 读取文件开头部分检测编码
    final bytes = await file.openRead(0, 1024).first;

    // 检测UTF-8 BOM
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return 'utf-8';
    }

    // 尝试解码为UTF-8
    try {
      const Utf8Decoder(allowMalformed: false).convert(bytes);
      return 'utf-8';
    } catch (_) {
      // 假设为GBK编码
      return 'gbk';
    }
  }

  static String cleanContent(String content) {
    // 清理无效字符
    content = content.replaceAll('\r\n', '\n');
    content = content.replaceAll('\r', '\n');

    // 清理多余的空行
    final lines = content.split('\n');
    final cleanedLines = <String>[];
    int emptyLineCount = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        emptyLineCount++;
        if (emptyLineCount <= 2) {
          cleanedLines.add(line);
        }
      } else {
        emptyLineCount = 0;
        cleanedLines.add(line);
      }
    }

    return cleanedLines.join('\n');
  }

  static String extractTitleFromFilename(String filename) {
    // 从文件名提取书名
    String title = filename;

    // 移除扩展名
    if (title.contains('.')) {
      title = title.substring(0, title.lastIndexOf('.'));
    }

    // 清理常见的前缀后缀
    title = title.replaceAll(RegExp(r'^(.*?)_'), '');
    title = title.replaceAll(RegExp(r'_txt$'), '');
    title = title.replaceAll(RegExp(r'_text$'), '');
    title = title.replaceAll(RegExp(r'_full$'), '');
    title = title.replaceAll(RegExp(r'_complete$'), '');
    title = title.replaceAll(RegExp(r'_完整版$'), '');
    title = title.replaceAll(RegExp(r'_全集$'), '');

    // 替换下划线为空格
    title = title.replaceAll('_', ' ');
    title = title.replaceAll('-', ' ');

    // 移除多余空格
    title = title.trim();

    return title.isNotEmpty ? title : '未命名书籍';
  }
}
