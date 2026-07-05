import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiClient>().notifications();
  }

  Future<void> _refresh() async {
    final f = context.read<ApiClient>().notifications();
    setState(() => _future = f);
    await f;
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.read) return;
    try {
      await context.read<ApiClient>().markNotificationRead(n.id);
      await _refresh();
    } catch (_) {/* non-fatal */}
  }

  IconData _iconFor(String type) => switch (type) {
        'payment_received' => Icons.south_west,
        'payment_success' => Icons.check_circle_outline,
        'payment_failed' => Icons.error_outline,
        _ => Icons.notifications_none,
      };

  Color _colorFor(String type) => switch (type) {
        'payment_received' => AppTheme.accent,
        'payment_success' => AppTheme.brand,
        'payment_failed' => Colors.red,
        _ => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<NotificationModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                const SizedBox(height: 120),
                Center(child: Text(apiErrorMessage(snap.error!))),
              ]);
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                Icon(Icons.notifications_none, size: 48, color: Colors.black26),
                SizedBox(height: 12),
                Center(child: Text('Nothing yet', style: TextStyle(color: Colors.black54))),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = items[i];
                final color = _colorFor(n.type);
                return Card(
                  child: ListTile(
                    onTap: () => _markRead(n),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(_iconFor(n.type), color: color),
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${n.body}\n${DateFormat.yMMMd().add_jm().format(n.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: n.read
                        ? null
                        : Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: AppTheme.brand, shape: BoxShape.circle),
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
