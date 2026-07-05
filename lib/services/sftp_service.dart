import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/models.dart' as models;

/// SFTP 服务类 - 管理文件操作
class SftpService {
  /// 当前 SFTP 客户端
  final SftpClient _client;

  SftpService(this._client);

  /// 将 SFTP 的 epoch 秒时间戳转为 DateTime
  static DateTime _epochToDate(int? epoch) {
    if (epoch == null || epoch == 0) return DateTime.now();
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
  }

  /// 列出目录内容
  Future<List<models.SftpFile>> listDirectory(String path) async {
    try {
      final items = await _client.listdir(path);
      
      return items.map((item) {
        final attr = item.attr;
        return models.SftpFile(
          name: item.filename,
          path: '$path/${item.filename}'.replaceAll('//', '/'),
          size: attr.size ?? 0,
          modifyTime: _epochToDate(attr.modifyTime),
          accessTime: _epochToDate(attr.accessTime),
          permissions: attr.mode?.value ?? 0,
          isDirectory: attr.isDirectory,
          isSymbolicLink: attr.isSymbolicLink,
        );
      }).toList();
    } catch (e) {
      throw Exception('列出目录失败: $e');
    }
  }

  /// 递归列出目录内容
  Future<List<models.SftpFile>> listDirectoryRecursive(String path) async {
    final result = <models.SftpFile>[];
    
    try {
      final items = await listDirectory(path);
      
      for (final item in items) {
        result.add(item);
        
        if (item.isDirectory && item.name != '.' && item.name != '..') {
          final subItems = await listDirectoryRecursive(item.path);
          result.addAll(subItems);
        }
      }
    } catch (e) {
      // 忽略无法访问的子目录
    }
    
    return result;
  }

  /// 创建目录
  Future<void> createDirectory(String path) async {
    try {
      await _client.mkdir(path);
    } catch (e) {
      throw Exception('创建目录失败: $e');
    }
  }

  /// 删除文件或目录
  Future<void> delete(String path, {bool recursive = false}) async {
    try {
      if (recursive) {
        await deleteRecursive(path);
      } else {
        await _client.remove(path);
      }
    } catch (e) {
      throw Exception('删除失败: $e');
    }
  }

  /// 递归删除目录
  Future<void> deleteRecursive(String path) async {
    try {
      final items = await listDirectory(path);
      
      for (final item in items) {
        if (item.name == '.' || item.name == '..') continue;
        
        if (item.isDirectory) {
          await deleteRecursive(item.path);
        } else {
          await delete(item.path);
        }
      }
      
      await _client.rmdir(path);
    } catch (e) {
      throw Exception('递归删除失败: $e');
    }
  }

  /// 重命名/移动文件
  Future<void> rename(String oldPath, String newPath) async {
    try {
      await _client.rename(oldPath, newPath);
    } catch (e) {
      throw Exception('重命名失败: $e');
    }
  }

  /// 读取文件内容
  Future<Uint8List> readFile(String remotePath) async {
    try {
      final file = await _client.open(remotePath);
      final data = await file.readBytes();
      await file.close();
      return data;
    } catch (e) {
      throw Exception('读取文件失败: $e');
    }
  }

  /// 写入文件内容
  Future<void> writeFile(String remotePath, Uint8List data) async {
    try {
      final file = await _client.open(remotePath, mode: SftpFileOpenMode.truncate);
      await file.writeBytes(data);
      await file.close();
    } catch (e) {
      throw Exception('写入文件失败: $e');
    }
  }

  /// 上传文件
  Future<void> uploadFile(
    String localPath,
    String remotePath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('本地文件不存在');
      }
      
      final data = await file.readAsBytes();
      final sftpFile = await _client.open(remotePath);
      
      // 分块写入以支持进度回调
      const chunkSize = 1024 * 1024; // 1MB
      var offset = 0;
      
      while (offset < data.length) {
        final end = (offset + chunkSize).clamp(0, data.length);
        final chunk = data.sublist(offset, end);
        
        await sftpFile.writeBytes(chunk);
        offset = end;
        
        onProgress?.call(offset, data.length);
      }
      
      await sftpFile.close();
    } catch (e) {
      throw Exception('上传文件失败: $e');
    }
  }

  /// 下载文件
  Future<void> downloadFile(
    String remotePath,
    String localPath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final sftpFile = await _client.open(remotePath);
      final data = await sftpFile.readBytes();
      
      final file = File(localPath);
      await file.writeAsBytes(data);
      
      onProgress?.call(data.length, data.length);
      
      await sftpFile.close();
    } catch (e) {
      throw Exception('下载文件失败: $e');
    }
  }

  /// 上传目录（递归）
  Future<void> uploadDirectory(
    String localPath,
    String remotePath, {
    Function(String, int, int)? onProgress,
  }) async {
    try {
      final directory = Directory(localPath);
      if (!await directory.exists()) {
        throw Exception('本地目录不存在');
      }
      
      // 创建远程目录
      await createDirectory(remotePath);
      
      await for (final entity in directory.list()) {
        final name = entity.path.split(Platform.pathSeparator).last;
        final remoteItemPath = '$remotePath/$name';
        
        if (entity is File) {
          await uploadFile(entity.path, remoteItemPath);
          onProgress?.call(name, 0, 1);
        } else if (entity is Directory) {
          await uploadDirectory(entity.path, remoteItemPath);
        }
      }
    } catch (e) {
      throw Exception('上传目录失败: $e');
    }
  }

  /// 下载目录（递归）
  Future<void> downloadDirectory(
    String remotePath,
    String localPath, {
    Function(String, int, int)? onProgress,
  }) async {
    try {
      final items = await listDirectory(remotePath);
      
      // 创建本地目录
      final directory = Directory(localPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      for (final item in items) {
        if (item.name == '.' || item.name == '..') continue;
        
        final localItemPath = '$localPath${Platform.pathSeparator}${item.name}';
        
        if (item.isDirectory) {
          await downloadDirectory(item.path, localItemPath);
        } else {
          await downloadFile(item.path, localItemPath);
          onProgress?.call(item.name, 0, 1);
        }
      }
    } catch (e) {
      throw Exception('下载目录失败: $e');
    }
  }

  /// 获取文件信息
  Future<models.SftpFile> stat(String path) async {
    try {
      final sftpStat = await _client.stat(path);
      return models.SftpFile(
        name: path.split('/').last,
        path: path,
        size: sftpStat.size ?? 0,
        modifyTime: _epochToDate(sftpStat.modifyTime),
        accessTime: _epochToDate(sftpStat.accessTime),
        permissions: sftpStat.mode?.value ?? 0,
        isDirectory: sftpStat.isDirectory,
        isSymbolicLink: sftpStat.isSymbolicLink,
      );
    } catch (e) {
      throw Exception('获取文件信息失败: $e');
    }
  }

  /// 修改文件/目录权限
  Future<void> chmod(String path, int mode) async {
    try {
      final sftpMode = SftpFileMode.value(mode);
      final attrs = SftpFileAttrs(mode: sftpMode);
      await _client.setStat(path, attrs);
    } catch (e) {
      throw Exception('修改权限失败: $e');
    }
  }

  /// 检查文件/目录是否存在
  Future<bool> exists(String path) async {
    try {
      await _client.stat(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 关闭 SFTP 连接
  void close() {
    _client.close();
  }
}
