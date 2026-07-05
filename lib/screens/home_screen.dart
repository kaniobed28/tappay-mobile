import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';
import '../theme.dart';
import 'receive/receive_screen.dart';
import 'pay/scan_screen.dart';
import 'history/history_screen.dart';
import 'business/dashboard_screen.dart';

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
    // Open the realtime channel once signed in, so merchant confirmation is instant,
    // and register this device for FCM push (no-op in dev/no-Firebase mode).
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
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Business'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Activity'),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome', style: TextStyle(color: Colors.black54)),
                    Text(auth.email ?? 'TapPay user',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.read<AuthService>().signOut(),
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _BrandCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.contactless,
                  label: 'Pay',
                  subtitle: 'Tap or scan',
                  color: AppTheme.brand,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionTile(
                  icon: Icons.qr_code_2,
                  label: 'Receive',
                  subtitle: 'Get paid',
                  color: AppTheme.accent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiveScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: const [
          Text('Contactless payments',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 8),
          Text('Pay as simply as a handshake',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(children: [
            Icon(Icons.contactless, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('NFC', style: TextStyle(color: Colors.white)),
            SizedBox(width: 20),
            Icon(Icons.qr_code_2, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('QR fallback', style: TextStyle(color: Colors.white)),
          ]),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EAF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 24, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
            const SizedBox(height: 14),
            Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
