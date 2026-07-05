import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';

/// 命令片段管理页面
class SnippetsScreen extends ConsumerStatefulWidget {
  const SnippetsScreen({super.key});

  @override
  ConsumerState<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends ConsumerState<SnippetsScreen> {
  @override
  Widget build(BuildContext context) {
    final snippets = ref.watch(snippetsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('命令片段库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加片段',
            onPressed: () => _showEditDialog(),
          ),
        ],
      ),
      body: snippets.isEmpty
          ? _buildEmptyState()
          : _buildSnippetList(snippets),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code,
            size: 80,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: AppStyles.spacingLarge),
          Text(
            '暂无命令片段',
            style: AppStyles.titleLarge.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppStyles.spacingSmall),
          Text(
            '点击右上角 + 按钮添加常用命令',
            style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppStyles.spacingExtraLarge),
          ElevatedButton.icon(
            onPressed: () => _showEditDialog(),
            icon: const Icon(Icons.add),
            label: const Text('添加片段'),
          ),
        ],
      ),
    );
  }

  /// 构建片段列表
  Widget _buildSnippetList(List<Snippet> snippets) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppStyles.spacingSmall),
      itemCount: snippets.length,
      itemBuilder: (context, index) {
        final snippet = snippets[index];
        return _buildSnippetCard(snippet);
      },
    );
  }

  /// 构建片段卡片
  Widget _buildSnippetCard(Snippet snippet) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingSmall),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
          ),
          child: Icon(
            Icons.terminal,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          snippet.name,
          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          snippet.command,
          style: AppStyles.bodySmall.copyWith(color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value, snippet),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'insert',
              child: ListTile(
                leading: Icon(Icons.input),
                title: Text('插入到终端'),
              ),
            ),
            const PopupMenuItem(
              value: 'copy',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('复制命令'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('编辑'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
        onTap: () => _insertToTerminal(snippet),
      ),
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(String action, Snippet snippet) {
    switch (action) {
      case 'insert':
        _insertToTerminal(snippet);
        break;
      case 'copy':
        _copyCommand(snippet);
        break;
      case 'edit':
        _showEditDialog(snippet: snippet);
        break;
      case 'delete':
        _showDeleteConfirmation(snippet);
        break;
    }
  }

  /// 插入命令到终端
  void _insertToTerminal(Snippet snippet) {
    // 将命令写入 pendingCommand，由活动终端监听并发送到 SSH 会话
    ref.read(pendingCommandProvider.notifier).state = '${snippet.command}\n';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('命令 "${snippet.name}" 已发送到终端'),
        duration: const Duration(seconds: 1),
      ),
    );
    Navigator.pop(context); // 返回到终端界面
  }

  /// 复制命令到剪贴板
  void _copyCommand(Snippet snippet) async {
    await Clipboard.setData(ClipboardData(text: snippet.command));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已复制: ${snippet.command}')),
      );
    }
  }

  /// 显示编辑对话框
  void _showEditDialog({Snippet? snippet}) {
    final nameController = TextEditingController(text: snippet?.name ?? '');
    final commandController = TextEditingController(text: snippet?.command ?? '');
    final descriptionController = TextEditingController(text: snippet?.description ?? '');
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(snippet == null ? '添加命令片段' : '编辑命令片段'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '例如：查看系统信息',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              TextFormField(
                controller: commandController,
                decoration: const InputDecoration(
                  labelText: '命令',
                  hintText: '例如：uname -a',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入命令';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final name = nameController.text.trim();
                final command = commandController.text.trim();
                final description = descriptionController.text.trim();
                
                if (snippet == null) {
                  // 添加新片段
                  ref.read(snippetsProvider.notifier).addSnippet(
                        Snippet(
                          name: name,
                          command: command,
                          description: description.isNotEmpty ? description : null,
                        ),
                      );
                } else {
                  // 更新片段
                  ref.read(snippetsProvider.notifier).updateSnippet(
                        snippet.copyWith(
                          name: name,
                          command: command,
                          description: description.isNotEmpty ? description : null,
                        ),
                      );
                }
                
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmation(Snippet snippet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除片段 "${snippet.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(snippetsProvider.notifier).deleteSnippet(snippet.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
