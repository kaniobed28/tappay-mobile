import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Merchant sales dashboard — today/week/month volume, count and average payment.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<AnalyticsModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiClient>().analytics();
  }

  Future<void> _refresh() async {
    final f = context.read<ApiClient>().analytics();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text('Business', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5)),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.brand,
            onRefresh: _refresh,
            child: FutureBuilder<AnalyticsModel?>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _scroll(EmptyState(icon: Icons.wifi_off_rounded, title: 'Couldn’t load', subtitle: apiErrorMessage(snap.error!)));
                }
                final a = snap.data;
                if (a == null) {
                  return _scroll(const EmptyState(
                    icon: Icons.storefront_rounded,
                    title: 'No business yet',
                    subtitle: 'Tap Receive to set up and take your first payment.',
                  ));
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _HeroStat(label: 'This month', value: formatAmount(a.month, a.currency), count: a.count),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _Stat(label: 'Today', value: formatAmount(a.today, a.currency), icon: Icons.today_rounded, tint: AppColors.brand)),
                      const SizedBox(width: 12),
                      Expanded(child: _Stat(label: 'This week', value: formatAmount(a.week, a.currency), icon: Icons.date_range_rounded, tint: AppColors.accent)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _Stat(label: 'Payments', value: '${a.count}', icon: Icons.receipt_long_rounded, tint: const Color(0xFF7A34E8))),
                      const SizedBox(width: 12),
                      Expanded(child: _Stat(label: 'Avg payment', value: formatAmount(a.avgPayment, a.currency), icon: Icons.trending_up_rounded, tint: AppColors.success)),
                    ]),
                    const SizedBox(height: 12),
                    _Stat(label: 'Total volume (all time)', value: formatAmount(a.totalVolume, a.currency), icon: Icons.account_balance_wallet_rounded, tint: AppColors.brand, wide: true),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _scroll(Widget child) => ListView(children: [const SizedBox(height: 80), child]);
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  final int count;
  const _HeroStat({required this.label, required this.value, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: AppGradients.brand, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.brandGlow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
              child: Text('$count paid', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color tint;
  final bool wide;
  const _Stat({required this.label, required this.value, required this.icon, required this.tint, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
