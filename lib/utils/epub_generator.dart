import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';
import '../models/book_info.dart';

class EpubGenerator {
  final BookInfo book;
  final String outputPath;

  EpubGenerator({
    required this.book,
    required this.outputPath,
  });

  Future<void> generate() async {
    final archive = Archive();

    // Add mimetype file (must be first and uncompressed)
    final mimetypeBytes = 'application/epub+zip'.codeUnits;
    archive.addFile(
      ArchiveFile(
        'mimetype',
        mimetypeBytes.length,
        mimetypeBytes,
        compression: CompressionLevel.none,
      ),
    );

    // Add container.xml
    await _addContainerXml(archive);

    // Process cover image
    String? coverImagePath;
    if (book.coverImage != null) {
      coverImagePath = await _processAndAddCoverImage(archive);
    }

    // Generate and add chapter files
    final chapterFiles = await _addChapters(archive);

    // Add table of contents
    await _addTocNcx(archive, chapterFiles);

    // Add content.opf
    await _addContentOpf(archive, chapterFiles, coverImagePath);

    // Add navigation document (EPUB 3)
    await _addNavXhtml(archive, chapterFiles);

    // Add stylesheet
    await _addStylesheet(archive);

    // Add cover page if needed
    if (coverImagePath != null) {
      await _addCoverPage(archive, coverImagePath);
    }

    // Create and save the EPUB file
    final encoded = ZipEncoder().encode(archive)!;
    await File(outputPath).writeAsBytes(encoded);
  }

