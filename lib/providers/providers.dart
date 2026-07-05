import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'package:dartssh2/dartssh2.dart';

/// 数据库服务 Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// 安全存储服务 Provider
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// SSH 服务 Provider
final sshServiceProvider = Provider<SshService>((ref) {
  return SshService();
});

/// 应用设置状态 Provider
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref);
});

/// 连接列表 Provider
final connectionsProvider = StateNotifierProvider<ConnectionsNotifier, List<ConnectionProfile>>((ref) {
  return ConnectionsNotifier(ref);
});

/// 命令片段列表 Provider
final snippetsProvider = StateNotifierProvider<SnippetsNotifier, List<Snippet>>((ref) {
  return SnippetsNotifier(ref);
});

/// 终端标签列表 Provider
final terminalTabsProvider = StateNotifierProvider<TerminalTabsNotifier, List<TerminalTab>>((ref) {
  return TerminalTabsNotifier(ref);
});

/// 当前激活的标签 ID Provider
final activeTabIdProvider = StateProvider<String?>((ref) => null);

/// 主密码设置状态 Provider
final masterPasswordSetProvider = StateProvider<bool>((ref) => false);

/// 待插入终端的命令 Provider（由片段库设置，终端监听并消费）
final pendingCommandProvider = StateProvider<String?>((ref) => null);

/// SFTP 跟随 SSH 目录的路径 Provider（终端检测到目录变化时设置）
final sshDirectoryProvider = StateProvider<String?>((ref) => null);

/// 活跃 SSH 会话注册表 Provider（tabId -> SSHSession）
final activeSessionsProvider = Provider<ActiveSessions>((ref) => ActiveSessions());

/// 应用设置状态管理器
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final Ref ref;
  
  AppSettingsNotifier(this.ref) : super(AppSettings()) {
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final dbService = ref.read(databaseServiceProvider);
    final settingsJson = await dbService.getSetting('app_settings');
    
    if (settingsJson != null) {
      try {
        final json = Map<String, dynamic>.from(
          Map<String, dynamic>.from(jsonDecode(settingsJson)),
        );
        state = AppSettings.fromJson(json);
      } catch (e) {
        // 解析失败，使用默认设置
      }
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.setSetting(
      'app_settings',
      jsonEncode(state.toJson()),
    );
  }

  /// 更新主题模式
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }

  /// 更新主题色
  Future<void> setThemeColor(int index) async {
    state = state.copyWith(themeColorIndex: index);
    await _saveSettings();
  }

  /// 更新字体大小
  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _saveSettings();
  }

  /// 更新终端字体大小
  Future<void> setTerminalFontSize(double size) async {
    state = state.copyWith(terminalFontSize: size);
    await _saveSettings();
  }

  /// 切换命令广播
  Future<void> toggleCommandBroadcast() async {
    state = state.copyWith(
      commandBroadcastEnabled: !state.commandBroadcastEnabled,
    );
    await _saveSettings();
  }

  /// 更新分栏比例
  Future<void> setSplitRatio(double ratio) async {
    state = state.copyWith(splitRatio: ratio);
    await _saveSettings();
  }

  /// 切换 SFTP 面板显示
  Future<void> toggleSftpPanel() async {
    final visible = !state.sftpPanelVisible;
    state = state.copyWith(
      sftpPanelVisible: visible,
      splitRatio: visible ? (state.splitRatio == 0 ? 0.5 : state.splitRatio) : 0,
    );
    await _saveSettings();
  }

  /// 切换 SFTP 跟随 SSH 目录
  Future<void> toggleFollowSshDirectory() async {
    state = state.copyWith(
      followSshDirectory: !state.followSshDirectory,
    );
    await _saveSettings();
  }

  /// 更新 WebDAV 设置
  Future<void> setWebdavSettings({
    String? url,
    String? username,
    String? password,
    int? syncInterval,
  }) async {
    state = state.copyWith(
      webdavUrl: url ?? state.webdavUrl,
      webdavUsername: username ?? state.webdavUsername,
      webdavPassword: password ?? state.webdavPassword,
      webdavSyncInterval: syncInterval ?? state.webdavSyncInterval,
    );
    await _saveSettings();
  }

  /// 更新 WebDAV 子目录
  Future<void> setWebdavSubdirectory(String subdirectory) async {
    state = state.copyWith(webdavSubdirectory: subdirectory);
    await _saveSettings();
  }

  /// 标记主密码已设置
  Future<void> setMasterPasswordFlag(bool set) async {
    state = state.copyWith(masterPasswordSet: set);
    await _saveSettings();
  }
}

