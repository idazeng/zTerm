import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';

/// 连接编辑对话框
class ConnectionEditDialog extends ConsumerStatefulWidget {
  /// 要编辑的连接（为空则新建）
  final ConnectionProfile? connection;

  const ConnectionEditDialog({
    super.key,
    this.connection,
  });

  @override
  ConsumerState<ConnectionEditDialog> createState() => _ConnectionEditDialogState();
}

class _ConnectionEditDialogState extends ConsumerState<ConnectionEditDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _passphraseController;
  late TextEditingController _groupNameController;
  late TextEditingController _notesController;
  
  late AuthType _authType;
  String? _privateKeyPath;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePassphrase = true;

  @override
  void initState() {
    super.initState();
    
    final conn = widget.connection;
    _nameController = TextEditingController(text: conn?.name ?? '');
    _hostController = TextEditingController(text: conn?.host ?? '');
    _portController = TextEditingController(text: conn?.port.toString() ?? '22');
    _usernameController = TextEditingController(text: conn?.username ?? '');
    _passwordController = TextEditingController();
    _passphraseController = TextEditingController();
    _groupNameController = TextEditingController(text: conn?.groupName ?? '');
    _notesController = TextEditingController(text: conn?.notes ?? '');
    
    _authType = conn?.authType ?? AuthType.password;
    _privateKeyPath = conn?.privateKeyPath;
    // 编辑已有连接时，从安全存储加载密码
    if (conn != null) {
      _loadPassword(conn.id);
    }
  }

  Future<void> _loadPassword(String connId) async {
    try {
      final secureStorage = SecureStorageService();
      final pwd = await secureStorage.getPassword(connId);
      if (pwd != null && pwd.isNotEmpty) {
        _passwordController.text = pwd;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passphraseController.dispose();
    _groupNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.connection != null;
    
    return AlertDialog(
      title: Text(isEditing ? '编辑连接' : '新建连接'),
      content: SizedBox(
        width: 400,
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 连接名称
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '连接名称',
                  hintText: '例如：生产服务器',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入连接名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              
              // 主机地址
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: '主机地址',
                  hintText: 'IP 地址或域名',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入主机地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              
              // 端口号
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: '端口号',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入端口号';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return '端口号无效';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              
              // 用户名
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              
              // 认证方式
              Row(
                children: [
                  const Text('认证方式：'),
                  const SizedBox(width: AppStyles.spacingSmall),
                  ChoiceChip(
                    label: const Text('密码'),
                    selected: _authType == AuthType.password,
                    onSelected: (selected) {
                      setState(() {
                        _authType = AuthType.password;
                      });
                    },
                  ),
                  const SizedBox(width: AppStyles.spacingSmall),
                  ChoiceChip(
                    label: const Text('密钥'),
                    selected: _authType == AuthType.key,
                    onSelected: (selected) {
                      setState(() {
                        _authType = AuthType.key;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              
              // 根据认证方式显示不同内容
              if (_authType == AuthType.password)
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '密码',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (_authType == AuthType.password &&
                        (value == null || value.isEmpty) &&
                        widget.connection == null) {
                      return '请输入密码';
                    }
                    return null;
                  },
                ),
              
              if (_authType == AuthType.key) ...[
                // 私钥文件选择
                InkWell(
                  onTap: _pickPrivateKey,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '私钥文件',
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _privateKeyPath ?? '选择私钥文件',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _privateKeyPath != null
                                  ? null
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        const Icon(Icons.folder_open),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.spacingMedium),
                
                // 密钥口令
                TextFormField(
                  controller: _passphraseController,
                  obscureText: _obscurePassphrase,
                  decoration: InputDecoration(
                    labelText: '密钥口令（可选）',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassphrase ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassphrase = !_obscurePassphrase;
                        });
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppStyles.spacingMedium),
              
              // 分组
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: '分组（可选）',
                  hintText: '例如：生产环境、测试环境',
                ),
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              
              // 备注
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  hintText: '关于此连接的备注信息',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      )),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  /// 选择私钥文件
  Future<void> _pickPrivateKey() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _privateKeyPath = result.files.first.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  /// 处理保存
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // 验证密钥文件
    if (_authType == AuthType.key && _privateKeyPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择私钥文件')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final connectionsNotifier = ref.read(connectionsProvider.notifier);
      
      final port = int.parse(_portController.text.trim());
      final name = _nameController.text.trim();
      final host = _hostController.text.trim();
      final username = _usernameController.text.trim();
      
      ConnectionProfile? connection = widget.connection;
      
      if (connection == null) {
        // 新建连接
        connection = ConnectionProfile(
          name: name,
          host: host,
          port: port,
          username: username,
          authType: _authType,
          groupName: _groupNameController.text.trim().isEmpty ? null : _groupNameController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        
        await connectionsNotifier.addConnection(connection);
      } else {
        // 更新连接
        connection = connection.copyWith(
          name: name,
          host: host,
          port: port,
          username: username,
          authType: _authType,
          groupName: _groupNameController.text.trim().isEmpty ? null : _groupNameController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
        
        await connectionsNotifier.updateConnection(connection);
      }
      
      // 存储密码或密钥
      if (_authType == AuthType.password) {
        final password = _passwordController.text;
        if (password.isNotEmpty) {
          await secureStorage.storePassword(connection.id, password);
        }
      } else {
        // 存储私钥内容
        if (_privateKeyPath != null) {
          final keyFile = File(_privateKeyPath!);
          final keyBytes = await keyFile.readAsBytes();
          await secureStorage.storePrivateKey(connection.id, keyBytes);
        }
        
        // 存储密钥口令
        final passphrase = _passphraseController.text;
        if (passphrase.isNotEmpty) {
          await secureStorage.storePassphrase(connection.id, passphrase);
        }
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.connection == null ? '连接已创建' : '连接已更新'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
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