  Future<void> _addContainerXml(Archive archive) async {
    final containerXml = XmlDocument([
      XmlProcessing('xml', {'version': '1.0', 'encoding': 'UTF-8'}),
      XmlElement(
      XmlName('container'),
      {
        'version': '1.0',
        'xmlns': 'urn:oasis:names:tc:opendocument:xmlns:container',
      },
      [
        XmlElement(XmlName('rootfiles'),
        [
          XmlElement(
            XmlName('rootfile'),
            {
              'full-path': 'OEBPS/content.opf',
              'media-type': 'application/oebps-package+xml',
            },
          ),
        ],
      ],
    ),
    ]).toXmlString(pretty: true);

    archive.addFile(
      ArchiveFile(
        'META-INF/container.xml',
        containerXml.length,
        Utf8Encoder().convert(containerXml),
      ),
    );
  }

  Future<String> _processAndAddCoverImage(Archive archive) async {
    final coverBytes = await book.coverImage!.readAsBytes();
    final image = img.decodeImage(coverBytes);

    if (image == null) {
      throw Exception('无法解码封面图片');
    }

    // Resize cover image for best quality while maintaining aspect ratio
    const maxDimension = 1600;
    late img.Image resized;

    if (image.width > maxDimension || image.height > maxDimension) {
      final ratio = maxDimension / (image.width > image.height ? image.width : image.height);
      resized = img.copyResize(
        image,
        width: (image.width * ratio).round(),
        height: (image.height * ratio).round(),
      );
    } else {
      resized = image;
    }

    final jpgBytes = img.encodeJpg(resized, quality: 85);
    const coverPath = 'OEBPS/cover.jpg';

    archive.addFile(
      ArchiveFile(
        coverPath,
        jpgBytes.length,
        jpgBytes,
      ),
    );

    return coverPath;
  }

  Future<List<String>> _addChapters(Archive archive) async {
    final chapterFiles = <String>[];

    for (var i = 0; i < book.chapters.length; i++) {
      final chapterNum = i + 1;
      final chapterContent = book.chapters[i];
      final chapterHtml = _generateChapterHtml(chapterContent, chapterNum);
      final fileName = 'OEBPS/chapter_$chapterNum.xhtml';

      archive.addFile(
        ArchiveFile(
          fileName,
          chapterHtml.length,
          Utf8Encoder().convert(chapterHtml),
        ),
      );

      chapterFiles.add(fileName);
    }

    return chapterFiles;
  }

  String _generateChapterHtml(String content, int chapterNumber) {
    final paragraphs = content.split('\n\n');
    final htmlContent = StringBuffer();

    for (var para in paragraphs) {
      para = para.trim();
      if (para.isEmpty) continue;
      para = para.replaceAll('\n', ' ');
      para = _escapeHtml(para);
      htmlContent.writeln('<p>$para</p>');
    }

    // Try to extract chapter title from first line
    var chapterTitle = '第 $chapterNumber 章';
    if (paragraphs.isNotEmpty) {
      final firstLine = paragraphs.first.trim();
      if (firstLine.length < 100) {
        chapterTitle = _escapeHtml(firstLine);
      }
    }

    return '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>${_escapeHtml(chapterTitle)}</title>
  <link rel="stylesheet" type="text/css" href="style.css"/>
  <meta charset="utf-8"/>
</head>
<body>
  <h2>$chapterTitle</h2>
  $htmlContent
</body>
</html>''';
  }

  Future<void> _addTocNcx(Archive archive, List<String> chapterFiles) async {
    final navPoints = StringBuffer();
    var playOrder = 1;

    for (var i = 0; i < chapterFiles.length; i++) {
      final chapterNum = i + 1;
      final chapterFile = chapterFiles[i];
      final relativePath = path.basename(chapterFile);

      navPoints.writeln('''
    <navPoint id="chapter$chapterNum" playOrder="$playOrder">
      <navLabel>
        <text>第 $chapterNum 章</text>
      </navLabel>
      <content src="$relativePath"/>
    </navPoint>''');
      playOrder++;
    }

    final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="urn:uuid:${_generateUuid()}"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle>
    <text>${_escapeXml(book.title)}</text>
  </docTitle>
  <docAuthor>
    <text>${_escapeXml(book.author)}</text>
  </docAuthor>
  $navPoints
</ncx>''';

    archive.addFile(
      ArchiveFile(
        'OEBPS/toc.ncx',
        tocNcx.length,
        Utf8Encoder().convert(tocNcx),
      ),
    );
  }

  Future<void> _addContentOpf(Archive archive, List<String> chapterFiles, String? coverImagePath) async {
    final manifest = StringBuffer();
    final spine = StringBuffer();

    manifest.writeln('    <item id="css" href="style.css" media-type="text/css"/>');
    manifest.writeln('    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');
    manifest.writeln('    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');

    String? coverMeta = '';
    if (coverImagePath != null) {
      final relativeCoverPath = path.basename(coverImagePath);
      manifest.writeln('    <item id="cover" href="$relativeCoverPath" media-type="image/jpeg" properties="cover-image"/>');
      manifest.writeln('    <item id="cover-page" href="cover.xhtml" media-type="application/xhtml+xml"/>');
      spine.writeln('    <itemref idref="cover-page"/>');
      coverMeta = '    <meta name="cover" content="cover"/>';
    }

    for (var i = 0; i < chapterFiles.length; i++) {
      final chapterNum = i + 1;
      final chapterFile = chapterFiles[i];
      final relativePath = path.basename(chapterFile);

      manifest.writeln('    <item id="chapter$chapterNum" href="$relativePath" media-type="application/xhtml+xml"/>');
      spine.writeln('    <itemref idref="chapter$chapterNum"/>');
    }

    final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="uuid-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>${_escapeXml(book.title)}</dc:title>
    <dc:creator>${_escapeXml(book.author)}</dc:creator>
    <dc:language>zh-CN</dc:language>
    <dc:identifier id="uuid-id">urn:uuid:${_generateUuid()}</dc:identifier>
    <meta property="dcterms:modified">${_getCurrentDate()}</meta>
$coverMeta
  </metadata>
  <manifest>
$manifest
  </manifest>
  <spine toc="ncx">
$spine
  </spine>
</package>''';

    archive.addFile(
      ArchiveFile(
        'OEBPS/content.opf',
        contentOpf.length,
        Utf8Encoder().convert(contentOpf),
      ),
    );
  }

  Future<void> _addNavXhtml(Archive archive, List<String> chapterFiles) async {
    final navItems = StringBuffer();

    for (var i = 0; i < chapterFiles.length; i++) {
      final chapterNum = i + 1;
      final chapterFile = chapterFiles[i];
      final relativePath = path.basename(chapterFile);

      navItems.writeln('      <li><a href="$relativePath">第 $chapterNum 章</a></li>');
    }

    final navXhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
  <title>目录</title>
  <link rel="stylesheet" type="text/css" href="style.css"/>
  <meta charset="utf-8"/>
</head>
<body>
  <nav epub:type="toc">
    <h1>目录</h1>
    <ol>
$navItems
    </ol>
  </nav>
</body>
</html>''';

    archive.addFile(
      ArchiveFile(
        'OEBPS/nav.xhtml',
        navXhtml.length,
        Utf8Encoder().convert(navXhtml),
      ),
    );
  }

  Future<void> _addStylesheet(Archive archive) async {
    const css = '''
@page {
  margin: 5pt;
}

body {
  margin: 5%;
  font-family: "PingFang SC", "Helvetica Neue", Helvetica, Arial, sans-serif;
  line-height: 1.6;
  text-align: justify;
  -webkit-line-break: auto;
  -webkit-line-break: strict;
}

h1, h2 {
  font-family: "PingFang SC", "Helvetica Neue", Helvetica, Arial, sans-serif;
  margin-top: 2em;
  page-break-before: always;
  text-align: center;
  font-weight: bold;
}

h1 {
  font-size: 2em;
  margin-bottom: 1em;
}

h2 {
  font-size: 1.5em;
  margin-bottom: 0.8em;
}

p {
  margin: 0.8em 0;
  text-indent: 2em;
}

.cover {
  text-align: center;
  page-break-after: always;
  margin: 0;
  padding: 0;
}

.cover img {
  max-width: 100%;
  height: auto;
}

.cover-title {
  font-size: 2.5em;
  font-weight: bold;
  margin-top: 2em;
  text-align: center;
}

.cover-author {
  font-size: 1.5em;
  margin-top: 1em;
  text-align: center;
  color: #666666;
}

.toc-entry {
  margin: 0.5em 0;
}
''';

    archive.addFile(
      ArchiveFile(
        'OEBPS/style.css',
        css.length,
        Utf8Encoder().convert(css),
      ),
    );
  }

  Future<void> _addCoverPage(Archive archive, String coverImagePath) async {
    final relativeCoverPath = path.basename(coverImagePath);
    final coverHtml = '''<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>封面</title>
  <link rel="stylesheet" type="text/css" href="style.css"/>
  <meta charset="utf-8"/>
</head>
<body>
  <div class="cover">
    <img src="$relativeCoverPath" alt="封面"/>
  </div>
  <div class="cover-title">${_escapeHtml(book.title)}</div>
  <div class="cover-author">${_escapeHtml(book.author)}</div>
</body>
</html>''';

    archive.addFile(
      ArchiveFile(
        'OEBPS/cover.xhtml',
        coverHtml.length,
        Utf8Encoder().convert(coverHtml),
      ),
    );
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }

  String _escapeXml(String text) => _escapeHtml(text);

  String _generateUuid() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}-${now.microsecondsSinceEpoch}';
  }

  String _getCurrentDate() {
    return DateTime.now().toIso8601String();
  }
}
