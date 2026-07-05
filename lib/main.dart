import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'services/nfc_service.dart';
import 'services/realtime_service.dart';
import 'theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  await auth.init();

  runApp(TapPayApp(auth: auth));
}

class TapPayApp extends StatelessWidget {
  final AuthService auth;
  const TapPayApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        Provider<NfcService>(create: (_) => NfcService()),
        Provider<RealtimeService>(
          create: (_) => RealtimeService(),
          dispose: (_, s) => s.dispose(),
        ),
        ProxyProvider<AuthService, ApiClient>(
          update: (_, a, _) => ApiClient(a),
        ),
      ],
      child: MaterialApp(
        title: 'TapPay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return auth.isSignedIn ? const HomeScreen() : const LoginScreen();
  }
}
