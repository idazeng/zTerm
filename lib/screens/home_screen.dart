import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

/// Main screen - manages tabs and layout
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkMasterPassword();
  }

  Future<void> _checkMasterPassword() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final isSet = await secureStorage.isMasterPasswordSet();
    ref.read(masterPasswordSetProvider.notifier).state = isSet;
    ref.read(appSettingsProvider.notifier).setMasterPasswordFlag(isSet);
    if (!isSet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMasterPasswordSetupDialog();
      });
    }
  }

  void _showMasterPasswordSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MasterPasswordDialog(isSetup: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(terminalTabsProvider);
    final activeTabId = ref.watch(activeTabIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('zTerm'),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: '新建连接', onPressed: _showNewConnectionDialog),
          IconButton(icon: const Icon(Icons.tab), tooltip: '新建标签', onPressed: _showNewTabDialog),
          IconButton(icon: const Icon(Icons.settings), tooltip: '设置', onPressed: _showSettingsScreen),
          IconButton(icon: const Icon(Icons.sync), tooltip: '同步', onPressed: _syncData),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'hosts', child: ListTile(leading: Icon(Icons.dns), title: Text('主机管理'))),
              const PopupMenuItem(value: 'snippets', child: ListTile(leading: Icon(Icons.code), title: Text('命令片段'))),
              const PopupMenuItem(value: 'import', child: ListTile(leading: Icon(Icons.upload), title: Text('导入'))),
              const PopupMenuItem(value: 'export', child: ListTile(leading: Icon(Icons.download), title: Text('导出'))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'about', child: ListTile(leading: Icon(Icons.info), title: Text('关于'))),
            ],
          ),
        ],
      ),
      body: Column(children: [
        if (tabs.isNotEmpty) _buildTabBar(tabs, activeTabId),
        Expanded(child: tabs.isEmpty ? _buildEmptyState() : _buildTabContent(tabs, activeTabId)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    final connections = ref.watch(connectionsProvider);
    return Center(
      child: connections.isEmpty ? _buildNoConnectionsView() : _buildConnectionsList(connections),
    );
  }

  Widget _buildNoConnectionsView() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.computer, size: 100, color: Colors.grey.withOpacity(0.3)),
      const SizedBox(height: AppStyles.spacingLarge),
      Text('暂无连接', style: AppStyles.titleLarge.copyWith(color: Colors.grey)),
      const SizedBox(height: AppStyles.spacingSmall),
      Text('点击 + 创建连接', style: AppStyles.bodyMedium.copyWith(color: Colors.grey)),
      const SizedBox(height: AppStyles.spacingExtraLarge),
      ElevatedButton.icon(onPressed: _showNewConnectionDialog, icon: const Icon(Icons.add), label: const Text('新建连接')),
    ]);
  }

  Widget _buildConnectionsList(List<ConnectionProfile> connections) {
    final Map<String, List<ConnectionProfile>> grouped = {};
    final List<ConnectionProfile> ungrouped = [];
    for (final conn in connections) {
      final group = conn.groupName;
      if (group != null && group.isNotEmpty) {
        grouped.putIfAbsent(group, () => []).add(conn);
      } else {
        ungrouped.add(conn);
      }
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          const Icon(Icons.dns, size: 20),
          const SizedBox(width: 8),
          Text('主机列表 (${connections.length})', style: AppStyles.titleMedium),
          const Spacer(),
          TextButton.icon(onPressed: _showNewConnectionDialog, icon: const Icon(Icons.add, size: 18), label: const Text('新建')),
        ]),
      ),
      const Divider(height: 1),
      Expanded(child: ListView(children: [
        for (final entry in grouped.entries) ...[
          _buildGroupHeader(entry.key, entry.value.length),
          if (_expandedGroups.contains(entry.key))
            for (final conn in entry.value) _buildConnectionTile(conn),
        ],
        if (ungrouped.isNotEmpty && grouped.isNotEmpty) _buildGroupHeader('未分组', ungrouped.length),
        if (_expandedGroups.contains('未分组') || !grouped.isNotEmpty)
          for (final conn in ungrouped) _buildConnectionTile(conn),
      ])),
    ]);
  }

  Widget _buildGroupHeader(String groupName, int count) {
    final isExpanded = _expandedGroups.contains(groupName);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedGroups.remove(groupName);
          } else {
            _expandedGroups.add(groupName);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        child: Row(children: [
          Icon(isExpanded ? Icons.expand_more : Icons.chevron_right, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(groupName, style: AppStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text('($count)', style: AppStyles.bodySmall.copyWith(color: Colors.grey)),
        ]),
      ),
    );
  }

  final Set<String> _expandedGroups = {};

  Widget _buildConnectionTile(ConnectionProfile conn) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(Icons.computer, color: Theme.of(context).colorScheme.primary, size: 20)),
      title: Text(conn.name),
      subtitle: Text(conn.notes?.isNotEmpty == true ? '${conn.displayHost}  ·  ${conn.notes}' : conn.displayHost, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'edit') {
            showDialog(context: context, builder: (context) => ConnectionEditDialog(connection: conn));
          } else if (value == 'delete') {
            _confirmDeleteConnection(conn);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('编辑'))),
          const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('删除', style: TextStyle(color: Colors.red)))),
        ],
      ),
      onTap: () => _createNewTab(conn),
    );
  }

  void _confirmDeleteConnection(ConnectionProfile conn) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('删除连接'),
      content: Text('Delete "${conn.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(onPressed: () { Navigator.pop(context); ref.read(connectionsProvider.notifier).deleteConnection(conn.id); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  Widget _buildTabContent(List<TerminalTab> tabs, String? activeTabId) {
    final activeTab = tabs.firstWhere((t) => t.id == activeTabId, orElse: () => tabs.first);
    return TerminalScaffold(tab: activeTab);
  }

  Widget _buildTabBar(List<TerminalTab> tabs, String? activeTabId) {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = tab.id == activeTabId;
          return GestureDetector(
            onTap: () => ref.read(activeTabIdProvider.notifier).state = tab.id,
            onLongPress: () => _showTabOptions(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacingLarge),
              decoration: BoxDecoration(border: Border(right: BorderSide(color: Theme.of(context).dividerColor), top: BorderSide(color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(tab.title, style: TextStyle(color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                const SizedBox(width: AppStyles.spacingSmall),
                GestureDetector(onTap: () => _closeTab(tab.id), child: Icon(Icons.close, size: 16, color: Theme.of(context).textTheme.bodySmall?.color)),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _showNewConnectionDialog() {
    final masterPasswordSet = ref.read(masterPasswordSetProvider);
    if (!masterPasswordSet) {
      showDialog(context: context, builder: (context) => AlertDialog(
        title: const Text('请先设置主密码'),
        content: const Text('You need to set a master password to protect sensitive data'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(onPressed: () { Navigator.pop(context); showDialog(context: context, builder: (context) => const MasterPasswordDialog(isSetup: true)); }, child: const Text('设置')),
        ],
      ));
      return;
    }
    showDialog(context: context, builder: (context) => const ConnectionEditDialog());
  }

  void _showNewTabDialog() {
    final connections = ref.read(connectionsProvider);
    if (connections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a connection first')));
      return;
    }
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('选择连接'),
      content: SizedBox(width: double.maxFinite, child: ListView.builder(
        shrinkWrap: true,
        itemCount: connections.length,
        itemBuilder: (context, index) {
          final conn = connections[index];
          return ListTile(leading: const Icon(Icons.computer), title: Text(conn.name), subtitle: Text(conn.displayHost), onTap: () { Navigator.pop(context); _createNewTab(conn); });
        },
      )),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消'))],
    ));
  }

  Future<void> _createNewTab(dynamic connection) async {
    final tab = TerminalTab(connectionId: connection.id, title: connection.name);
    ref.read(terminalTabsProvider.notifier).addTab(tab);
    ref.read(activeTabIdProvider.notifier).state = tab.id;
  }

  void _closeTab(String tabId) {
    ref.read(terminalTabsProvider.notifier).removeTab(tabId);
    final tabs = ref.read(terminalTabsProvider);
    if (tabs.isNotEmpty) ref.read(activeTabIdProvider.notifier).state = tabs.first.id;
  }

  void _showTabOptions(TerminalTab tab) {
    showModalBottomSheet(context: context, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.edit), title: const Text('Rename'), onTap: () { Navigator.pop(context); _showRenameTabDialog(tab); }),
      ListTile(leading: const Icon(Icons.close, color: Colors.red), title: const Text('Close', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); _closeTab(tab.id); }),
    ])));
  }

  void _showRenameTabDialog(TerminalTab tab) {
    final controller = TextEditingController(text: tab.title);
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('重命名标签'),
      content: TextField(controller: controller, decoration: const InputDecoration(labelText: '标签名称'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () { final newTitle = controller.text.trim(); if (newTitle.isNotEmpty) ref.read(terminalTabsProvider.notifier).updateTab(tab.copyWith(title: newTitle)); Navigator.pop(context); }, child: const Text('确定')),
      ],
    ));
  }

  void _showSettingsScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'hosts': Navigator.push(context, MaterialPageRoute(builder: (context) => const HostManageScreen())); break;
      case 'snippets': Navigator.push(context, MaterialPageRoute(builder: (context) => const SnippetsScreen())); break;
      case 'import': _showImportDialog(); break;
      case 'export': _showExportDialog(); break;
      case 'about': Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())); break;
    }
  }

  void _showSyncDialog() {
    final settings = ref.read(appSettingsProvider);
    if (settings.webdavUrl == null || settings.webdavUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先在设置中配置 WebDAV')));
      return;
    }
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('WebDAV 同步'),
      content: const Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: Icon(Icons.sync), title: Text('同步数据'), subtitle: Text('Merge local and cloud data.\nSame ID keeps latest version.\nDifferent IDs are merged.')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () async { Navigator.pop(context); await _syncData(); }, child: const Text('同步')),
      ],
    ));
  }

  /// Sync data: merge local and cloud, same ID keep latest, different IDs merge
  Future<void> _syncData() async {
    try {
      final settings = ref.read(appSettingsProvider);
      if (settings.webdavUrl == null || settings.webdavUrl!.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configure WebDAV in Settings first')));
        return;
      }
      final dbService = ref.read(databaseServiceProvider);
      final secureStorage = ref.read(secureStorageServiceProvider);
      final syncService = WebdavSyncService(dbService, secureStorage);
      final webdavPassword = settings.webdavPassword ?? '';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing...'), duration: Duration(seconds: 1)));
      await syncService.initialize(
        url: settings.webdavUrl!,
        username: settings.webdavUsername ?? '',
        password: webdavPassword,
        subdirectory: settings.webdavSubdirectory,
      );
      final summary = await syncService.sync();
      syncService.disconnect();
      ref.read(connectionsProvider.notifier).refresh();
      ref.read(snippetsProvider.notifier).refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('同步完成: $summary')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('同步失败: $e')));
    }
  }

  void _showImportDialog() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json', 'txt'], dialogTitle: 'Select host config file');
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.first.path!);
      final fileBytes = await file.readAsBytes();
      String content;
      try {
        // 先检查 BOM (UTF-8 BOM: EF BB BF)
        if (fileBytes.length >= 3 && fileBytes[0] == 0xEF && fileBytes[1] == 0xBB && fileBytes[2] == 0xBF) {
          content = utf8.decode(fileBytes.sublist(3));
        } else {
          content = utf8.decode(fileBytes);
        }
      } catch (_) {
        // UTF-8 解析失败，尝试系统默认编码（中文 Windows 的 GBK）
        try {
          content = SystemEncoding().decode(fileBytes);
        } catch (_) {
          // 最后尝试 Latin-1（不丢失字节）
          content = String.fromCharCodes(fileBytes);
        }
      }
      int importedCount = 0;
      final connectionsNotifier = ref.read(connectionsProvider.notifier);

      // 尝试 JSON 格式
      try {
        final List<dynamic> jsonList = jsonDecode(content);
        for (final json in jsonList) {
          try {
            final profile = ConnectionProfile.fromJson(Map<String, dynamic>.from(json));
            final newProfile = ConnectionProfile(name: profile.name, host: profile.host, port: profile.port, username: profile.username, authType: profile.authType, groupName: profile.groupName, notes: profile.notes);
            // 保存密码
            if (profile.password != null && profile.password!.isNotEmpty) {
              await ref.read(secureStorageServiceProvider).storePassword(newProfile.id, profile.password!);
            }
            await connectionsNotifier.addConnection(newProfile);
            importedCount++;
          } catch (e) { continue; }
        }
      } catch (_) {
        // JSON 解析失败，尝试纯文本格式
        final lines = content.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final parts = trimmed.replaceAll('，', ',').split(',');
          if (parts.length < 5) continue;
          try {
            final name = parts[0].trim();
            final host = parts[1].trim();
            final port = int.tryParse(parts[2].trim()) ?? 22;
            final username = parts[3].trim();
            final authType = parts[4].trim().toLowerCase() == 'key' ? AuthType.key : AuthType.password;
            final password = parts.length > 5 ? parts[5].trim() : null;
            final groupName = parts.length > 6 && parts[6].trim().isNotEmpty ? parts[6].trim() : null;
            final notes = parts.length > 7 && parts[7].trim().isNotEmpty ? parts[7].trim() : null;

            final profile = ConnectionProfile(
              name: name, host: host, port: port, username: username,
              authType: authType, groupName: groupName, notes: notes,
            );
            if (password != null && password.isNotEmpty) {
              await ref.read(secureStorageServiceProvider).storePassword(profile.id, password);
            }
            await connectionsNotifier.addConnection(profile);
            importedCount++;
          } catch (e) { continue; }
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $importedCount hosts')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  void _showExportDialog() async {
    // 选择导出格式
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出格式'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: Icon(Icons.data_object), title: const Text('JSON'), subtitle: const Text('标准备份格式'), onTap: () => Navigator.pop(context, 'json')),
          ListTile(leading: Icon(Icons.text_fields), title: const Text('TXT'), subtitle: const Text('文本格式，可导入'), onTap: () => Navigator.pop(context, 'txt')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ],
      ),
    );
    if (format == null) return;

    // TXT 格式询问是否导出明文密码
    bool includePassword = false;
    if (format == 'txt') {
      includePassword = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导出密码'),
          content: const Text('是否在导出文件中包含明文密码？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('不包含')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('包含')),
          ],
        ),
      ) ?? false;
    }

    try {
      final connections = ref.read(connectionsProvider);
      if (connections.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有主机可导出')));
        return;
      }

      if (format == 'txt') {
        // TXT 格式
        final lines = <String>[];
        final secureStorage = ref.read(secureStorageServiceProvider);
        for (final conn in connections) {
          String password = '';
          if (includePassword) {
            try {
              final pwd = await secureStorage.getPassword(conn.id);
              if (pwd != null) password = pwd;
            } catch (_) {}
          }
          final parts = [
            conn.name, conn.host, conn.port.toString(), conn.username,
            conn.authType == AuthType.key ? 'key' : 'password', password,
            conn.groupName ?? '', conn.notes ?? '',
          ];
          lines.add(parts.join(','));
        }
        final content = lines.join('\n');
        final result = await FilePicker.platform.saveFile(dialogTitle: '保存', fileName: 'zTerm_hosts.txt', type: FileType.custom, allowedExtensions: ['txt']);
        if (result == null) return;
        await File(result).writeAsString(content);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导出 ${connections.length} 个主机')));
      } else {
        // JSON 格式
        final jsonList = connections.map((c) => c.toJson()).toList();
        final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
        final result = await FilePicker.platform.saveFile(dialogTitle: '保存', fileName: 'zTerm_hosts.json', type: FileType.custom, allowedExtensions: ['json']);
        if (result == null) return;
        await File(result).writeAsString(jsonString);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导出 ${connections.length} 个主机')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }
}
