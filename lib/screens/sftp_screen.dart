import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartssh2/dartssh2.dart' show SSHClient, SftpClient;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../theme/app_radius.dart';
import '../theme/glass_container.dart';
import '../widgets/widgets.dart';

/// SFTP file management panel
class SftpPanel extends ConsumerStatefulWidget {
  final TerminalTab tab;
  final SSHClient? sshClient;

  const SftpPanel({super.key, required this.tab, this.sshClient});

  @override
  ConsumerState<SftpPanel> createState() => _SftpPanelState();
}

class _SftpPanelState extends ConsumerState<SftpPanel> {
  String _currentPath = '~';
  List<SftpFile> _files = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _selectedFiles = {};
  SftpClient? _sftpClient;
  bool _isDragging = false;
  ProviderSubscription<String?>? _sshDirSub;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.tab.currentDirectory;
    _initSftp();
    _sshDirSub = ref.listenManual<String?>(sshDirectoryProvider, (prev, next) {
      if (next != null && mounted) {
        final settings = ref.read(appSettingsProvider);
        if (settings.followSshDirectory) {
          navigateToPath(next);
        }
      }
    });
  }

  @override
  void dispose() {
    _sshDirSub?.close();
    super.dispose();
  }

  Future<void> _initSftp() async {
    try {
      final sshClient = widget.sshClient;
      if (sshClient == null) {
        setState(() { _isLoading = false; _errorMessage = 'SSH 未就绪'; });
        return;
      }
      _sftpClient = await sshClient.sftp();
      _loadFiles();
    } catch (e) {
      setState(() { _errorMessage = 'SFTP 初始化失败: $e'; });
    }
  }

  @override
  void didUpdateWidget(SftpPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.currentDirectory != _currentPath) {
      _currentPath = widget.tab.currentDirectory;
      _loadFiles();
    }
    if (widget.sshClient != oldWidget.sshClient) {
      _sftpClient = null;
      if (widget.sshClient != null) {
        _initSftp();
      } else {
        setState(() { _isLoading = false; _errorMessage = 'SSH 客户端未就绪'; });
      }
    }
  }

  Future<void> _loadFiles() async {
    setState(() { _isLoading = true; _errorMessage = null; _selectedFiles.clear(); });
    try {
      final sshClient = widget.sshClient;
      if (sshClient == null) throw Exception('SSH 未连接');
      if (_sftpClient == null) _sftpClient = await sshClient.sftp();
      final resolvedPath = await _resolvePath(_currentPath);
      final sftpService = SftpService(_sftpClient!);
      final allFiles = await sftpService.listDirectory(resolvedPath);
      final files = allFiles.where((f) => f.name != '.' && f.name != '..').toList();
      files.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      setState(() { _files = files; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = e.toString(); });
    }
  }

  void _navigateUp() {
    if (_currentPath == '/') return;
    final parts = _currentPath.split('/');
    parts.removeLast();
    final newPath = parts.isEmpty ? '/' : parts.join('/');
    setState(() { _currentPath = newPath; });
    _loadFiles();
    ref.read(terminalTabsProvider.notifier).updateCurrentDirectory(widget.tab.id, _currentPath);
  }

  void _navigateTo(String path) {
    setState(() { _currentPath = path; });
    _loadFiles();
    ref.read(terminalTabsProvider.notifier).updateCurrentDirectory(widget.tab.id, _currentPath);
  }

  void navigateToPath(String path) {
    setState(() { _currentPath = path; });
    _loadFiles();
  }

  Future<String> _resolvePath(String path) async {
    if (path == '~' || path.startsWith('~/')) {
      try {
        final sshClient = widget.sshClient;
        if (sshClient == null) return path;
        final result = await sshClient.run('echo -n \$HOME');
        final homeDir = String.fromCharCodes(result).trim();
        return path == '~' ? homeDir : '$homeDir/${path.substring(2)}';
      } catch (e) {
        return path == '~' ? '/root' : '/root/${path.substring(2)}';
      }
    }
    return path;
  }

  void _enterDirectory(SftpFile file) {
    if (!file.isDirectory) return;
    setState(() { _currentPath = file.path; });
    _loadFiles();
    ref.read(terminalTabsProvider.notifier).updateCurrentDirectory(widget.tab.id, _currentPath);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildToolbar(),
      const SizedBox(height: 1),
      _buildPathBreadcrumb(),
      Expanded(
        child: DropTarget(
          onDragDone: _onDropFiles,
          onDragEntered: (_) => setState(() { _isDragging = true; }),
          onDragExited: (_) => setState(() { _isDragging = false; }),
          child: Container(
            decoration: _isDragging ? BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2)) : null,
            child: _buildFileListView(),
          ),
        ),
      ),
      _buildStatusBar(),
    ]);
  }

  Widget _buildFileListView() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: AppStyles.spacingMedium),
        Text(_errorMessage!, style: AppStyles.bodyMedium),
        const SizedBox(height: AppStyles.spacingMedium),
        ElevatedButton.icon(onPressed: _loadFiles, icon: const Icon(Icons.refresh), label: const Text('重试')),
      ]));
    }
    if (_files.isEmpty) return const Center(child: Text('空目录'));
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final isSelected = _selectedFiles.contains(file.path);
        return FileListTile(
          file: file, isSelected: isSelected,
          onTap: () { if (file.isDirectory) _enterDirectory(file); else _toggleSelection(file); },
          onLongPress: () => _toggleSelection(file),
          onMorePressed: (details) => _showFileOptions(file, details),
        );
      },
    );
  }

  Widget _buildToolbar() {
    return GlassContainer.toolbar(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_upward, size: 20), tooltip: '上级', onPressed: _currentPath == '/' ? null : _navigateUp),
        IconButton(icon: const Icon(Icons.refresh, size: 20), tooltip: '刷新', onPressed: _loadFiles),
        const VerticalDivider(width: 1),
        IconButton(icon: const Icon(Icons.upload, size: 20), tooltip: '上传文件', onPressed: _uploadFiles),
        IconButton(icon: const Icon(Icons.drive_folder_upload, size: 20), tooltip: '上传文件夹', onPressed: _uploadFolder),
        const VerticalDivider(width: 1),
        IconButton(icon: const Icon(Icons.create_new_folder, size: 20), tooltip: '新建文件夹', onPressed: _showCreateFolderDialog),
        IconButton(icon: const Icon(Icons.note_add, size: 20), tooltip: '新建文件', onPressed: _showCreateFileDialog),
        const VerticalDivider(width: 1),
        Builder(builder: (context) {
          final settings = ref.watch(appSettingsProvider);
          return IconButton(
            icon: Icon(Icons.sync, size: 20, color: settings.followSshDirectory ? Theme.of(context).colorScheme.primary : null),
            tooltip: settings.followSshDirectory ? '跟随 SSH: 开' : '跟随 SSH: 关',
            onPressed: () => ref.read(appSettingsProvider.notifier).toggleFollowSshDirectory(),
          );
        }),
        const Spacer(),
        if (_selectedFiles.isNotEmpty) Text('已选 ${_selectedFiles.length} 项', style: AppStyles.bodySmall),
      ]),
    );
  }

  Widget _buildPathBreadcrumb() {
    final parts = _currentPath.split('/');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingSmall, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border.symmetric(
          horizontal: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        ),
      ),
      child: Row(children: [
        GestureDetector(onTap: () => _navigateTo('/'), child: const Icon(Icons.home, size: 16)),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
            children: List.generate(parts.length, (index) {
              final path = parts.sublist(0, index + 1).join('/');
              final name = parts[index];
              if (name.isEmpty) return const SizedBox.shrink();
              return Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chevron_right, size: 16),
                GestureDetector(
                  onTap: () => _navigateTo(path.isEmpty ? '/' : path),
                  child: Text(name, style: AppStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.primary)),
                ),
              ]);
            }),
          )),
        ),
      ]),
    );
  }

  Widget _buildStatusBar() {
    return GlassContainer.toolbar(
      padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingSmall, vertical: AppStyles.spacingExtraSmall),
      child: Row(children: [
        Text('${_files.length} 项', style: AppStyles.caption),
        const Spacer(),
        Text(_currentPath, style: AppStyles.caption, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  void _toggleSelection(SftpFile file) {
    setState(() {
      if (_selectedFiles.contains(file.path)) _selectedFiles.remove(file.path);
      else _selectedFiles.add(file.path);
    });
  }

  Future<void> _uploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null || result.files.isEmpty) return;
      final sftpService = SftpService(_sftpClient!);
      for (final file in result.files) {
        if (file.path == null) continue;
        final remotePath = '$_currentPath/${file.name}';
        if (mounted) {
          showDialog(context: context, barrierDismissible: false, builder: (context) =>
            _UploadProgressDialog(fileName: file.name, onUpload: (onProgress) async {
              await sftpService.uploadFile(file.path!, remotePath, onProgress: onProgress);
            }));
        }
      }
      _loadFiles();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('上传失败: $e')));
    }
  }

  Future<void> _uploadFolder() async {
    try {
      final directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) return;
      final folderName = directoryPath.split(Platform.pathSeparator).last;
      final remotePath = '$_currentPath/$folderName';
      final sftpService = SftpService(_sftpClient!);
      if (mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (context) =>
          _UploadProgressDialog(fileName: '$folderName/', onUpload: (onProgress) async {
            await sftpService.uploadDirectory(directoryPath, remotePath, onProgress: (name, current, total) => onProgress(current, total));
          }));
      }
      _loadFiles();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('上传失败: $e')));
    }
  }

  Future<void> _downloadSelected() async {
    try {
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return;
      final sftpService = SftpService(_sftpClient!);
      for (final filePath in _selectedFiles) {
        final fileName = filePath.split('/').last;
        final localPath = '$directory${Platform.pathSeparator}$fileName';
        if (mounted) {
          showDialog(context: context, barrierDismissible: false, builder: (context) =>
            _DownloadProgressDialog(fileName: fileName, onDownload: (onProgress) async {
              await sftpService.downloadFile(filePath, localPath, onProgress: onProgress);
            }));
        }
      }
      setState(() { _selectedFiles.clear(); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下载完成')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下载失败: $e')));
    }
  }

  Future<void> _downloadSingleFile(SftpFile file) async {
    try {
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return;
      final localPath = '$directory${Platform.pathSeparator}${file.name}';
      final sftpService = SftpService(_sftpClient!);
      if (mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (context) =>
          _DownloadProgressDialog(fileName: file.name, onDownload: (onProgress) async {
            await sftpService.downloadFile(file.path, localPath, onProgress: onProgress);
          }));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下载失败: $e')));
    }
  }

  Future<void> _downloadDirectory(SftpFile folder) async {
    try {
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return;
      final localPath = '$directory${Platform.pathSeparator}${folder.name}';
      final sftpService = SftpService(_sftpClient!);
      if (mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (context) =>
          _DownloadProgressDialog(fileName: '${folder.name}/', onDownload: (onProgress) async {
            await sftpService.downloadDirectory(folder.path, localPath, onProgress: (name, current, total) => onProgress(current, total));
          }));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下载失败: $e')));
    }
  }

  void _openInTerminal() {
    final session = ref.read(activeSessionsProvider).getSession(widget.tab.id);
    if (session != null) {
      final path = _currentPath.startsWith('/') ? _currentPath : '$_currentPath';
      session.write(utf8.encode('cd $path\n'));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已切换到 $path')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SSH 会话未连接')));
    }
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('新建文件夹'),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: '文件夹名'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () async { final name = controller.text.trim(); if (name.isNotEmpty) await _createFolder(name); Navigator.pop(context); }, child: const Text('创建')),
      ],
    ));
  }

  Future<void> _createFolder(String name) async {
    try {
      final sftpService = SftpService(_sftpClient!);
      await sftpService.createDirectory('$_currentPath/$name');
      _loadFiles();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败: $e')));
    }
  }

  void _showCreateFileDialog() {
    final controller = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('新建文件'),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: '文件名'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () async { final name = controller.text.trim(); if (name.isNotEmpty) await _createFile(name); Navigator.pop(context); }, child: const Text('创建')),
      ],
    ));
  }

  Future<void> _createFile(String name) async {
    try {
      final sftpService = SftpService(_sftpClient!);
      await sftpService.writeFile('$_currentPath/$name', Uint8List(0));
      _loadFiles();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败: $e')));
    }
  }

  void _showFileOptions(SftpFile file, Offset position) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        padding: EdgeInsets.zero,
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          _buildMenuTile(Icons.info_outline, '属性', () { Navigator.pop(context); _showFileProperties(file); }),
          if (file.isDirectory)
            _buildMenuTile(Icons.download, '下载文件夹', () { Navigator.pop(context); _downloadDirectory(file); })
          else
            _buildMenuTile(Icons.download, '下载文件', () { Navigator.pop(context); _downloadSingleFile(file); }),
          if (!file.isDirectory) _buildMenuTile(Icons.edit, '编辑', () { Navigator.pop(context); _showFileEditor(file); }),
          _buildMenuTile(Icons.edit, '重命名', () { Navigator.pop(context); _showRenameDialog(file); }),
          _buildMenuTile(Icons.vpn_key, '权限设置', () { Navigator.pop(context); _showChmodDialog(file); }),
          _buildMenuTile(Icons.copy, '复制路径', () { Navigator.pop(context); Clipboard.setData(ClipboardData(text: file.path)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('路径已复制'))); }),
          _buildMenuTile(Icons.terminal, '在终端中打开', () { Navigator.pop(context); _openInTerminal(); }),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuTile(Icons.delete, '删除', () { Navigator.pop(context); _showDeleteConfirmation(file); }, isDestructive: true),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null, size: 20),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _showFileEditor(SftpFile file) async {
    try {
      final sftpService = SftpService(_sftpClient!);
      final content = await sftpService.readFile(file.path);
      String textContent;
      try {
        textContent = utf8.decode(content);
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法编辑二进制文件')));
        return;
      }
      if (mounted) _showEditorDialog(file, textContent);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('读取文件失败: $e')));
    }
  }

  void _showEditorDialog(SftpFile file, String initialContent) {
    final controller = TextEditingController(text: initialContent);
    final language = _detectLanguage(file.name);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Row(children: [
        Expanded(child: Text(file.name, overflow: TextOverflow.ellipsis)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(4)),
          child: Text(language, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
        ),
      ]),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: TextField(
          controller: controller, maxLines: null, expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
          cursorColor: Theme.of(context).colorScheme.primary,
          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12), filled: false),
          keyboardType: TextInputType.multiline,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          try {
            await SftpService(_sftpClient!).writeFile(file.path, utf8.encode(controller.text));
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
          }
        }, child: const Text('保存')),
      ],
    ));
  }

  String _detectLanguage(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart': return 'Dart';
      case 'js': return 'JavaScript';
      case 'ts': return 'TypeScript';
      case 'py': return 'Python';
      case 'java': return 'Java';
      case 'cpp': case 'c': case 'h': return 'C/C++';
      case 'go': return 'Go';
      case 'rs': return 'Rust';
      case 'rb': return 'Ruby';
      case 'php': return 'PHP';
      case 'sh': case 'bash': return 'Shell';
      case 'yaml': case 'yml': return 'YAML';
      case 'json': return 'JSON';
      case 'xml': case 'html': case 'htm': return 'HTML';
      case 'css': return 'CSS';
      case 'md': return 'Markdown';
      case 'sql': return 'SQL';
      case 'txt': return 'Text';
      case 'log': return 'Log';
      case 'conf': case 'cfg': case 'ini': return 'Config';
      default: return 'Text';
    }
  }

  /// 构建语法高亮 TextSpan
  TextSpan _buildHighlightedText(String code, String lang) {
    final keywords = <String, List<String>>{
      'Dart': ['import','class','void','final','const','var','if','else','for','while','return','async','await','Future','true','false','null','this','super','static','new','throw','try','catch','String','int','bool','double','List','Map','Set','dynamic'],
      'JavaScript': ['import','export','const','let','var','function','class','if','else','for','while','return','async','await','try','catch','throw','new','this','true','false','null','undefined','typeof'],
      'TypeScript': ['import','export','const','let','var','function','class','interface','type','if','else','for','while','return','async','await','try','catch','throw','new','true','false','null','undefined'],
      'Python': ['import','def','class','if','elif','else','for','while','return','try','except','finally','raise','with','as','from','lambda','pass','break','continue','True','False','None','and','or','not','in','is'],
      'Java': ['import','class','public','private','protected','static','void','if','else','for','while','return','try','catch','throw','new','this','super','true','false','null','int','String','boolean','double','float','long'],
      'Shell': ['if','then','else','elif','fi','for','while','do','done','case','esac','function','return','exit','export','source','local','echo','cd','rm','mv','cp','ls','cat','grep','awk','sed','chmod','mkdir'],
      'YAML': ['true','false','null','yes','no','on','off'],
    };
    final langKeywords = keywords[lang] ?? <String>[];
    final spans = <TextSpan>[];
    final lines = code.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      String line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//') || trimmed.startsWith('#') || trimmed.startsWith('/*')) {
        spans.add(TextSpan(text: line, style: const TextStyle(color: Color(0xFF6B7280)))); continue;
      }
      final words = line.split(RegExp(r'(\s+)'));
      for (final word in words) {
        if (word.startsWith('"') || word.startsWith("'")) {
          spans.add(TextSpan(text: word, style: const TextStyle(color: Color(0xFF34D399))));
        } else if (langKeywords.contains(word.trim())) {
          spans.add(TextSpan(text: word, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)));
        } else if (RegExp(r'^\d+\.?\d*$').hasMatch(word.trim())) {
          spans.add(TextSpan(text: word, style: const TextStyle(color: Color(0xFFF59E0B))));
        } else {
          spans.add(TextSpan(text: word));
        }
      }
    }
    return TextSpan(children: spans);
  }

  void _onDropFiles(DropDoneDetails details) async {
    setState(() { _isDragging = false; });
    if (_sftpClient == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SFTP 未连接'))); return; }
    final sftpService = SftpService(_sftpClient!);
    for (final file in details.files) {
      final localPath = file.path;
      if (localPath.isEmpty) continue;
      final remotePath = '$_currentPath/${file.name}';
      if (mounted) {
        showDialog(context: context, barrierDismissible: false, builder: (context) =>
          _UploadProgressDialog(fileName: file.name, onUpload: (onProgress) async { await sftpService.uploadFile(localPath, remotePath, onProgress: onProgress); }));
      }
    }
    _loadFiles();
  }

  void _showChmodDialog(SftpFile file) {
    int mode = file.permissions & 0x1FF;
    bool ownerRead = (mode & 0x100) != 0, ownerWrite = (mode & 0x80) != 0, ownerExecute = (mode & 0x40) != 0;
    bool groupRead = (mode & 0x20) != 0, groupWrite = (mode & 0x10) != 0, groupExecute = (mode & 0x08) != 0;
    bool otherRead = (mode & 0x04) != 0, otherWrite = (mode & 0x02) != 0, otherExecute = (mode & 0x01) != 0;
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
      int buildMode() {
        int m = 0;
        if (ownerRead) m |= 0x100; if (ownerWrite) m |= 0x80; if (ownerExecute) m |= 0x40;
        if (groupRead) m |= 0x20; if (groupWrite) m |= 0x10; if (groupExecute) m |= 0x08;
        if (otherRead) m |= 0x04; if (otherWrite) m |= 0x02; if (otherExecute) m |= 0x01;
        return m;
      }
      String modeString(int m) => '${(m >> 6) & 7}${(m >> 3) & 7}${m & 7}';
      Widget buildPermissionRow(String label, bool read, bool write, bool execute, ValueChanged<bool> onReadChanged, ValueChanged<bool> onWriteChanged, ValueChanged<bool> onExecuteChanged) {
        return Row(children: [
          SizedBox(width: 60, child: Text(label, style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold))),
          Checkbox(value: read, onChanged: (v) => setDialogState(() => onReadChanged(v ?? false))),
          Text('r', style: AppStyles.bodySmall), const SizedBox(width: 8),
          Checkbox(value: write, onChanged: (v) => setDialogState(() => onWriteChanged(v ?? false))),
          Text('w', style: AppStyles.bodySmall), const SizedBox(width: 8),
          Checkbox(value: execute, onChanged: (v) => setDialogState(() => onExecuteChanged(v ?? false))),
          Text('x', style: AppStyles.bodySmall),
        ]);
      }
      return AlertDialog(
        title: Text('权限 - ${file.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('当前: ${modeString(file.permissions & 0x1FF)} → ${modeString(buildMode())}', style: AppStyles.bodySmall),
          const SizedBox(height: 12),
          buildPermissionRow('所有者', ownerRead, ownerWrite, ownerExecute, (v) => ownerRead = v, (v) => ownerWrite = v, (v) => ownerExecute = v),
          buildPermissionRow('用户组', groupRead, groupWrite, groupExecute, (v) => groupRead = v, (v) => groupWrite = v, (v) => groupExecute = v),
          buildPermissionRow('其他', otherRead, otherWrite, otherExecute, (v) => otherRead = v, (v) => otherWrite = v, (v) => otherExecute = v),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _chmodFile(file, buildMode()); }, child: const Text('确定')),
        ],
      );
    }));
  }

  Future<void> _chmodFile(SftpFile file, int mode) async {
    try {
      final sftpService = SftpService(_sftpClient!);
      await sftpService.chmod(file.path, mode);
      _loadFiles();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('权限修改失败: $e')));
    }
  }

  void _showFileProperties(SftpFile file) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(file.name),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildPropertyRow('路径', file.path),
        _buildPropertyRow('大小', file.readableSize),
        _buildPropertyRow('类型', file.isDirectory ? '目录' : '文件'),
        _buildPropertyRow('权限', file.permissionsString),
        _buildPropertyRow('修改时间', file.modifyTime.toString()),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
    ));
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text('$label:', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold))),
      Expanded(child: Text(value, style: AppStyles.bodySmall)),
    ]));
  }

  void _showRenameDialog(SftpFile file) {
    final controller = TextEditingController(text: file.name);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('重命名'),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: '新名称'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () async { final newName = controller.text.trim(); if (newName.isNotEmpty && newName != file.name) await _renameFile(file, newName); Navigator.pop(context); }, child: const Text('确定')),
      ],
    ));
  }

  Future<void> _renameFile(SftpFile file, String newName) async {
    try {
      final sftpService = SftpService(_sftpClient!);
      final parentPath = file.path.substring(0, file.path.lastIndexOf('/'));
      await sftpService.rename(file.path, '$parentPath/$newName');
      _loadFiles();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重命名失败: $e')));
    }
  }

  void _showDeleteConfirmation(SftpFile file) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('确认删除'),
      content: Text('确认删除 "${file.name}"？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async { await _deleteFile(file); Navigator.pop(context); }, child: const Text('删除')),
      ],
    ));
  }

  Future<void> _deleteFile(SftpFile file) async {
    try {
      final sftpService = SftpService(_sftpClient!);
      await sftpService.delete(file.path, recursive: file.isDirectory);
      _loadFiles();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }
}

