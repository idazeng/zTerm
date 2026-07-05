import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../theme/app_colors.dart' as theme;

/// 设置页面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 外观设置
          _buildSectionHeader('外观'),
          _buildThemeModeTile(settings),
          _buildThemeColorTile(settings),
          _buildFontSizeTile(settings),
          _buildTerminalFontSizeTile(settings),
          
          const Divider(),
          
          // 终端设置
          _buildSectionHeader('终端'),
          _buildCommandBroadcastTile(settings),
          _buildSftpPanelTile(settings),
          
          const Divider(),
          
          // WebDAV 同步
          _buildSectionHeader('WebDAV 同步'),
          _buildWebdavSettingsTile(settings),
          _buildWebdavSyncIntervalTile(settings),
          
          const Divider(),
          
          // 安全设置
          _buildSectionHeader('安全'),
          _buildMasterPasswordTile(settings),
          
          const Divider(),
          
          // 数据管理
          _buildSectionHeader('数据管理'),
          _buildBackupTile(),
          _buildRestoreTile(),
          _buildClearDataTile(),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppStyles.titleSmall.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// 主题模式设置
  Widget _buildThemeModeTile(dynamic settings) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('主题模式'),
      subtitle: Text(_getThemeModeName(settings.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeModeDialog(settings),
    );
  }

  String _getThemeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return '浅色模式';
      case AppThemeMode.dark:
        return '深色模式';
      default:
        return '跟随系统';
    }
  }

  void _showThemeModeDialog(dynamic settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.brightness_auto,
                color: settings.themeMode == AppThemeMode.system
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('跟随系统'),
              trailing: settings.themeMode == AppThemeMode.system
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(appSettingsProvider.notifier).setThemeMode(AppThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.light_mode,
                color: settings.themeMode == AppThemeMode.light
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('浅色模式'),
              trailing: settings.themeMode == AppThemeMode.light
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(appSettingsProvider.notifier).setThemeMode(AppThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.dark_mode,
                color: settings.themeMode == AppThemeMode.dark
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: const Text('深色模式'),
              trailing: settings.themeMode == AppThemeMode.dark
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(appSettingsProvider.notifier).setThemeMode(AppThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 主题色设置
  Widget _buildThemeColorTile(dynamic settings) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('主题色'),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: theme.AppColors.accentPalette[settings.themeColorIndex],
          shape: BoxShape.circle,
        ),
      ),
      onTap: () => _showThemeColorDialog(settings),
    );
  }

  void _showThemeColorDialog(dynamic settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题色'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            theme.AppColors.accentPalette.length,
            (index) => GestureDetector(
              onTap: () {
                ref.read(appSettingsProvider.notifier).setThemeColor(index);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.AppColors.accentPalette[index],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: settings.themeColorIndex == index
                        ? Colors.white
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: settings.themeColorIndex == index
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 字体大小设置
  Widget _buildFontSizeTile(dynamic settings) {
    return ListTile(
      leading: const Icon(Icons.text_fields),
      title: const Text('字体大小'),
      subtitle: Text('${settings.fontSize.toStringAsFixed(0)}'),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: settings.fontSize,
          min: 12,
          max: 20,
          divisions: 8,
          onChanged: (value) {
            ref.read(appSettingsProvider.notifier).setFontSize(value);
          },
        ),
      ),
    );
  }

  /// 终端字体大小设置
  Widget _buildTerminalFontSizeTile(dynamic settings) {
    return ListTile(
      leading: const Icon(Icons.code),
      title: const Text('终端字体大小'),
      subtitle: Text('${settings.terminalFontSize.toStringAsFixed(0)}'),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: settings.terminalFontSize,
          min: 10,
          max: 20,
          divisions: 10,
          onChanged: (value) {
            ref.read(appSettingsProvider.notifier).setTerminalFontSize(value);
          },
        ),
      ),
    );
  }

  /// 命令广播设置
  Widget _buildCommandBroadcastTile(dynamic settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.broadcast_on_home),
      title: const Text('命令广播'),
      subtitle: const Text('开启后手动输入的命令同步发送到所有标签'),
      value: settings.commandBroadcastEnabled,
      onChanged: (value) {
        ref.read(appSettingsProvider.notifier).toggleCommandBroadcast();
      },
    );
  }

  /// SFTP 面板显示设置
  Widget _buildSftpPanelTile(dynamic settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.folder),
      title: const Text('显示 SFTP 面板'),
      subtitle: const Text('在终端界面显示文件管理面板'),
      value: settings.sftpPanelVisible,
      onChanged: (value) {
        ref.read(appSettingsProvider.notifier).toggleSftpPanel();
      },
    );
  }

  /// WebDAV 设置
  Widget _buildWebdavSettingsTile(dynamic settings) {
    return ListTile(
      leading: const Icon(Icons.cloud),
      title: const Text('WebDAV 服务器'),
      subtitle: Text(settings.webdavUrl ?? '未配置'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showWebdavSettingsDialog(settings),
    );
  }

  void _showWebdavSettingsDialog(dynamic settings) {
    final urlController = TextEditingController(text: settings.webdavUrl);
    final usernameController = TextEditingController(text: settings.webdavUsername);
    final passwordController = TextEditingController();
    final subdirectoryController = TextEditingController(text: settings.webdavSubdirectory);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WebDAV 设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: '服务器地址',
                hintText: 'https://example.com/webdav',
              ),
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
              ),
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
              ),
              obscureText: true,
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            TextField(
              controller: subdirectoryController,
              decoration: const InputDecoration(
                labelText: '同步目录名',
                hintText: 'zTerm',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(appSettingsProvider.notifier).setWebdavSettings(
                    url: urlController.text.trim(),
                    username: usernameController.text.trim(),
                    password: passwordController.text,
                  );
              ref.read(appSettingsProvider.notifier).setWebdavSubdirectory(
                    subdirectoryController.text.trim().isEmpty
                        ? 'zTerm'
                        : subdirectoryController.text.trim(),
                  );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// WebDAV 同步间隔设置
  Widget _buildWebdavSyncIntervalTile(dynamic settings) {
    return ListTile(
      leading: const Icon(Icons.timer),
      title: const Text('自动同步间隔'),
      subtitle: Text(settings.webdavSyncInterval > 0
          ? '每 ${settings.webdavSyncInterval} 分钟'
          : '已禁用'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showSyncIntervalDialog(settings),
    );
  }

  void _showSyncIntervalDialog(dynamic settings) {
    final intervals = [0, 5, 10, 15, 30, 60, 120];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择同步间隔'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            return RadioListTile<int>(
              title: Text(interval > 0 ? '每 $interval 分钟' : '禁用'),
              value: interval,
              groupValue: settings.webdavSyncInterval,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setWebdavSettings(
                      syncInterval: value!,
                    );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 主密码设置
  Widget _buildMasterPasswordTile(dynamic settings) {
    return ListTile(
      leading: const Icon(Icons.lock),
      title: const Text('修改主密码'),
      subtitle: Text(settings.masterPasswordSet ? '已设置' : '未设置'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showChangeMasterPasswordDialog(),
    );
  }

  void _showChangeMasterPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const MasterPasswordChangeDialog(),
    );
  }

  /// 备份数据
  Widget _buildBackupTile() {
    return ListTile(
      leading: const Icon(Icons.backup),
      title: const Text('备份数据'),
      subtitle: const Text('将连接和命令片段导出到文件'),
      onTap: () async {
        try {
          final result = await FilePicker.platform.saveFile(
            dialogTitle: '选择备份文件保存位置',
            fileName: 'zTerm_backup.json',
            type: FileType.custom,
            allowedExtensions: ['json'],
          );

          if (result == null) return;

          final dbService = ref.read(databaseServiceProvider);
          final connections = await dbService.getAllConnections();
          final snippets = await dbService.getAllSnippets();

          final backupData = {
            'version': '1.0.0',
            'createdAt': DateTime.now().toIso8601String(),
            'connections': connections.map((c) => c.toJson(includePassword: true)).toList(),
            'snippets': snippets.map((s) => s.toJson()).toList(),
          };

          final file = File(result);
          await file.writeAsString(
            const JsonEncoder.withIndent('  ').convert(backupData),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('备份完成：${connections.length} 个连接，${snippets.length} 个片段')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('备份失败: $e')),
            );
          }
        }
      },
    );
  }

  /// 恢复数据
  Widget _buildRestoreTile() {
    return ListTile(
      leading: const Icon(Icons.restore),
      title: const Text('恢复数据'),
      subtitle: const Text('从备份文件恢复数据'),
      onTap: () async {
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['json'],
            dialogTitle: '选择备份文件',
          );

          if (result == null || result.files.isEmpty) return;

          // 确认恢复
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认恢复'),
              content: const Text('恢复将覆盖当前所有数据（连接和命令片段）。确定继续吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('确定恢复'),
                ),
              ],
            ),
          );

          if (confirmed != true) return;

          final file = File(result.files.first.path!);
          final backupData = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

          final connectionsJson = backupData['connections'] as List? ?? [];
          final connections = connectionsJson
              .map((j) => ConnectionProfile.fromJson(Map<String, dynamic>.from(j)))
              .toList();

          final snippetsJson = backupData['snippets'] as List? ?? [];
          final snippets = snippetsJson
              .map((j) => Snippet.fromJson(Map<String, dynamic>.from(j)))
              .toList();

          final dbService = ref.read(databaseServiceProvider);
          await dbService.clearAll();
          await dbService.importConnections(connections);
          await dbService.importSnippets(snippets);

          // 恢复密码到安全存储
          final secureStorage = ref.read(secureStorageServiceProvider);
          for (final conn in connections) {
            if (conn.password != null && conn.password!.isNotEmpty) {
              await secureStorage.storePassword(conn.id, conn.password!);
            }
          }

          // 刷新连接列表
          ref.read(connectionsProvider.notifier).refresh();
          ref.read(snippetsProvider.notifier).refresh();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('恢复完成：${connections.length} 个连接，${snippets.length} 个片段')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('恢复失败: $e')),
            );
          }
        }
      },
    );
  }

  /// 清除数据
  Widget _buildClearDataTile() {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('清除所有数据', style: TextStyle(color: Colors.red)),
      subtitle: const Text('删除所有连接、命令片段和设置'),
      onTap: () => _showClearDataConfirmation(),
    );
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('此操作将删除所有数据，且无法恢复。确定继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final dbService = ref.read(databaseServiceProvider);
                await dbService.clearAll();
                
                // 清空内存中的状态
                ref.read(connectionsProvider.notifier).refresh();
                ref.read(snippetsProvider.notifier).refresh();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('所有数据已清除')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('清除失败: $e')),
                  );
                }
              }
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}

/// 主密码修改对话框
class MasterPasswordChangeDialog extends ConsumerStatefulWidget {
  const MasterPasswordChangeDialog({super.key});

  @override
  ConsumerState<MasterPasswordChangeDialog> createState() =>
      _MasterPasswordChangeDialogState();
}

class _MasterPasswordChangeDialogState
    extends ConsumerState<MasterPasswordChangeDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('修改主密码'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '当前密码',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入当前密码';
                }
                return null;
              },
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '新密码',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入新密码';
                }
                if (value.length < 6) {
                  return '密码至少6位';
                }
                return null;
              },
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '确认新密码',
              ),
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return '两次密码不一致';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleChange,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('修改'),
        ),
      ],
    );
  }

  Future<void> _handleChange() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.updateMasterPassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('密码修改成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('修改失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
