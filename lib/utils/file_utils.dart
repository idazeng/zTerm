import 'dart:io';
import 'package:path/path.dart' as p;

/// 文件工具类
class FileUtils {
  /// 获取文件扩展名
  static String getExtension(String path) {
    return p.extension(path).toLowerCase();
  }

  /// 获取文件名（不含扩展名）
  static String getFileNameWithoutExtension(String path) {
    return p.basenameWithoutExtension(path);
  }

  /// 获取文件名
  static String getFileName(String path) {
    return p.basename(path);
  }

  /// 获取父目录路径
  static String getParentPath(String path) {
    return p.dirname(path);
  }

  /// 合并路径
  static String joinPath(String part1, [String? part2, String? part3]) {
    if (part2 == null) return part1;
    if (part3 == null) return p.join(part1, part2);
    return p.join(part1, part2, part3);
  }

  /// 规范化路径
  static String normalizePath(String path) {
    return p.normalize(path);
  }

  /// 检查路径是否为绝对路径
  static bool isAbsolute(String path) {
    return p.isAbsolute(path);
  }

  /// 格式化文件大小
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${_pad(dateTime.month)}-${_pad(dateTime.day)} '
        '${_pad(dateTime.hour)}:${_pad(dateTime.minute)}:${_pad(dateTime.second)}';
  }

  /// 格式化日期
  static String formatDate(DateTime dateTime) {
    return '${dateTime.year}-${_pad(dateTime.month)}-${_pad(dateTime.day)}';
  }

  /// 格式化时间
  static String formatTime(DateTime dateTime) {
    return '${_pad(dateTime.hour)}:${_pad(dateTime.minute)}:${_pad(dateTime.second)}';
  }

  /// 数字补零
  static String _pad(int number) {
    return number.toString().padLeft(2, '0');
  }

  /// 检查文件是否存在
  static Future<bool> fileExists(String path) async {
    final file = File(path);
    return await file.exists();
  }

  /// 检查目录是否存在
  static Future<bool> directoryExists(String path) async {
    final directory = Directory(path);
    return await directory.exists();
  }

  /// 创建目录
  static Future<void> createDirectory(String path, {bool recursive = true}) async {
    final directory = Directory(path);
    await directory.create(recursive: recursive);
  }

  /// 删除文件
  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 删除目录
  static Future<void> deleteDirectory(String path, {bool recursive = true}) async {
    final directory = Directory(path);
    if (await directory.exists()) {
      await directory.delete(recursive: recursive);
    }
  }

  /// 复制文件
  static Future<void> copyFile(String source, String destination) async {
    final sourceFile = File(source);
    if (await sourceFile.exists()) {
      await sourceFile.copy(destination);
    }
  }

  /// 读取文件内容
  static Future<String> readFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
    throw FileSystemException('文件不存在', path);
  }

  /// 写入文件内容
  static Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  /// 获取临时目录
  static String getTempDirectory() {
    return Platform.environment['TEMP'] ??
        Platform.environment['TMPDIR'] ??
        '/tmp';
  }

  /// 获取用户主目录
  static String getHomeDirectory() {
    return Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '/';
  }
}
