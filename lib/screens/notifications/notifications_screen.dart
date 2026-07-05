import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

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
    } catch (_) {}
  }

  ({IconData icon, Color color}) _style(String type) => switch (type) {
        'payment_received' => (icon: Icons.south_west_rounded, color: AppColors.success),
        'payment_success' => (icon: Icons.check_circle_rounded, color: AppColors.brand),
        'payment_failed' => (icon: Icons.error_rounded, color: AppColors.danger),
        'payment_refunded' || 'refund_issued' => (icon: Icons.undo_rounded, color: AppColors.inkSoft),
        _ => (icon: Icons.notifications_rounded, color: AppColors.brand),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _refresh,
        child: FutureBuilder<List<NotificationModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _scroll(EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load', subtitle: apiErrorMessage(snap.error!)));
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return _scroll(const EmptyState(icon: Icons.notifications_none_rounded, title: 'All caught up', subtitle: 'Payment updates will appear here.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = items[i];
                final s = _style(n.type);
                return AppCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => _markRead(n),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: s.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(s.icon, color: s.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(n.title,
                                      style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800, color: AppColors.ink)),
                                ),
                                if (!n.read)
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(n.body, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.35)),
                            const SizedBox(height: 5),
                            Text(DateFormat.MMMd().add_jm().format(n.createdAt), style: const TextStyle(color: AppColors.inkFaint, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _scroll(Widget child) => ListView(children: [const SizedBox(height: 100), child]);
}
