import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/book_info.dart';
import '../utils/chapter_detector.dart';
import '../utils/epub_generator.dart';
import '../utils/permission_manager.dart';
import '../utils/storage_service.dart';
import '../widgets/custom_card.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _selectedIndex = _tabController.index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('电子书转换器'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.convert), text: '转换'),
            Tab(icon: Icon(Icons.history), text: '历史'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ConverterTab(),
          HistoryScreen(),
        ],
      ),
    );
  }
}

class ConverterTab extends StatefulWidget {
  const ConverterTab({super.key});

  @override
  State<ConverterTab> createState() => _ConverterTabState();
}

class _ConverterTabState extends State<ConverterTab> {
  List<File> _selectedFiles = [];
  File? _coverImageFile;
  bool _isConverting = false;
  String _status = '';
  StatusType _statusType = StatusType.info;
  double _progress = 0.0;

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _chapterSeparatorController = TextEditingController(text: '\n\n\n');

  ChapterDetectionMode _chapterDetectionMode = ChapterDetectionMode.auto;
  bool _autoFillTitle = true;
  bool _saveToHistory = true;
  bool _isBatchMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _chapterSeparatorController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final mode = await StorageService.getDefaultChapterMode();
    final separator = await StorageService.getDefaultSeparator();
    final autoFill = await StorageService.getAutoFillTitle();
    final saveHistory = await StorageService.getSaveToHistory();

