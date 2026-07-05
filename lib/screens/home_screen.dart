import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'receive/receive_screen.dart';
import 'pay/scan_screen.dart';
import 'history/history_screen.dart';
import 'business/dashboard_screen.dart';
import 'notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Open realtime channel once signed in, and register for FCM (no-op in demo mode).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthService>();
      final token = await auth.getIdToken();
      if (token != null && mounted) context.read<RealtimeService>().connect(token);
      if (mounted) {
        await PushService().register(context.read<ApiClient>(), firebaseReady: auth.firebaseReady);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [const _Dashboard(), const DashboardScreen(), const HistoryScreen()];
    return Scaffold(
      body: SafeArea(bottom: false, child: pages[_index]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.card),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Business'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Activity'),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final name = (auth.email ?? 'there').split('@').first;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back', style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.4)),
                  ],
                ),
              ),
              _CircleIcon(
                icon: Icons.notifications_none_rounded,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              const SizedBox(width: 10),
              _CircleIcon(icon: Icons.logout_rounded, onTap: () => context.read<AuthService>().signOut()),
            ],
          ),
          const SizedBox(height: 22),
          const _HeroCard(),
          const SizedBox(height: 24),
          const SectionTitle('Quick actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Pay',
                  subtitle: 'Tap or scan',
                  gradient: AppGradients.brand,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionTile(
                  icon: Icons.contactless_rounded,
                  label: 'Receive',
                  subtitle: 'Get paid',
                  gradient: AppGradients.mint,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiveScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _HowItWorks(),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Contactless payments', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Pay as simply\nas a handshake',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5)),
          const SizedBox(height: 20),
          Row(
            children: [
              _Chip(icon: Icons.contactless_rounded, label: 'NFC'),
              SizedBox(width: 10),
              _Chip(icon: Icons.qr_code_2_rounded, label: 'QR fallback'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.subtitle, required this.gradient, required this.onTap});

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: AppMotion.fast,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(gradient: widget.gradient, borderRadius: BorderRadius.circular(14)),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 16),
              Text(widget.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(widget.subtitle, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('How it works', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15)),
          SizedBox(height: 16),
          _Step(n: '1', title: 'Enter an amount', body: 'The receiver opens Receive and sets the amount.'),
          _Step(n: '2', title: 'Tap or scan', body: 'Bring the phones together, or scan the QR code.'),
          _Step(n: '3', title: 'Confirm & done', body: 'Pay securely — both phones confirm instantly.', last: true),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n, title, body;
  final bool last;
  const _Step({required this.n, required this.title, required this.body, this.last = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(child: Text(n, style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 13))),
              ),
              if (!last) Expanded(child: Container(width: 2, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 4))),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, height: 1.35)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
