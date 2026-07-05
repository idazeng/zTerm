import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'master_password_screen.dart';

/// Host management page with CRUD operations
class HostManageScreen extends ConsumerStatefulWidget {
  const HostManageScreen({super.key});
  @override
  ConsumerState<HostManageScreen> createState() => _HostManageScreenState();
}

class _HostManageScreenState extends ConsumerState<HostManageScreen> {
  String _searchQuery = '';
  String? _filterGroup;

  @override
  Widget build(BuildContext context) {
    final connections = ref.watch(connectionsProvider);
    final filtered = _filterConnections(connections);

    return Scaffold(
      appBar: AppBar(
        title: const Text('主机管理'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索主机...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
        actions: [
          if (_filterGroup != null)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              tooltip: '清除筛选',
              onPressed: () => setState(() => _filterGroup = null),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: '按分组筛选',
            onSelected: (v) => setState(() => _filterGroup = v == 'all' ? null : v),
            itemBuilder: (context) {
              final groups = connections
                  .map((c) => c.groupName)
                  .where((g) => g != null && g.isNotEmpty)
                  .cast<String>()
                  .toSet()
                  .toList()
                ..sort();
              if (groups.isEmpty) {
                return [const PopupMenuItem(value: 'all', child: Text('无分组'))];
              }
              return [
                const PopupMenuItem(value: 'all', child: Text('全部分组')),
                for (final g in groups)
                  PopupMenuItem(value: g, child: Text(g)),
              ];
            },
          ),
        ],
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.computer, size: 64, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty || _filterGroup != null
                        ? '无匹配主机'
                        : '暂无主机',
                    style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final conn = filtered[index];
                return _buildHostTile(conn);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<ConnectionProfile> _filterConnections(List<ConnectionProfile> list) {
    var result = list;
    if (_filterGroup != null) {
      result = result.where((c) => c.groupName == _filterGroup).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.host.toLowerCase().contains(q) ||
          c.username.toLowerCase().contains(q) ||
          (c.groupName?.toLowerCase().contains(q) ?? false) ||
          (c.notes?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  Widget _buildHostTile(ConnectionProfile conn) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(Icons.computer, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Text(conn.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${conn.username}@${conn.host}:${conn.port}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (conn.groupName != null && conn.groupName!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(conn.groupName!, style: AppStyles.caption),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') _showEditDialog(conn);
              else if (value == 'delete') _confirmDelete(conn);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('编辑'))),
              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('删除', style: TextStyle(color: Colors.red)))),
            ],
          ),
        ],
      ),
      onTap: () => _connectHost(conn),
      onLongPress: null,
    );
  }

  void _showHostOptions(ConnectionProfile conn) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('连接'),
            onTap: () {
              Navigator.pop(context);
              _connectHost(conn);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('编辑'),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog(conn);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(conn);
            },
          ),
        ]),
      ),
    );
  }

  void _showCreateDialog() {
    final masterPasswordSet = ref.read(masterPasswordSetProvider);
    if (!masterPasswordSet) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('请先设置主密码'),
          content: const Text('Set a master password to protect sensitive data'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (context) => MasterPasswordDialog(isSetup: true));
              },
              child: const Text('设置'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(context: context, builder: (context) => const ConnectionEditDialog());
  }

  void _showEditDialog(ConnectionProfile conn) {
    showDialog(context: context, builder: (context) => ConnectionEditDialog(connection: conn));
  }

  void _confirmDelete(ConnectionProfile conn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除主机'),
        content: Text('Delete "${conn.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(connectionsProvider.notifier).deleteConnection(conn.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${conn.name} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _connectHost(ConnectionProfile conn) {
    // Navigate back and create a new tab
    Navigator.pop(context);
    // Use the same logic as home screen
    final tab = TerminalTab(connectionId: conn.id, title: conn.name);
    ref.read(terminalTabsProvider.notifier).addTab(tab);
    ref.read(activeTabIdProvider.notifier).state = tab.id;
  }
}
