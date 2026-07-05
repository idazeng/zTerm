import 'package:uuid/uuid.dart';

/// SFTP 文件信息模型
class SftpFile {
  /// 文件/文件夹名称
  final String name;
  
  /// 文件完整路径
  final String path;
  
  /// 文件大小（字节）
  final int size;
  
  /// 修改时间
  final DateTime modifyTime;
  
  /// 访问时间
  final DateTime accessTime;
  
  /// 文件权限（八进制）
  final int permissions;
  
  /// 是否为目录
  final bool isDirectory;
  
  /// 是否为符号链接
  final bool isSymbolicLink;
  
  /// 所有者 ID
  final int? uid;
  
  /// 组 ID
  final int? gid;

  SftpFile({
    required this.name,
    required this.path,
    this.size = 0,
    DateTime? modifyTime,
    DateTime? accessTime,
    this.permissions = 0,
    this.isDirectory = false,
    this.isSymbolicLink = false,
    this.uid,
    this.gid,
  }) : modifyTime = modifyTime ?? DateTime.now(),
       accessTime = accessTime ?? DateTime.now();

  /// 从 dartssh2 的 SftpName 创建
  factory SftpFile.fromSftp(dynamic sftpName, String parentPath) {
    // sftpName 是 dartssh2 的 SftpName，具有 filename、longname、attr 属性
    final name = sftpName.filename ?? '';
    final path = '$parentPath/$name'.replaceAll('//', '/');
    final attr = sftpName.attr;
    
    return SftpFile(
      name: name,
      path: path,
      size: attr?.size ?? 0,
      modifyTime: _epochToDate(attr?.modifyTime),
      accessTime: _epochToDate(attr?.accessTime),
      permissions: attr?.mode?.value ?? 0,
      isDirectory: attr?.isDirectory ?? false,
      isSymbolicLink: attr?.isSymbolicLink ?? false,
      uid: attr?.userID,
      gid: attr?.groupID,
    );
  }

  /// 将 epoch 秒时间戳转为 DateTime
  static DateTime _epochToDate(int? epoch) {
    if (epoch == null || epoch == 0) return DateTime.now();
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
  }

  /// 获取权限字符串表示（如 rwxr-xr-x）
  String get permissionsString {
    final buf = StringBuffer();
    
    // 用户权限
    buf.write((permissions & 0x100) != 0 ? 'r' : '-');
    buf.write((permissions & 0x080) != 0 ? 'w' : '-');
    buf.write((permissions & 0x040) != 0 ? 'x' : '-');
    
    // 组权限
    buf.write((permissions & 0x020) != 0 ? 'r' : '-');
    buf.write((permissions & 0x010) != 0 ? 'w' : '-');
    buf.write((permissions & 0x008) != 0 ? 'x' : '-');
    
    // 其他权限
    buf.write((permissions & 0x004) != 0 ? 'r' : '-');
    buf.write((permissions & 0x002) != 0 ? 'w' : '-');
    buf.write((permissions & 0x001) != 0 ? 'x' : '-');
    
    return buf.toString();
  }

  /// 获取文件大小的可读字符串
  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 获取文件扩展名
  String get extension {
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1 || lastDot == 0) return '';
    return name.substring(lastDot + 1).toLowerCase();
  }
}

/// SFTP 传输任务状态
enum TransferStatus {
  /// 等待中
  waiting,
  
  /// 传输中
  transferring,
  
  /// 已完成
  completed,
  
  /// 失败
  failed,
  
  /// 已取消
  cancelled,
}

/// SFTP 传输任务
class TransferTask {
  /// 任务 ID
  final String id;
  
  /// 远程文件路径
  final String remotePath;
  
  /// 本地文件路径
  final String localPath;
  
  /// 文件大小
  final int totalSize;
  
  /// 已传输大小
  final int transferredSize;
  
  /// 传输状态
  final TransferStatus status;
  
  /// 是否为上传任务（true=上传，false=下载）
  final bool isUpload;
  
  /// 错误信息
  final String? error;
  
  /// 创建时间
  final DateTime createdAt;

  TransferTask({
    String? id,
    required this.remotePath,
    required this.localPath,
    this.totalSize = 0,
    this.transferredSize = 0,
    this.status = TransferStatus.waiting,
    required this.isUpload,
    this.error,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// 获取传输进度百分比
  double get progress {
    if (totalSize == 0) return 0.0;
    return transferredSize / totalSize;
  }

  /// 创建副本
  TransferTask copyWith({
    int? transferredSize,
    TransferStatus? status,
    String? error,
  }) {
    return TransferTask(
      id: id,
      remotePath: remotePath,
      localPath: localPath,
      totalSize: totalSize,
      transferredSize: transferredSize ?? this.transferredSize,
      status: status ?? this.status,
      isUpload: isUpload,
      error: error ?? this.error,
      createdAt: createdAt,
    );
  }
}
