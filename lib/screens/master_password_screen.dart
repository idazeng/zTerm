import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/constants.dart';
import '../providers/providers.dart';

/// 主密码设置/验证对话框
class MasterPasswordDialog extends ConsumerStatefulWidget {
  /// 是否为首次设置（true=设置，false=验证）
  final bool isSetup;
  
  const MasterPasswordDialog({
    super.key,
    this.isSetup = true,
  });

  @override
  ConsumerState<MasterPasswordDialog> createState() => _MasterPasswordDialogState();
}

class _MasterPasswordDialogState extends ConsumerState<MasterPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isSetup ? '设置主密码' : '输入主密码'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isSetup)
              Padding(
                padding: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
                child: Text(
                  '主密码用于加密保护您的敏感信息（密码、密钥等）\n请牢记此密码，丢失后无法恢复',
                  style: AppStyles.bodySmall.copyWith(color: Colors.orange),
                ),
              ),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '主密码',
                prefixIcon: const Icon(Icons.lock),
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
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                if (widget.isSetup && value.length < 6) {
                  return '密码至少6位';
                }
                return null;
              },
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            if (widget.isSetup)
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: '确认密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return '两次密码不一致';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
      actions: [
        if (!widget.isSetup)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isSetup ? '设置' : '验证'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final password = _passwordController.text;
      
      if (widget.isSetup) {
        // 设置主密码
        await secureStorage.setMasterPassword(password);
        ref.read(masterPasswordSetProvider.notifier).state = true;
        // 同步到 AppSettings
        ref.read(appSettingsProvider.notifier).setMasterPasswordFlag(true);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('主密码设置成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 验证主密码
        final isValid = await secureStorage.verifyMasterPassword(password);
        
        if (mounted) {
          if (isValid) {
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('密码错误'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
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
