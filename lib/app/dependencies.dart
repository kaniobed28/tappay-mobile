import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:tappay/core/network/api_client.dart';
import 'package:tappay/core/realtime/realtime_service.dart';
import 'package:tappay/features/auth/data/auth_service.dart';
import 'package:tappay/features/merchants/data/merchants_api.dart';
import 'package:tappay/features/notifications/data/notifications_api.dart';
import 'package:tappay/features/payments/data/payments_api.dart';
import 'package:tappay/features/requests/data/requests_api.dart';
import 'package:tappay/features/sessions/data/nfc_service.dart';
import 'package:tappay/features/sessions/data/sessions_api.dart';
import 'package:tappay/features/users/data/users_api.dart';

/// Single place where the app's dependencies are assembled.
///
/// Each feature exposes exactly one API object, all sharing the one authenticated
/// [ApiClient] transport — so a screen depends on its own feature's API and nothing else.
List<SingleChildWidget> appProviders(AuthService auth) => [
      ChangeNotifierProvider<AuthService>.value(value: auth),
      Provider<NfcService>(create: (_) => NfcService()),
      Provider<RealtimeService>(
        create: (_) => RealtimeService(),
        dispose: (_, s) => s.dispose(),
      ),
      ProxyProvider<AuthService, ApiClient>(
        update: (_, a, _) => ApiClient(a),
      ),
      // Feature APIs — thin, typed views over the shared transport.
      ProxyProvider<ApiClient, UsersApi>(update: (_, c, _) => UsersApi(c)),
      ProxyProvider<ApiClient, MerchantsApi>(update: (_, c, _) => MerchantsApi(c)),
      ProxyProvider<ApiClient, SessionsApi>(update: (_, c, _) => SessionsApi(c)),
      ProxyProvider<ApiClient, PaymentsApi>(update: (_, c, _) => PaymentsApi(c)),
      ProxyProvider<ApiClient, RequestsApi>(update: (_, c, _) => RequestsApi(c)),
      ProxyProvider<ApiClient, NotificationsApi>(update: (_, c, _) => NotificationsApi(c)),
    ];