    setState(() {
      _chapterDetectionMode = mode;
      _chapterSeparatorController.text = separator;
      _autoFillTitle = autoFill;
      _saveToHistory = saveHistory;
    });
  }

  Future<void> _pickTxtFiles() async {
    try {
      final hasPermission = await PermissionManager.requestStoragePermission();
      if (!hasPermission) {
        _showStatus('需要存储权限才能选择文件', StatusType.error);
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: _isBatchMode,
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.paths.map((path) => File(path!)).toList();
          _status = '已选择 ${_selectedFiles.length} 个文件';
          _statusType = StatusType.success;

          if (_selectedFiles.length == 1 && _autoFillTitle) {
            final filename = _selectedFiles.first.path.split(Platform.pathSeparator).last;
            _titleController.text = ChapterDetector.extractTitleFromFilename(filename);
          } else {
            _titleController.clear();
          }
        });
      }
    } catch (e) {
      _showStatus('选择文件失败: $e', StatusType.error);
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final hasPermission = await PermissionManager.requestPhotosPermission();
      if (!hasPermission) {
        _showStatus('需要相册权限才能选择封面图片', StatusType.error);
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result != null) {
        setState(() {
          _coverImageFile = File(result.files.single.path!);
          _status = '已选择封面图片: ${result.files.single.name}';
          _statusType = StatusType.success;
        });
      }
    } catch (e) {
      _showStatus('选择封面图片失败: $e', StatusType.error);
    }
  }

  void _clearCoverImage() {
    setState(() {
      _coverImageFile = null;
    });
  }

  Future<void> _convertToEpub() async {
    if (_selectedFiles.isEmpty) {
      _showStatus('请先选择TXT文件', StatusType.warning);
      return;
    }

    if (!_isBatchMode && _titleController.text.isEmpty) {
      _showStatus('请输入书籍标题', StatusType.warning);
      return;
    }

    setState(() {
      _isConverting = true;
      _progress = 0.0;
      _status = '开始转换...';
      _statusType = StatusType.info;
    });

    try {
      if (_isBatchMode) {
        await _batchConvert();
      } else {
        await _singleConvert();
      }
    } catch (e) {
      _showStatus('转换失败: $e', StatusType.error);
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  Future<void> _singleConvert() async {
    final file = _selectedFiles.first;
    final content = await file.readAsString();
    final cleanedContent = ChapterDetector.cleanContent(content);

    final chapters = ChapterDetector.splitChapters(
      cleanedContent,
      _chapterDetectionMode,
      customSeparator: _chapterSeparatorController.text,
    );

    final book = BookInfo(
      title: _titleController.text,
      author: _authorController.text.isNotEmpty ? _authorController.text : '未知作者',
      coverImage: _coverImageFile,
      chapters: chapters,
      sourceFilePath: file.path,
    );

    setState(() {
      _progress = 0.3;
      _status = '正在生成EPUB...';
    });

    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/${_titleController.text.replaceAll(' ', '_')}.epub';

    final generator = EpubGenerator(
      book: book,
      outputPath: outputPath,
    );

    await generator.generate();

    final updatedBook = book.copyWith(
      outputPath: outputPath,
      status: ConversionStatus.completed,
    );

    if (_saveToHistory) {
      await StorageService.saveToHistory(updatedBook);
    }

    setState(() {
      _progress = 1.0;
      _status = '转换完成！共生成 ${chapters.length} 章';
      _statusType = StatusType.success;
    });

    _showConversionSuccessDialog(outputPath, updatedBook);
  }

  Future<void> _batchConvert() async {
    final successCount = 0;
    final totalCount = _selectedFiles.length;

    for (var i = 0; i < _selectedFiles.length; i++) {
      try {
        final file = _selectedFiles[i];
        final filename = file.path.split(Platform.pathSeparator).last;
        final title = ChapterDetector.extractTitleFromFilename(filename);

        setState(() {
          _progress = (i + 1) / totalCount;
          _status = '正在转换 ${i + 1}/$totalCount: $title';
        });

        final content = await file.readAsString();
        final cleanedContent = ChapterDetector.cleanContent(content);

        final chapters = ChapterDetector.splitChapters(
          cleanedContent,
          _chapterDetectionMode,
          customSeparator: _chapterSeparatorController.text,
        );

        final book = BookInfo(
          title: title,
          author: _authorController.text.isNotEmpty ? _authorController.text : '未知作者',
          coverImage: _coverImageFile,
          chapters: chapters,
          sourceFilePath: file.path,
        );

        final tempDir = await getTemporaryDirectory();
        final outputPath = '${tempDir.path}/${title.replaceAll(' ', '_')}.epub';

        final generator = EpubGenerator(
          book: book,
          outputPath: outputPath,
        );

        await generator.generate();

        final updatedBook = book.copyWith(
          outputPath: outputPath,
          status: ConversionStatus.completed,
        );

        if (_saveToHistory) {
          await StorageService.saveToHistory(updatedBook);
        }

        successCount++;
      } catch (e) {
        debugPrint('转换文件失败: $e');
      }
    }

    setState(() {
      _progress = 1.0;
      _status = '批量转换完成！成功 $successCount/$totalCount 个文件';
      _statusType = StatusType.success;
    });

    _showBatchSuccessDialog(successCount, totalCount);
  }

  void _showStatus(String message, StatusType type) {
    setState(() {
      _status = message;
      _statusType = type;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: type == StatusType.error ? Colors.red :
                        type == StatusType.success ? Colors.green :
                        type == StatusType.warning ? Colors.orange : Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showConversionSuccessDialog(String outputPath, BookInfo book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('转换成功'),
        content: const Text('EPUB文件已生成，是否现在分享？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareFile(outputPath, book.title);
            },
            child: const Text('分享'),
          ),
        ],
      ),
    );
  }

  void _showBatchSuccessDialog(int successCount, int totalCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量转换完成'),
        content: Text('成功转换 $successCount 个文件，失败 ${totalCount - successCount} 个。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(String path, String title) async {
    await Share.shareXFiles(
      [XFile(path)],
      text: '$title.epub',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 批量模式切换
          SwitchListTile(
            title: const Text('批量转换模式'),
            subtitle: const Text('可同时选择多个TXT文件转换'),
            value: _isBatchMode,
            onChanged: _isConverting ? null : (value) {
              setState(() {
                _isBatchMode = value;
                _selectedFiles.clear();
                _titleController.clear();
                _status = '';
              });
            },
          ),
          const SizedBox(height: 16),

          // 文件选择
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  title: '选择文件',
                  icon: Icons.file_upload,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: _isBatchMode ? '选择多个TXT文件' : '选择TXT文件',
                  icon: Icons.file_open,
                  onPressed: _isConverting ? null : _pickTxtFiles,
                ),
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._selectedFiles.take(3).map((file) {
                    final filename = file.path.split(Platform.pathSeparator).last;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.description, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              filename,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_selectedFiles.length > 3)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '... 还有 ${_selectedFiles.length - 3} 个文件',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 封面选择
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  title: '书籍封面（可选）',
                  icon: Icons.image,
                ),
                const SizedBox(height: 16),
                if (_coverImageFile != null) ...[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _coverImageFile!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _coverImageFile!.path.split(Platform.pathSeparator).last,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextButton.icon(
                        onPressed: _isConverting ? null : _clearCoverImage,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('移除'),
                      ),
                    ],
                  ),
                ] else
                  CustomButton(
                    text: '选择封面图片',
                    icon: Icons.add_photo_alternate,
                    onPressed: _isConverting ? null : _pickCoverImage,
                  ),
                const SizedBox(height: 8),
                Text(
                  '支持格式：JPG、PNG、WEBP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 书籍信息
          if (!_isBatchMode)
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    title: '书籍信息',
                    icon: Icons.info,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _titleController,
                    labelText: '书籍标题',
                    hintText: '请输入书籍标题',
                    prefixIcon: const Icon(Icons.book),
                    enabled: !_isConverting,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _authorController,
                    labelText: '作者',
                    hintText: '请输入作者名称（可选）',
                    prefixIcon: const Icon(Icons.person),
                    enabled: !_isConverting,
                  ),
                ],
              ),
            ),
          if (!_isBatchMode) const SizedBox(height: 16),

          // 章节识别
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  title: '章节识别设置',
                  icon: Icons.format_list_numbered,
                ),
                const SizedBox(height: 16),
                const Text('识别模式：'),
                const SizedBox(height: 8),
                ...ChapterDetectionMode.values.map((mode) {
                  String title;
                  String subtitle;

                  switch (mode) {
                    case ChapterDetectionMode.auto:
                      title = '自动识别（推荐）';
                      subtitle = '自动检测中文、英文、数字编号等各种章节格式';
                      break;
                    case ChapterDetectionMode.chinese:
                      title = '中文格式（第X章）';
                      subtitle = '仅识别"第一章"、"第1回"等中文格式';
                      break;
                    case ChapterDetectionMode.numbered:
                      title = '数字编号（1. 标题）';
                      subtitle = '仅识别"1. 标题"等数字编号格式';
                      break;
                    case ChapterDetectionMode.english:
                      title = '英文格式（Chapter X）';
                      subtitle = '仅识别"Chapter 1"等英文格式';
                      break;
                    case ChapterDetectionMode.customSeparator:
                      title = '自定义分隔符';
                      subtitle = '使用指定的文本分割章节';
                      break;
                  }

                  return RadioListTile<ChapterDetectionMode>(
                    title: Text(title),
                    subtitle: Text(subtitle),
                    value: mode,
                    groupValue: _chapterDetectionMode,
                    onChanged: _isConverting
                        ? null
                        : (value) {
                            setState(() {
                              _chapterDetectionMode = value!;
                            });
                          },
                  );
                }),
                if (_chapterDetectionMode == ChapterDetectionMode.customSeparator) ...[
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _chapterSeparatorController,
                    labelText: '章节分隔符',
                    hintText: '输入用于分隔章节的文本',
                    helperText: '默认为三个换行符',
                    maxLines: 2,
                    enabled: !_isConverting,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 转换按钮
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomButton(
                  text: _isConverting ? '转换中...' : '开始转换',
                  icon: _isConverting ? null : Icons.convert_to_text_outlined,
                  isLoading: _isConverting,
                  onPressed: _convertToEpub,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_isConverting) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _progress,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}% 完成',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  StatusBanner(
                    message: _status,
                    type: _statusType,
                    onDismiss: () {
                      setState(() {
                        _status = '';
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 功能说明
          const CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: '功能说明',
                  icon: Icons.help,
                ),
                SizedBox(height: 12),
                Text('• 支持单文件和批量转换模式'),
                SizedBox(height: 4),
                Text('• 智能识别多种章节格式，支持中英文书籍'),
                SizedBox(height: 4),
                Text('• 生成标准EPUB 3格式，兼容所有主流阅读器'),
                SizedBox(height: 4),
                Text('• 自动优化封面图片尺寸和质量'),
                SizedBox(height: 4),
                Text('• 转换历史自动保存，随时查看和分享'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