/// 连接列表状态管理器
class ConnectionsNotifier extends StateNotifier<List<ConnectionProfile>> {
  final Ref ref;
  
  ConnectionsNotifier(this.ref) : super([]) {
    _loadConnections();
  }

  /// 加载连接列表
  Future<void> _loadConnections() async {
    final dbService = ref.read(databaseServiceProvider);
    state = await dbService.getAllConnections();
  }

  /// 添加连接
  Future<void> addConnection(ConnectionProfile connection) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.insertConnection(connection);
    state = [...state, connection];
  }

  /// 更新连接
  Future<void> updateConnection(ConnectionProfile connection) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.updateConnection(connection);
    state = state.map((c) => c.id == connection.id ? connection : c).toList();
  }

  /// 删除连接
  Future<void> deleteConnection(String id) async {
    final dbService = ref.read(databaseServiceProvider);
    final secureStorage = ref.read(secureStorageServiceProvider);
    
    await dbService.deleteConnection(id);
    await secureStorage.deletePassword(id);
    await secureStorage.deletePassphrase(id);
    await secureStorage.deletePrivateKey(id);
    
    state = state.where((c) => c.id != id).toList();
  }

  /// 更新最后连接时间
  Future<void> updateLastConnected(String id) async {
    final dbService = ref.read(databaseServiceProvider);
    final connection = state.firstWhere((c) => c.id == id);
    
    final updated = connection.copyWith(lastConnected: DateTime.now());
    await dbService.updateConnection(updated);
    state = state.map((c) => c.id == id ? updated : c).toList();
  }

  /// 刷新连接列表
  Future<void> refresh() async {
    await _loadConnections();
  }
}

/// 命令片段状态管理器
class SnippetsNotifier extends StateNotifier<List<Snippet>> {
  final Ref ref;
  
  SnippetsNotifier(this.ref) : super([]) {
    _loadSnippets();
  }

  /// 加载片段列表
  Future<void> _loadSnippets() async {
    final dbService = ref.read(databaseServiceProvider);
    state = await dbService.getAllSnippets();
  }

  /// 添加片段
  Future<void> addSnippet(Snippet snippet) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.insertSnippet(snippet);
    state = [...state, snippet];
  }

  /// 更新片段
  Future<void> updateSnippet(Snippet snippet) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.updateSnippet(snippet);
    state = state.map((s) => s.id == snippet.id ? snippet : s).toList();
  }

  /// 删除片段
  Future<void> deleteSnippet(String id) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.deleteSnippet(id);
    state = state.where((s) => s.id != id).toList();
  }

  /// 刷新片段列表
  Future<void> refresh() async {
    await _loadSnippets();
  }
}

/// 终端标签状态管理器
class TerminalTabsNotifier extends StateNotifier<List<TerminalTab>> {
  final Ref ref;
  
  TerminalTabsNotifier(this.ref) : super([]);

  /// 添加标签
  void addTab(TerminalTab tab) {
    state = [...state, tab];
  }

  /// 移除标签
  void removeTab(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  /// 更新标签
  void updateTab(TerminalTab tab) {
    state = state.map((t) => t.id == tab.id ? tab : t).toList();
  }

  /// 设置激活标签
  void setActiveTab(String id) {
    state = state.map((t) => t.copyWith(isActive: t.id == id)).toList();
  }

  /// 更新当前目录
  void updateCurrentDirectory(String tabId, String directory) {
    state = state.map((t) {
      if (t.id == tabId) {
        return t.copyWith(currentDirectory: directory);
      }
      return t;
    }).toList();
  }
}

/// 活跃 SSH 会话注册表 - 用于命令广播和片段插入
class ActiveSessions {
  final Map<String, SSHSession> _sessions = {};

  /// 获取指定标签的 SSH 会话
  SSHSession? getSession(String tabId) => _sessions[tabId];

  /// 注册会话
  void register(String tabId, SSHSession session) {
    _sessions[tabId] = session;
  }

  /// 注销会话
  void unregister(String tabId) {
    _sessions.remove(tabId);
  }

  /// 获取所有活跃的标签 ID
  Iterable<String> get activeTabIds => _sessions.keys;
}
