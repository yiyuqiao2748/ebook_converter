import 'package:flutter/material.dart';
import '../models/book_info.dart';
import '../utils/storage_service.dart';
import '../widgets/custom_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'system';
  ChapterDetectionMode _defaultChapterMode = ChapterDetectionMode.auto;
  String _defaultSeparator = '\n\n\n';
  bool _autoFillTitle = true;
  bool _saveToHistory = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final themeMode = await StorageService.getThemeMode();
    final chapterMode = await StorageService.getDefaultChapterMode();
    final separator = await StorageService.getDefaultSeparator();
    final autoFill = await StorageService.getAutoFillTitle();
    final saveHistory = await StorageService.getSaveToHistory();

    setState(() {
      _themeMode = themeMode;
      _defaultChapterMode = chapterMode;
      _defaultSeparator = separator;
      _autoFillTitle = autoFill;
      _saveToHistory = saveHistory;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await StorageService.saveThemeMode(_themeMode);
    await StorageService.saveDefaultChapterMode(_defaultChapterMode);
    await StorageService.saveDefaultSeparator(_defaultSeparator);
    await StorageService.saveAutoFillTitle(_autoFillTitle);
    await StorageService.saveSaveToHistory(_saveToHistory);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存')),
      );
      Navigator.pop(context);
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('system', '跟随系统', Icons.settings),
            _buildThemeOption('light', '浅色模式', Icons.light_mode),
            _buildThemeOption('dark', '深色模式', Icons.dark_mode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String value, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: _themeMode == value ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        setState(() {
          _themeMode = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showChapterModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('默认章节识别模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ChapterDetectionMode.values.map((mode) {
            String title;
            switch (mode) {
              case ChapterDetectionMode.auto:
                title = '自动识别';
                break;
              case ChapterDetectionMode.chinese:
                title = '中文格式';
                break;
              case ChapterDetectionMode.numbered:
                title = '数字编号';
                break;
              case ChapterDetectionMode.english:
                title = '英文格式';
                break;
              case ChapterDetectionMode.customSeparator:
                title = '自定义分隔符';
                break;
            }

            return ListTile(
              title: Text(title),
              trailing: _defaultChapterMode == mode
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _defaultChapterMode = mode;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: '电子书转换器',
      applicationVersion: '2.0.0',
      applicationIcon: const Icon(Icons.book, size: 48),
      children: const [
        SizedBox(height: 16),
        Text('一个功能强大的TXT转EPUB转换工具，支持智能章节识别、自定义封面、批量转换等功能。'),
        SizedBox(height: 8),
        Text('© 2024 yiyuqiao'),
      ],
    );
  }

  String _getThemeModeText() {
    switch (_themeMode) {
      case 'light':
        return '浅色模式';
      case 'dark':
        return '深色模式';
      case 'system':
      default:
        return '跟随系统';
    }
  }

  String _getChapterModeText() {
    switch (_defaultChapterMode) {
      case ChapterDetectionMode.auto:
        return '自动识别';
      case ChapterDetectionMode.chinese:
        return '中文格式';
      case ChapterDetectionMode.numbered:
        return '数字编号';
      case ChapterDetectionMode.english:
        return '英文格式';
      case ChapterDetectionMode.customSeparator:
        return '自定义分隔符';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: '外观设置',
                          icon: Icons.palette,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.brightness_6),
                          title: const Text('主题模式'),
                          subtitle: Text(_getThemeModeText()),
                          onTap: _showThemeDialog,
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: '转换设置',
                          icon: Icons.settings,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.format_list_numbered),
                          title: const Text('默认章节识别模式'),
                          subtitle: Text(_getChapterModeText()),
                          onTap: _showChapterModeDialog,
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                        const Divider(height: 1),
                        if (_defaultChapterMode == ChapterDetectionMode.customSeparator)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextFormField(
                              initialValue: _defaultSeparator,
                              decoration: const InputDecoration(
                                labelText: '默认分隔符',
                                border: OutlineInputBorder(),
                                helperText: '默认用于分割章节的文本',
                              ),
                              maxLines: 2,
                              onChanged: (value) {
                                setState(() {
                                  _defaultSeparator = value;
                                });
                              },
                            ),
                          ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(Icons.title),
                          title: const Text('自动填充书名'),
                          subtitle: const Text('从文件名自动提取书名'),
                          value: _autoFillTitle,
                          onChanged: (value) {
                            setState(() {
                              _autoFillTitle = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(Icons.history),
                          title: const Text('保存转换历史'),
                          subtitle: const Text('自动保存转换记录到历史列表'),
                          value: _saveToHistory,
                          onChanged: (value) {
                            setState(() {
                              _saveToHistory = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: '关于',
                          icon: Icons.info,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('版本信息'),
                          subtitle: const Text('2.0.0'),
                          onTap: _showAboutDialog,
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          leading: Icon(Icons.description),
                          title: Text('使用说明'),
                          subtitle: Text('查看功能介绍和使用教程'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          leading: Icon(Icons.feedback),
                          title: Text('意见反馈'),
                          subtitle: Text('报告问题或提出建议'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '保存设置',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
