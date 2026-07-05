/// 应用设置模型
import 'package:flutter/material.dart';

class AppSettings {
  /// 主题模式：system, light, dark
  final AppThemeMode themeMode;
  
  /// 主题色索引
  final int themeColorIndex;
  
  /// 字体大小
  final double fontSize;
  
  /// 字体族
  final String fontFamily;
  
  /// 终端字体大小
  final double terminalFontSize;
  
  /// 终端字体族
  final String terminalFontFamily;
  
  /// 命令广播是否开启
  final bool commandBroadcastEnabled;
  
  /// SFTP 面板默认显示
  final bool sftpPanelVisible;
  
  /// 分栏比例 (0.0 - 1.0)
  final double splitRatio;
  
  /// WebDAV 同步地址
  final String? webdavUrl;
  
  /// WebDAV 用户名
  final String? webdavUsername;
  
  /// WebDAV 密码（加密存储）
  final String? webdavPassword;
  
  /// WebDAV 自动同步间隔（分钟），0 表示禁用
  final int webdavSyncInterval;
  
  /// SFTP 跟随 SSH 目录
  final bool followSshDirectory;
  
  /// WebDAV 同步子目录
  final String webdavSubdirectory;
  
  /// 主密码是否已设置
  final bool masterPasswordSet;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;

  AppSettings({
    this.themeMode = AppThemeMode.system,
    this.themeColorIndex = 0,
    this.fontSize = 14.0,
    this.fontFamily = '',
    this.terminalFontSize = 14.0,
    this.terminalFontFamily = 'monospace',
    this.commandBroadcastEnabled = false,
    this.sftpPanelVisible = true,
    this.splitRatio = 0.5,
    this.webdavUrl,
    this.webdavUsername,
    this.webdavPassword,
    this.webdavSyncInterval = 30,
    this.followSshDirectory = true,
    this.webdavSubdirectory = 'zTerm',
    this.masterPasswordSet = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 创建实例
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      themeColorIndex: json['themeColorIndex'] as int? ?? 0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      fontFamily: json['fontFamily'] as String? ?? '',
      terminalFontSize: (json['terminalFontSize'] as num?)?.toDouble() ?? 14.0,
      terminalFontFamily: json['terminalFontFamily'] as String? ?? 'monospace',
      commandBroadcastEnabled: json['commandBroadcastEnabled'] as bool? ?? false,
      sftpPanelVisible: json['sftpPanelVisible'] as bool? ?? true,
      splitRatio: (json['splitRatio'] as num?)?.toDouble() ?? 0.5,
      webdavUrl: json['webdavUrl'] as String?,
      webdavUsername: json['webdavUsername'] as String?,
      webdavPassword: json['webdavPassword'] as String?,
      webdavSyncInterval: json['webdavSyncInterval'] as int? ?? 30,
      followSshDirectory: json['followSshDirectory'] as bool? ?? false,
      webdavSubdirectory: json['webdavSubdirectory'] as String? ?? 'zTerm',
      masterPasswordSet: json['masterPasswordSet'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'themeColorIndex': themeColorIndex,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'terminalFontSize': terminalFontSize,
      'terminalFontFamily': terminalFontFamily,
      'commandBroadcastEnabled': commandBroadcastEnabled,
      'sftpPanelVisible': sftpPanelVisible,
      'splitRatio': splitRatio,
      'webdavUrl': webdavUrl,
      'webdavUsername': webdavUsername,
      'webdavPassword': webdavPassword,
      'webdavSyncInterval': webdavSyncInterval,
      'followSshDirectory': followSshDirectory,
      'webdavSubdirectory': webdavSubdirectory,
      'masterPasswordSet': masterPasswordSet,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// 创建副本
  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? themeColorIndex,
    double? fontSize,
    String? fontFamily,
    double? terminalFontSize,
    String? terminalFontFamily,
    bool? commandBroadcastEnabled,
    bool? sftpPanelVisible,
    double? splitRatio,
    String? webdavUrl,
    String? webdavUsername,
    String? webdavPassword,
    int? webdavSyncInterval,
    bool? followSshDirectory,
    String? webdavSubdirectory,
    bool? masterPasswordSet,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      themeColorIndex: themeColorIndex ?? this.themeColorIndex,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      terminalFontSize: terminalFontSize ?? this.terminalFontSize,
      terminalFontFamily: terminalFontFamily ?? this.terminalFontFamily,
      commandBroadcastEnabled: commandBroadcastEnabled ?? this.commandBroadcastEnabled,
      sftpPanelVisible: sftpPanelVisible ?? this.sftpPanelVisible,
      splitRatio: splitRatio ?? this.splitRatio,
      webdavUrl: webdavUrl ?? this.webdavUrl,
      webdavUsername: webdavUsername ?? this.webdavUsername,
      webdavPassword: webdavPassword ?? this.webdavPassword,
      webdavSyncInterval: webdavSyncInterval ?? this.webdavSyncInterval,
      followSshDirectory: followSshDirectory ?? this.followSshDirectory,
      webdavSubdirectory: webdavSubdirectory ?? this.webdavSubdirectory,
      masterPasswordSet: masterPasswordSet ?? this.masterPasswordSet,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// 主题模式枚举
enum AppThemeMode {
  /// 跟随系统
  system,
  
  /// 浅色模式
  light,
  
  /// 深色模式
  dark,
}