class _UploadProgressDialog extends StatefulWidget {
  final String fileName;
  final Future<void> Function(Function(int, int) onProgress) onUpload;
  const _UploadProgressDialog({required this.fileName, required this.onUpload});
  @override
  State<_UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<_UploadProgressDialog> {
  double _progress = 0;
  String? _error;
  @override
  void initState() { super.initState(); _startUpload(); }
  Future<void> _startUpload() async {
    try {
      await widget.onUpload((transferred, total) { if (mounted) setState(() { _progress = total > 0 ? transferred / total : 0; }); });
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) setState(() { _error = e.toString(); }); }
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('上传中'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.fileName), const SizedBox(height: AppStyles.spacingMedium),
        LinearProgressIndicator(value: _progress), const SizedBox(height: AppStyles.spacingSmall),
        Text('${(_progress * 100).toStringAsFixed(1)}%'),
        if (_error != null) ...[const SizedBox(height: AppStyles.spacingMedium), Text(_error!, style: const TextStyle(color: Colors.red))],
      ]),
      actions: [if (_error != null) TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final String fileName;
  final Future<void> Function(Function(int, int) onProgress) onDownload;
  const _DownloadProgressDialog({required this.fileName, required this.onDownload});
  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0;
  String? _error;
  @override
  void initState() { super.initState(); _startDownload(); }
  Future<void> _startDownload() async {
    try {
      await widget.onDownload((transferred, total) { if (mounted) setState(() { _progress = total > 0 ? transferred / total : 0; }); });
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) setState(() { _error = e.toString(); }); }
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('下载中'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.fileName), const SizedBox(height: AppStyles.spacingMedium),
        LinearProgressIndicator(value: _progress), const SizedBox(height: AppStyles.spacingSmall),
        Text('${(_progress * 100).toStringAsFixed(1)}%'),
        if (_error != null) ...[const SizedBox(height: AppStyles.spacingMedium), Text(_error!, style: const TextStyle(color: Colors.red))],
      ]),
      actions: [if (_error != null) TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
    );
  }
}
