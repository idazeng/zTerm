import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

/// 数据库服务类 - 管理 SQLite 数据库操作
class DatabaseService {
  static Database? _database;
  
  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    // 初始化 sqflite_common_ffi（桌面平台需要）
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Use Documents/zTerm for data storage
    String dbPath;
    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
      dbPath = p.join(home, 'Documents', 'zTerm');
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '';
      dbPath = p.join(home, 'Documents', 'zTerm');
    } else {
      dbPath = await getDatabasesPath();
    }
    
    // Ensure directory exists
    await Directory(dbPath).create(recursive: true);
    
    final path = p.join(dbPath, 'zTerm.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建连接配置表
    await db.execute('''
      CREATE TABLE connections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER NOT NULL DEFAULT 22,
        username TEXT NOT NULL,
        authType TEXT NOT NULL DEFAULT 'password',
        password TEXT,
        privateKeyPath TEXT,
        passphrase TEXT,
        lastConnected TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        groupName TEXT,
        notes TEXT
      )
    ''');

    // 创建命令片段表
    await db.execute('''
      CREATE TABLE snippets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        command TEXT NOT NULL,
        description TEXT,
        groupName TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // 创建终端标签表
    await db.execute('''
      CREATE TABLE terminal_tabs (
        id TEXT PRIMARY KEY,
        connectionId TEXT NOT NULL,
        title TEXT,
        currentDirectory TEXT DEFAULT '~',
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (connectionId) REFERENCES connections(id) ON DELETE CASCADE
      )
    ''');

    // 创建设置表
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  // ============ 连接配置操作 ============

  /// 获取所有连接配置
  Future<List<ConnectionProfile>> getAllConnections() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('connections');
    
    return maps.map((map) => ConnectionProfile.fromJson(map)).toList();
  }

  /// 获取单个连接配置
  Future<ConnectionProfile?> getConnection(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'connections',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return ConnectionProfile.fromJson(maps.first);
  }

  /// 插入连接配置
  Future<void> insertConnection(ConnectionProfile connection) async {
    final db = await database;
    await db.insert(
      'connections',
      connection.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新连接配置
  Future<void> updateConnection(ConnectionProfile connection) async {
    final db = await database;
    await db.update(
      'connections',
      connection.toJson(),
      where: 'id = ?',
      whereArgs: [connection.id],
    );
  }

  /// 删除连接配置
  Future<void> deleteConnection(String id) async {
    final db = await database;
    await db.delete(
      'connections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ 命令片段操作 ============

  /// 获取所有命令片段
  Future<List<Snippet>> getAllSnippets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('snippets');
    
    return maps.map((map) => Snippet.fromJson(map)).toList();
  }

  /// 获取单个命令片段
  Future<Snippet?> getSnippet(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'snippets',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return Snippet.fromJson(maps.first);
  }

  /// 插入命令片段
  Future<void> insertSnippet(Snippet snippet) async {
    final db = await database;
    await db.insert(
      'snippets',
      snippet.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新命令片段
  Future<void> updateSnippet(Snippet snippet) async {
    final db = await database;
    await db.update(
      'snippets',
      snippet.toJson(),
      where: 'id = ?',
      whereArgs: [snippet.id],
    );
  }

  /// 删除命令片段
  Future<void> deleteSnippet(String id) async {
    final db = await database;
    await db.delete(
      'snippets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ 终端标签操作 ============

  /// 获取所有终端标签
  Future<List<TerminalTab>> getAllTabs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('terminal_tabs');
    
    return maps.map((map) => TerminalTab.fromJson(map)).toList();
  }

  /// 插入终端标签
  Future<void> insertTab(TerminalTab tab) async {
    final db = await database;
    await db.insert(
      'terminal_tabs',
      tab.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新终端标签
  Future<void> updateTab(TerminalTab tab) async {
    final db = await database;
    await db.update(
      'terminal_tabs',
      tab.toJson(),
      where: 'id = ?',
      whereArgs: [tab.id],
    );
  }

  /// 删除终端标签
  Future<void> deleteTab(String id) async {
    final db = await database;
    await db.delete(
      'terminal_tabs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ 设置操作 ============

  /// 获取设置值
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  /// 设置值
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 删除设置
  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // ============ 批量操作 ============

  /// 批量导入连接（WebDAV 同步用）
  Future<void> importConnections(List<ConnectionProfile> connections) async {
    final db = await database;
    final batch = db.batch();
    
    for (final connection in connections) {
      batch.insert(
        'connections',
        connection.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// 批量导入片段（WebDAV 同步用）
  Future<void> importSnippets(List<Snippet> snippets) async {
    final db = await database;
    final batch = db.batch();
    
    for (final snippet in snippets) {
      batch.insert(
        'snippets',
        snippet.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// 清空所有数据（用于恢复）
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('connections');
    await db.delete('snippets');
    await db.delete('terminal_tabs');
    await db.delete('settings');
  }

  /// 关闭数据库连接
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
