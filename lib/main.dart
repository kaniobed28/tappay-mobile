import 'package:flutter/material.dart';
import 'package:tappay/app/app.dart';
import 'package:tappay/features/auth/data/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  await auth.init();

  runApp(TapPayApp(auth: auth));
}
