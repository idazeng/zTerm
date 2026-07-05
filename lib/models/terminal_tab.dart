import 'package:uuid/uuid.dart';

/// 终端标签模型
class TerminalTab {
  /// 标签唯一标识
  final String id;
  
  /// 关联的连接配置 ID
  final String connectionId;
  
  /// 标签标题
  final String title;
  
  /// 当前工作目录（用于 SFTP 同步）
  final String currentDirectory;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 是否激活
  final bool isActive;

  TerminalTab({
    String? id,
    required this.connectionId,
    String? title,
    this.currentDirectory = '~',
    DateTime? createdAt,
    this.isActive = false,
  }) : id = id ?? const Uuid().v4(),
       title = title ?? '新终端',
       createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 创建实例
  factory TerminalTab.fromJson(Map<String, dynamic> json) {
    return TerminalTab(
      id: json['id'] as String?,
      connectionId: json['connectionId'] as String,
      title: json['title'] as String?,
      currentDirectory: json['currentDirectory'] as String? ?? '~',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connectionId': connectionId,
      'title': title,
      'currentDirectory': currentDirectory,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// 创建副本
  TerminalTab copyWith({
    String? title,
    String? currentDirectory,
    bool? isActive,
  }) {
    return TerminalTab(
      id: id,
      connectionId: connectionId,
      title: title ?? this.title,
      currentDirectory: currentDirectory ?? this.currentDirectory,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
