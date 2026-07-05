import 'package:uuid/uuid.dart';

/// SSH 主机连接配置模型
class ConnectionProfile {
  /// 连接唯一标识
  final String id;
  
  /// 连接名称/主机名
  final String name;
  
  /// 主机 IP 地址
  final String host;
  
  /// SSH 端口号，默认 22
  final int port;
  
  /// 用户名
  final String username;
  
  /// 认证方式：password 或 key
  final AuthType authType;
  
  /// 密码（加密存储）
  final String? password;
  
  /// 私钥路径
  final String? privateKeyPath;
  
  /// 私钥口令（加密存储）
  final String? passphrase;
  
  /// 最后连接时间
  final DateTime? lastConnected;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;
  
  /// 连接分组
  final String? groupName;
  
  /// 备注信息
  final String? notes;

  ConnectionProfile({
    String? id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    this.authType = AuthType.password,
    this.password,
    this.privateKeyPath,
    this.passphrase,
    this.lastConnected,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.groupName,
    this.notes,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 创建实例
  factory ConnectionProfile.fromJson(Map<String, dynamic> json) {
    return ConnectionProfile(
      id: json['id'] as String?,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? 22,
      username: json['username'] as String,
      authType: AuthType.values.firstWhere(
        (e) => e.name == json['authType'],
        orElse: () => AuthType.password,
      ),
      password: json['password'] as String?,
      privateKeyPath: json['privateKeyPath'] as String?,
      passphrase: json['passphrase'] as String?,
      lastConnected: json['lastConnected'] != null
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      groupName: json['groupName'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// 转换为 JSON（导出时不包含敏感信息）
  Map<String, dynamic> toJson({bool includePassword = false}) {
    final json = {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'authType': authType.name,
      'privateKeyPath': privateKeyPath,
      'lastConnected': lastConnected?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'groupName': groupName,
      'notes': notes,
    };
    
    // 仅密码认证时可选包含密码
    if (includePassword && authType == AuthType.password) {
      json['password'] = password;
    }
    
    return json;
  }

  /// 创建副本
  ConnectionProfile copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    AuthType? authType,
    String? password,
    String? privateKeyPath,
    String? passphrase,
    DateTime? lastConnected,
    String? groupName,
    String? notes,
  }) {
    return ConnectionProfile(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      password: password ?? this.password,
      privateKeyPath: privateKeyPath ?? this.privateKeyPath,
      passphrase: passphrase ?? this.passphrase,
      lastConnected: lastConnected ?? this.lastConnected,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      groupName: groupName ?? this.groupName,
      notes: notes ?? this.notes,
    );
  }

  /// 获取显示用的主机信息
  String get displayHost => '$username@$host:$port';
}

/// 认证方式枚举
enum AuthType {
  /// 密码认证
  password,
  
  /// 密钥认证
  key,
}
