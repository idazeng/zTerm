import 'package:uuid/uuid.dart';

/// 命令片段模型
class Snippet {
  /// 片段唯一标识
  final String id;
  
  /// 片段名称
  final String name;
  
  /// 命令内容
  final String command;
  
  /// 描述信息
  final String? description;
  
  /// 分组标签
  final String? groupName;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;

  Snippet({
    String? id,
    required this.name,
    required this.command,
    this.description,
    this.groupName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 创建实例
  factory Snippet.fromJson(Map<String, dynamic> json) {
    return Snippet(
      id: json['id'] as String?,
      name: json['name'] as String,
      command: json['command'] as String,
      description: json['description'] as String?,
      groupName: json['groupName'] as String?,
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
      'id': id,
      'name': name,
      'command': command,
      'description': description,
      'groupName': groupName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 创建副本
  Snippet copyWith({
    String? name,
    String? command,
    String? description,
    String? groupName,
  }) {
    return Snippet(
      id: id,
      name: name ?? this.name,
      command: command ?? this.command,
      description: description ?? this.description,
      groupName: groupName ?? this.groupName,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
