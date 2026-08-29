import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tappay/app/dependencies.dart';
import 'package:tappay/core/network/api_client.dart';
import 'package:tappay/core/theme/app_theme.dart';
import 'package:tappay/features/auth/data/auth_service.dart';
import 'package:tappay/features/auth/presentation/login_screen.dart';
import 'package:tappay/features/home/presentation/home_screen.dart';

class TapPayApp extends StatelessWidget {
  final AuthService auth;
  const TapPayApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders(auth),
      child: MaterialApp(
        title: 'TapPay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  @override
  void initState() {
    super.initState();
    // Wake the backend as soon as the app opens so the first real request
    // (login, history, session create) doesn't hit the cold-start delay.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ApiClient>().warmUp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return auth.isSignedIn ? const HomeScreen() : const LoginScreen();
  }
}
