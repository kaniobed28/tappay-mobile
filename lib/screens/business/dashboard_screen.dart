import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';

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
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text('Business', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<AnalyticsModel?>(
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
                  final a = snap.data;
                  if (a == null) {
                    return ListView(children: const [
                      SizedBox(height: 100),
                      Icon(Icons.storefront_outlined, size: 48, color: Colors.black26),
                      SizedBox(height: 12),
                      Center(child: Text('No business yet', style: TextStyle(color: Colors.black54))),
                      SizedBox(height: 4),
                      Center(child: Text('Tap Receive to set up and take your first payment.',
                          style: TextStyle(color: Colors.black38, fontSize: 13))),
                    ]);
                  }
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _HeroCard(label: 'This month', value: formatAmount(a.month, a.currency)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _StatCard(label: 'Today', value: formatAmount(a.today, a.currency), icon: Icons.today, color: AppTheme.brand)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'This week', value: formatAmount(a.week, a.currency), icon: Icons.date_range, color: AppTheme.accent)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _StatCard(label: 'Payments', value: '${a.count}', icon: Icons.receipt_long, color: Colors.deepPurple)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(label: 'Avg payment', value: formatAmount(a.avgPayment, a.currency), icon: Icons.trending_up, color: Colors.teal)),
                      ]),
                      const SizedBox(height: 12),
                      _StatCard(label: 'Total volume (all time)', value: formatAmount(a.totalVolume, a.currency), icon: Icons.account_balance_wallet, color: Colors.indigo, wide: true),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String label;
  final String value;
  const _HeroCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brand, Color(0xFF7A4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }
}
